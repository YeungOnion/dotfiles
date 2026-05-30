import argparse
import json
import unittest

from executable_dialogue_session import (
    DialogueState,
    EventType,
    LogOp,
    PrintOp,
    Question,
    QuestionState,
    UpdateOp,
    cli_ask,
    cli_cancel,
    cli_defer,
    cli_note,
    cli_resolve,
    cli_summarize,
)

TS = "2026-01-01T00:00:00"


class TestQuestionInnermostLogic(unittest.TestCase):
    """Pure graph traversal mechanics and structure."""

    def test_traverse_base_case_empty(self) -> None:
        """traverse should immediately return the total collection if the iterator is empty."""
        initial_total = {Question("Existing")}
        result = list(Question.traverse(iter([]), initial_total))
        self.assertEqual(set(result), initial_total)

    def test_traverse_recursive_unrolling(self) -> None:
        """traverse should unroll complex DAGs into a single flat set without duplicate steps."""
        q3 = Question("Leaf")
        q2 = Question("Branch", upstreams=(q3,))
        q1 = Question("Root", upstreams=(q2, q3))

        result = list(Question.traverse(iter([q1]), set()))

        self.assertEqual(len(result), 3)
        self.assertEqual(set(result), {q1, q2, q3})

    def test_all_children_thin_wrapper(self) -> None:
        """all_children should merely bridge self into the core traverse logic safely."""
        q = Question("Standalone")
        self.assertEqual(q.all_children(), [q])


class TestDialogueStateMutatorUnits(unittest.TestCase):
    """State machine transitions via _mutate with raw events."""

    def setUp(self) -> None:
        self.state = DialogueState()

    def test_mutate_ask_action(self) -> None:
        self.state._mutate({"event": EventType.ASK, "theme": "CoreEngine"})
        self.assertEqual(self.state._seen_in("CoreEngine"), QuestionState.TODO)

    def test_mutate_defer_action_resolves_strings(self) -> None:
        self.state.todo.add(Question("DependencyY"))
        self.state._mutate({"event": EventType.DEFER, "theme": "FeatureX", "upstreams": ["DependencyY"]})
        self.assertEqual(self.state._seen_in("FeatureX"), QuestionState.TODO)
        self.assertEqual(self.state._seen_in("DependencyY"), QuestionState.TODO)

    def test_mutate_resolve_action(self) -> None:
        self.state.todo.add(Question("FixBug"))
        self.state._mutate({"event": EventType.RESOLVE, "theme": "FixBug"})
        self.assertEqual(self.state._seen_in("FixBug"), QuestionState.DONE)

    def test_mutate_cancel_action(self) -> None:
        self.state.todo.add(Question("AbortedTask"))
        self.state._mutate({"event": EventType.CANCEL, "theme": "AbortedTask"})
        self.assertEqual(self.state._seen_in("AbortedTask"), QuestionState.CANCELED)

    def test_mutate_unknown_event_raises(self) -> None:
        with self.assertRaises(ValueError):
            self.state._mutate({"event": "not-a-real-event", "theme": "X"})


class TestDialogueStateInternalHelpers(unittest.TestCase):
    """Low-level conditional checks inside DialogueState."""

    def test_seen_in_structural_resolution(self) -> None:
        state = DialogueState()
        state.todo.add(Question(theme="MatchMe"))
        self.assertEqual(state._seen_in("MatchMe"), QuestionState.TODO)
        self.assertIsNone(state._seen_in("MissingTarget"))


class TestCliHandlers(unittest.TestCase):
    """CLI handler functions are pure: they take events and return (ops, exit_code)."""

    def test_ask_emits_update_and_log(self) -> None:
        args = argparse.Namespace(key="CoreEngine", motive=None)
        ops, code = cli_ask(args, [], TS)
        self.assertEqual(code, 0)
        self.assertEqual(len(ops), 2)
        self.assertIsInstance(ops[0], UpdateOp)
        self.assertIsInstance(ops[1], LogOp)
        self.assertEqual(ops[0].inner["theme"], "CoreEngine")
        self.assertEqual(ops[0].inner["event"], EventType.ASK)

    def test_ask_includes_motive_in_log(self) -> None:
        args = argparse.Namespace(key="Scope", motive="needed for planning")
        ops, _ = cli_ask(args, [], TS)
        self.assertIn("needed for planning", ops[1].inner)

    def test_note_emits_log_only(self) -> None:
        args = argparse.Namespace(key="Scope", msg="user said X")
        ops, code = cli_note(args, [], TS)
        self.assertEqual(code, 0)
        self.assertEqual(ops, [LogOp("* **[NOTE: Scope]** user said X\n")])

    def test_resolve_emits_update_only(self) -> None:
        args = argparse.Namespace(key="Scope")
        ops, code = cli_resolve(args, [], TS)
        self.assertEqual(code, 0)
        self.assertEqual(ops, [UpdateOp({"event": EventType.RESOLVE, "theme": "Scope", "timestamp": TS})])

    def test_defer_emits_update_with_upstreams(self) -> None:
        args = argparse.Namespace(key="FeatureX", upstreams='["DepA", "DepB"]', motive=None)
        ops, code = cli_defer(args, [], TS)
        self.assertEqual(code, 0)
        self.assertEqual(len(ops), 1)
        self.assertIsInstance(ops[0], UpdateOp)
        self.assertEqual(ops[0].inner["upstreams"], ["DepA", "DepB"])

    def test_cancel_prints_remaining_todo(self) -> None:
        events = [
            {"event": EventType.ASK, "theme": "A"},
            {"event": EventType.ASK, "theme": "B"},
        ]
        args = argparse.Namespace(key="A")
        ops, code = cli_cancel(args, events, TS)
        self.assertEqual(code, 0)
        self.assertIsInstance(ops[0], UpdateOp)
        self.assertIsInstance(ops[1], PrintOp)
        remaining = json.loads(ops[1].inner)
        self.assertEqual(remaining["todo"], ["B"])

    def test_summarize_close_with_open_topics_exits_one(self) -> None:
        events = [{"event": EventType.ASK, "theme": "open-topic"}]
        args = argparse.Namespace(close=True)
        expected_out = json.dumps({"todo": ["open-topic"]}, indent=2)
        self.assertEqual(cli_summarize(args, events, TS), ([PrintOp(expected_out)], 1))

    def test_summarize_close_with_all_resolved_exits_zero(self) -> None:
        events = [
            {"event": EventType.ASK, "theme": "open-topic"},
            {"event": EventType.RESOLVE, "theme": "open-topic"},
        ]
        args = argparse.Namespace(close=True)
        expected_out = json.dumps({"todo": []}, indent=2)
        self.assertEqual(cli_summarize(args, events, TS), ([PrintOp(expected_out)], 0))

    def test_summarize_without_close_never_exits_one(self) -> None:
        events = [{"event": EventType.ASK, "theme": "open-topic"}]
        args = argparse.Namespace(close=False)
        _, code = cli_summarize(args, events, TS)
        self.assertEqual(code, 0)


if __name__ == "__main__":
    unittest.main()
