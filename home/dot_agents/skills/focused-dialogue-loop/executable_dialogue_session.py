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
from typing import TYPE_CHECKING, cast


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

    @staticmethod
    def do(ops: list["Op"], state_file: Path, log_file: Path) -> int:
        code = 0
        for op in ops:
            result = Op._do(op, state_file, log_file)
            if result is not None:
                code = result
        return code

    @staticmethod
    def _do(op: "Op", state_file: Path, log_file: Path) -> int | None:
        if isinstance(op, UpdateOp):
            append_state(state_file, op.inner)
        elif isinstance(op, LogOp):
            append_log(log_file, op.inner)
        elif isinstance(op, PrintOp):
            print(op.inner)
        elif isinstance(op, ExitOp):
            return op.inner
        return None


class UpdateOp(Op):
    pass


class LogOp(Op):
    pass


class PrintOp(Op):
    pass


class ExitOp(Op):
    pass


class QuestionState(StrEnum):
    TODO = "todo"
    DONE = "done"
    CANCELED = "canceled"


type Theme = str


@dataclass(frozen=True, unsafe_hash=True)
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
        # Fixed structural comparison: self.todo stores Question instances
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
        etype = event.get("event")
        theme = str(event.get("theme"))
        if etype == EventType.ASK:
            self.ask(theme)
        elif etype == EventType.DEFER:
            # Map incoming upstream strings to instantiated Question instances
            upstreams_raw = event.get("upstreams", [])
            upstreams = [Question(theme=str(u)) for u in upstreams_raw]
            self.defer(theme, upstreams)
        elif etype == EventType.RESOLVE:
            self.resolve(theme)
        elif etype == EventType.CANCEL:
            self.cancel(theme)

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
    """Atomic POSIX append using standard text flushing."""
    line = json.dumps(event) + "\n"
    with open(filename, "a", encoding="utf-8") as f:
        f.write(line)
        f.flush()


def append_log(filename: Path, content: str):
    """Atomic POSIX append using standard text flushing."""
    with open(filename, "a", encoding="utf-8") as f:
        f.write(content)
        f.flush()


def read_updates(filename: Path) -> list[dict]:
    # Fixed: Prevent FileNotFoundError on fresh operations
    if not filename.exists():
        return []

    with open(filename, "r", encoding="utf-8") as f:
        fcntl.flock(f, fcntl.LOCK_SH)
        lines = f.readlines()
        fcntl.flock(f, fcntl.LOCK_UN)

    return [json.loads(line) for line in lines if line.strip()]


def cli_ask(args, state_file, timestamp):
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
    return [UpdateOp(event), LogOp(log_entry)]


def cli_defer(args, state_file, timestamp):
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
    return [UpdateOp(event)]


def cli_note(args, state_file, timestamp):
    log_entry = f"* **[NOTE: {args.key}]** {args.msg}\n"
    return [LogOp(log_entry)]


def cli_resolve(args, state_file, timestamp):
    event = {"event": EventType.RESOLVE, "theme": args.key, "timestamp": timestamp}
    return [UpdateOp(event)]


def cli_cancel(args, state_file, timestamp):
    event = {"event": EventType.CANCEL, "theme": args.key, "timestamp": timestamp}
    updates = read_updates(state_file)
    state = DialogueState.collect_delta(updates + [event])
    out = json.dumps({"todo": list(map(lambda q: q.theme, state.todo))}, indent=2)

    return [UpdateOp(event), PrintOp(out)]


def cli_summarize(args, state_file, timestamp):
    state = DialogueState.collect_delta(read_updates(state_file))
    open_themes = [q.theme for q in state.todo]
    out = json.dumps({"todo": open_themes}, indent=2)
    ops: list[Op] = [PrintOp(out)]
    if args.close and open_themes:
        ops.append(ExitOp(1))
    return ops


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

    timestamp = datetime.now().isoformat()

    cmds: dict[str, Callable[[dict, Path, datetime], list[Op]]] = {
        "ask": cli_ask,
        "defer": cli_defer,
        "note": cli_note,
        "resolve": cli_resolve,
        "cancel": cli_cancel,
        "summarize": cli_summarize,
    }
    ops = cmds[args.command](args, state_file, timestamp)
    sys.exit(Op.do(ops, state_file, log_file))


if __name__ == "__main__":
    main()
