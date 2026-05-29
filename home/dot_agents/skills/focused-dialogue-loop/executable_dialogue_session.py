#!/usr/bin/env python3
import sys
import json
import fcntl
import argparse
from dataclasses import dataclass, field, asdict
from enum import StrEnum
from datetime import datetime
from typing import List, Set, Dict, Optional, Tuple


class EventType(StrEnum):
    ASK = "ask"
    DEFER = "defer"
    NOTE = "note"
    RESOLVE = "resolve"
    CANCEL = "cancel"
    INIT = "init"


@dataclass(frozen=True)
class Question:
    theme: str
    upstreams: Tuple[str, ...] = field(default_factory=tuple)


class DialogueState:
    def __init__(self):
        self.todo: Dict[str, Question] = {}
        self.done: Set[str] = set()
        self.canceled: Set[str] = set()

    def ask(self, theme: str):
        if theme not in self.done and theme not in self.canceled:
            self.todo[theme] = Question(theme=theme)

    def defer(self, theme: str, upstreams: List[str]):
        # BFS-like insertion: target theme and all upstreams go to TODO
        # if they aren't already resolved or canceled.
        all_themes = [theme] + upstreams
        for t in all_themes:
            if t not in self.done and t not in self.canceled:
                # For defer, we record the upstreams for the main theme
                if t == theme:
                    self.todo[t] = Question(theme=t, upstreams=tuple(upstreams))
                elif t not in self.todo:
                    self.todo[t] = Question(theme=t)

    def resolve(self, theme: str):
        if theme in self.todo:
            self.todo.pop(theme)
        self.done.add(theme)

    def cancel(self, theme: str):
        if theme in self.todo:
            self.todo.pop(theme)
        self.canceled.add(theme)

    def to_dict(self):
        return {
            "todo": {k: list(v.upstreams) for k, v in self.todo.items()},
            "done": list(self.done),
            "canceled": list(self.canceled),
        }


def get_filenames(agent_uuid: str) -> Tuple[str, str]:
    safe_uuid = "-".join(
        c for c in agent_uuid.replace("_", "-") if c.isalnum() or c in "-"
    )
    return f".session_state_{safe_uuid}.jsonl", f".session_notes_{safe_uuid}.md"


def append_state(filename: str, event: dict):
    """Atomic POSIX append for JSONL."""
    line = json.dumps(event) + "\n"
    with open(filename, "a", buffering=0) as f:
        f.write(line)


def append_log(filename: str, content: str):
    """Atomic POSIX append for Markdown."""
    with open(filename, "a", buffering=0) as f:
        f.write(content)


def reconcile_state(filename: str) -> DialogueState:
    state = DialogueState()
    try:
        with open(filename, "r") as f:
            # Locking for read to ensure we see a consistent state
            fcntl.flock(f, fcntl.LOCK_SH)
            for line in f:
                if not line.strip():
                    continue
                event = json.loads(line)
                etype = event.get("event")
                theme = event.get("theme")
                if etype == EventType.ASK:
                    state.ask(theme)
                elif etype == EventType.DEFER:
                    state.defer(theme, event.get("upstreams", []))
                elif etype == EventType.RESOLVE:
                    state.resolve(theme)
                elif etype == EventType.CANCEL:
                    state.cancel(theme)
            fcntl.flock(f, fcntl.LOCK_UN)
    except FileNotFoundError:
        pass
    return state


def main():
    parser = argparse.ArgumentParser(description="Focused Dialogue Session Manager")
    parser.add_argument("--uuid", required=True, help="Agent UUID")
    
    subparsers = parser.add_subparsers(dest="command", required=True)

    # ask <key> [--motive=<motive>]
    ask_p = subparsers.add_parser("ask")
    ask_p.add_argument("key")
    ask_p.add_argument("--motive")

    # defer <key> [upstreams_json] [--motive=<motive>]
    defer_p = subparsers.add_parser("defer")
    defer_p.add_argument("key")
    defer_p.add_argument("upstreams", nargs="?", default="[]")
    defer_p.add_argument("--motive")

    # note <key> <msg>
    note_p = subparsers.add_parser("note")
    note_p.add_argument("key")
    note_p.add_argument("msg")

    # resolve <key>
    resolve_p = subparsers.add_parser("resolve")
    resolve_p.add_argument("key")

    # view
    subparsers.add_parser("view")

    # cancel <key>
    cancel_p = subparsers.add_parser("cancel")
    cancel_p.add_argument("key")

    # summarize
    subparsers.add_parser("summarize")

    args = parser.parse_args()
    state_file, log_file = get_filenames(args.uuid)

    timestamp = datetime.now().isoformat()

    if args.command == "ask":
        event = {"event": EventType.ASK, "theme": args.key, "motive": args.motive, "timestamp": timestamp}
        append_state(state_file, event)
        log_entry = f"* **[ASK: {args.key}]**"
        if args.motive:
            log_entry += f" (Motive: {args.motive})"
        log_entry += "\n"
        append_log(log_file, log_entry)
        sys.exit(0)

    elif args.command == "defer":
        try:
            upstreams = json.loads(args.upstreams)
        except json.JSONDecodeError:
            upstreams = []
        event = {
            "event": EventType.DEFER,
            "theme": args.key,
            "upstreams": upstreams,
            "motive": args.motive,
            "timestamp": timestamp
        }
        append_state(state_file, event)
        log_entry = f"* **[DEFER: {args.key}]**"
        if upstreams:
            log_entry += f" Upstreams: {', '.join(upstreams)}"
        if args.motive:
            log_entry += f" (Motive: {args.motive})"
        log_entry += "\n"
        append_log(log_file, log_entry)
        sys.exit(0)

    elif args.command == "note":
        log_entry = f"* **[NOTE: {args.key}]** {args.msg}\n"
        append_log(log_file, log_entry)
        sys.exit(0)

    elif args.command == "resolve":
        event = {"event": EventType.RESOLVE, "theme": args.key, "timestamp": timestamp}
        append_state(state_file, event)
        sys.exit(0)

    elif args.command == "view":
        state = reconcile_state(state_file)
        print(json.dumps(state.to_dict(), indent=2))
        sys.exit(0)

    elif args.command == "cancel":
        event = {"event": EventType.CANCEL, "theme": args.key, "timestamp": timestamp}
        append_state(state_file, event)
        state = reconcile_state(state_file)
        print(json.dumps({"todo": list(state.todo.keys())}, indent=2))
        sys.exit(0)

    elif args.command == "summarize":
        state = reconcile_state(state_file)
        print(json.dumps({"todo": list(state.todo.keys())}, indent=2))
        sys.exit(0)


if __name__ == "__main__":
    main()
