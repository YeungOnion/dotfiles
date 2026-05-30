#!/usr/bin/env python3
import argparse
from copy import deepcopy
import fcntl
import json
import sys
from collections.abc import Callable, Collection, Generator, Iterator
from dataclasses import dataclass, field
from datetime import datetime
from enum import StrEnum
from itertools import chain
from pathlib import Path
from typing import TYPE_CHECKING, assert_never, cast


class EventType(StrEnum):
    ASK = "ask"
    DEFER = "defer"
    NOTE = "note"
    RESOLVE = "resolve"
    CANCEL = "cancel"
    INIT = "init"


class Op:
    def __init__(self, arg):
        self.inner = deepcopy(arg)

    def __eq__(self, other: object) -> bool:
        return type(self) is type(other) and self.inner == other.inner  # type: ignore[union-attr]

    def __repr__(self) -> str:
        return f"{type(self).__name__}({self.inner!r})"


class UpdateOp(Op):
    pass


class LogOp(Op):
    pass


class PrintOp(Op):
    pass


type AnyOp = UpdateOp | LogOp | PrintOp


def _execute_op(op: AnyOp, state_file: Path, log_file: Path) -> None:
    match op:
        case UpdateOp():
            append_state(state_file, op.inner)
        case LogOp():
            append_log(log_file, op.inner)
        case PrintOp():
            print(op.inner)
        case _ as unreachable:
            assert_never(unreachable)


def execute_ops(ops: list[AnyOp], state_file: Path, log_file: Path) -> None:
    for op in ops:
        _execute_op(op, state_file, log_file)


class QuestionState(StrEnum):
    TODO = "todo"
    DONE = "done"
    CANCELED = "canceled"


type Theme = str


@dataclass(frozen=True)
class Question:
    theme: Theme
    upstreams: tuple["Question", ...] = field(
        default_factory=tuple, hash=False, compare=False
    )

    def all_children(self) -> list["Question"]:
        return list(self.traverse(iter([self]), []))

    @staticmethod
    def traverse(
        rem: Iterator["Question"], total: Collection["Question"]
    ) -> Generator["Question"]:
        _sentinel = object()
        head = next(rem, _sentinel)

        if head is _sentinel:
            yield from total
            return
        if TYPE_CHECKING:
            head = cast("Question", head)

        yield from Question.traverse(chain(head.upstreams, rem), set(total) | {head})


class DialogueState:
    def __init__(self):
        self.todo: set[Question] = set()
        self.done: set[Theme] = set()
        self.canceled: set[Theme] = set()

    def _seen_in(self, theme: Theme) -> QuestionState | None:
        if any(q.theme == theme for q in self.todo):
            return QuestionState.TODO
        if theme in self.done:
            return QuestionState.DONE
        if theme in self.canceled:
            return QuestionState.CANCELED
        return None

    @staticmethod
    def collect_delta(events: Collection[dict]) -> "DialogueState":
        s = DialogueState()
        for e in events:
            s._mutate(e)
        return s

    def _mutate(self, event: dict):
        theme = str(event.get("theme"))
        match EventType(event.get("event")):
            case EventType.ASK:
                self.ask(theme)
            case EventType.DEFER:
                upstreams = [Question(theme=str(u)) for u in event.get("upstreams", [])]
                self.defer(theme, upstreams)
            case EventType.RESOLVE:
                self.resolve(theme)
            case EventType.CANCEL:
                self.cancel(theme)
            case EventType.NOTE | EventType.INIT:
                pass

    def ask(self, theme: Theme):
        if theme not in self.done and theme not in self.canceled:
            self.todo.add(Question(theme=theme))

    def defer(self, t: Theme, upstreams: Collection[Question]):
        upstreams = tuple(upstreams)
        self.todo.add(Question(theme=t, upstreams=upstreams))

        if not upstreams:
            return

        for q in Question.traverse(iter(upstreams), []):
            match self._seen_in(q.theme):
                case QuestionState.TODO:
                    self.todo.add(q)
                case QuestionState.DONE:
                    self.done.add(q.theme)
                case QuestionState.CANCELED:
                    self.canceled.add(q.theme)

    def resolve(self, t: Theme):
        if any(q.theme == t for q in self.todo):
            self.todo.remove(Question(theme=t))
        self.done.add(t)

    def cancel(self, t: Theme):
        if any(q.theme == t for q in self.todo):
            self.todo.remove(Question(theme=t))
        self.canceled.add(t)

    def to_dict(self):
        return {
            QuestionState.TODO: {
                q.theme: [u.theme for u in q.upstreams] for q in self.todo
            },
            QuestionState.DONE: list(self.done),
            QuestionState.CANCELED: list(self.canceled),
        }


