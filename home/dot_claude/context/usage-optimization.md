Claude Code Usage Optimization - Quick Reference

  Start Today

  1. Create .claude/context/vadar-architecture.md - Core system docs for @ referencing
  2. Create .claude/context/dairy-domain.md - Business context to stop re-explaining
  3. Use @ references instead of inline descriptions: @src/file.ts not "the file that does X"

  This Week

  1. Add .claude/commands/debug-template - Standard debug format with error/expected/context/need
  structure
  2. Add .claude/commands/review-template - Code review with specific criteria
  (performance/security/maintainability)
  3. Batch related requests in single prompts instead of iterating

  Tools to Use

  - Claude Code built-ins: .claude/context/ and .claude/commands/ (zero setup)
  - Skip external tools for now - built-ins solve 80% of problems

  Meta-Agent Cue

  "Before prompting: Check if context exists in .claude/context/. Use @ references. Specify success
   criteria. Batch related work. Stop re-explaining systems."

  Success Metric

  Transform 500+ char context-heavy prompts into focused 150-char prompts with @ references.

  ---Save this in .claude/context/usage-optimization.md for meta-reference
