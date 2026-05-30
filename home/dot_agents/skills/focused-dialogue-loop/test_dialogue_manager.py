import unittest
from pathlib import Path
from unittest.mock import patch, mock_open

# Assuming the original file is named dialogue_manager.py
from executable_dialogue_session import (
    Question,
    DialogueState,
    QuestionState,
    EventType,
)


class TestQuestionInnermostLogic(unittest.TestCase):
    """Focuses directly on the pure graph traversal mechanics and structure."""

    def test_traverse_base_case_empty(self) -> None:
        """traverse should immediately return the total collection if the iterator is empty."""
        initial_total = {Question("Existing")}
        empty_iterator = iter([])

        result = Question.traverse(empty_iterator, initial_total)
        self.assertEqual(set(result), initial_total)

    def test_traverse_recursive_unrolling(self) -> None:
        """traverse should unroll complex DAGs into a single flat set without duplicate steps."""
        q3 = Question("Leaf")
        q2 = Question("Branch", upstreams=(q3,))
        q1 = Question("Root", upstreams=(q2, q3))

        # We pass the entry point directly into traverse as a raw iterator
        result = list(Question.traverse(iter([q1]), set()))

        self.assertEqual(len(result), 3)
        self.assertEqual(set(result), {q1, q2, q3})

    def test_all_children_thin_wrapper(self) -> None:
        """all_children should merely bridge self into the core traverse logic safely."""
        q = Question("Standalone")
        self.assertEqual(q.all_children(), [q])


class TestDialogueStateMutatorUnits(unittest.TestCase):
    """Isolates the state machine transitions by targeting `_mutate` directly with raw events."""

    def setUp(self) -> None:
        self.state = DialogueState()

    def test_mutate_ask_action(self) -> None:
        """_mutate must ingest an ASK dictionary payload and safely transition state."""
        event = {"event": EventType.ASK, "theme": "CoreEngine"}
        self.state._mutate(event)
        self.assertEqual(self.state._seen_in("CoreEngine"), QuestionState.TODO)

    def test_mutate_defer_action_resolves_strings(self) -> None:
        """_mutate must convert raw upstream string primitives from json payloads into Question objects."""
        event = {
            "event": EventType.DEFER,
            "theme": "FeatureX",
            "upstreams": ["DependencyY"],
        }
        # Pre-seed DependencyY as a TODO so it follows the internal routing rule
        self.state.todo.add(Question("DependencyY"))

        self.state._mutate(event)

        self.assertEqual(self.state._seen_in("FeatureX"), QuestionState.TODO)
        self.assertEqual(self.state._seen_in("DependencyY"), QuestionState.TODO)

    def test_mutate_resolve_action(self) -> None:
        """_mutate must transition a targeted theme out of todo buckets and into done buckets."""
        # Setup initial internal state without calling orchestration layers
        self.state.todo.add(Question("FixBug"))

        event = {"event": EventType.RESOLVE, "theme": "FixBug"}
        self.state._mutate(event)

        self.assertEqual(self.state._seen_in("FixBug"), QuestionState.DONE)

    def test_mutate_cancel_action(self) -> None:
        """_mutate must cleanly move a tracking topic into the canceled set."""
        self.state.todo.add(Question("AbortedTask"))

        event = {"event": EventType.CANCEL, "theme": "AbortedTask"}
        self.state._mutate(event)

        self.assertEqual(self.state._seen_in("AbortedTask"), QuestionState.CANCELED)


class TestDialogueStateInternalHelpers(unittest.TestCase):
    """Validates low-level conditional checks inside DialogueState."""

    def test_seen_in_structural_resolution(self) -> None:
        """_seen_in must compare string themes correctly against structural objects inside self.todo."""
        state = DialogueState()
        state.todo.add(Question(theme="MatchMe"))

        # This confirms that searching via a pure string primitive successfully
        # unwraps the Question instance checked inside the set container.
        self.assertEqual(state._seen_in("MatchMe"), QuestionState.TODO)
        self.assertIsNone(state._seen_in("MissingTarget"))


if __name__ == "__main__":
    unittest.main()