def get_filenames(agent_uuid: str) -> tuple[Path, Path]:
    safe_uuid = "".join(
        c for c in agent_uuid.replace("_", "-") if c.isalnum() or c in "-"
    ).strip("-")
    return (
        Path(f".session_state_{safe_uuid}.jsonl"),
        Path(f".session_notes_{safe_uuid}.md"),
    )


def append_state(filename: Path, event: dict):
    line = json.dumps(event) + "\n"
    with open(filename, "a", encoding="utf-8") as f:
        f.write(line)
        f.flush()


def append_log(filename: Path, content: str):
    with open(filename, "a", encoding="utf-8") as f:
        f.write(content)
        f.flush()


def read_updates(filename: Path) -> list[dict]:
    if not filename.exists():
        return []

    with open(filename, "r", encoding="utf-8") as f:
        fcntl.flock(f, fcntl.LOCK_SH)
        lines = f.readlines()
        fcntl.flock(f, fcntl.LOCK_UN)

    return [json.loads(line) for line in lines if line.strip()]


type Handler = Callable[[argparse.Namespace, list[dict], str], tuple[list[AnyOp], int]]


def cli_ask(args: argparse.Namespace, events: list[dict], timestamp: str) -> tuple[list[AnyOp], int]:
    event = {
        "event": EventType.ASK,
        "theme": args.key,
        "motive": args.motive,
        "timestamp": timestamp,
    }
    log_entry = f"* **[ASK: {args.key}]**"
    if args.motive:
        log_entry += f" (Motive: {args.motive})"
    log_entry += "\n"
    return [UpdateOp(event), LogOp(log_entry)], 0


def cli_defer(args: argparse.Namespace, events: list[dict], timestamp: str) -> tuple[list[AnyOp], int]:
    try:
        upstreams = json.loads(args.upstreams)
    except json.JSONDecodeError:
        upstreams = []
    event = {
        "event": EventType.DEFER,
        "theme": args.key,
        "upstreams": upstreams,
        "motive": args.motive,
        "timestamp": timestamp,
    }
    return [UpdateOp(event)], 0


def cli_note(args: argparse.Namespace, events: list[dict], timestamp: str) -> tuple[list[AnyOp], int]:
    log_entry = f"* **[NOTE: {args.key}]** {args.msg}\n"
    return [LogOp(log_entry)], 0


def cli_resolve(args: argparse.Namespace, events: list[dict], timestamp: str) -> tuple[list[AnyOp], int]:
    event = {"event": EventType.RESOLVE, "theme": args.key, "timestamp": timestamp}
    return [UpdateOp(event)], 0


def cli_cancel(args: argparse.Namespace, events: list[dict], timestamp: str) -> tuple[list[AnyOp], int]:
    event = {"event": EventType.CANCEL, "theme": args.key, "timestamp": timestamp}
    state = DialogueState.collect_delta(events + [event])
    out = json.dumps({"todo": [q.theme for q in state.todo]}, indent=2)
    return [UpdateOp(event), PrintOp(out)], 0


def cli_summarize(args: argparse.Namespace, events: list[dict], timestamp: str) -> tuple[list[AnyOp], int]:
    state = DialogueState.collect_delta(events)
    open_themes = [q.theme for q in state.todo]
    out = json.dumps({"todo": open_themes}, indent=2)
    code = 1 if args.close and open_themes else 0
    return [PrintOp(out)], code


def main():
    parser = argparse.ArgumentParser(description="Focused Dialogue Session Manager")
    parser.add_argument("--uuid", required=True, help="Agent UUID")

    subparsers = parser.add_subparsers(dest="command", required=True)

    ask_p = subparsers.add_parser("ask")
    ask_p.add_argument("key")
    ask_p.add_argument("--motive")

    defer_p = subparsers.add_parser("defer")
    defer_p.add_argument("key")
    defer_p.add_argument("upstreams", nargs="?", default="[]")
    defer_p.add_argument("--motive")

    note_p = subparsers.add_parser("note")
    note_p.add_argument("key")
    note_p.add_argument("msg")

    resolve_p = subparsers.add_parser("resolve")
    resolve_p.add_argument("key")

    cancel_p = subparsers.add_parser("cancel")
    cancel_p.add_argument("key")

    summarize_p = subparsers.add_parser("summarize")
    summarize_p.add_argument("--close", action="store_true", help="Exit non-zero if open topics remain")

    args = parser.parse_args()
    state_file, log_file = get_filenames(args.uuid)
    events = read_updates(state_file)
    timestamp = datetime.now().isoformat()

    cmds: dict[str, Handler] = {
        "ask": cli_ask,
        "defer": cli_defer,
        "note": cli_note,
        "resolve": cli_resolve,
        "cancel": cli_cancel,
        "summarize": cli_summarize,
    }
    ops, code = cmds[args.command](args, events, timestamp)
    execute_ops(ops, state_file, log_file)
    sys.exit(code)


if __name__ == "__main__":
    main()
