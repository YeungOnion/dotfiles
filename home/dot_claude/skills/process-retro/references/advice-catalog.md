# Advice catalog

Pick only entries the data supports. For each, cite the moment in the user's history that triggered it.

## Do more

| Practice | Source | Use when the history shows |
|---|---|---|
| Write the sequence or state table before discussing | Amazon's written-narrative practice; Nygard, "Documenting Architecture Decisions" (2011) | Many prompts circling a design, then one written sequence collapsing it |
| Build a tracer bullet: one thin path end to end | Hunt and Thomas, *The Pragmatic Programmer* | Design of extensions and future features before any slice ran |
| Time-box a spike with a stopping rule | Beck, *Extreme Programming Explained* (spike) | Open-ended investigation with no stated "done" |
| Classify decisions as one-way or two-way doors | Bezos, 2015 shareholder letter | Equal effort spent on a recoverable and an irreversible decision |
| Run a pre-mortem before configuring anything | Klein, "Performing a Project Premortem", HBR 2007 | Environment changes made, then dropped when the design moved |
| Choose existing patterns over new ones | McKinley, "Choose Boring Technology" (2015) | Choosing to follow the system's own approval or extension pattern |
| State the failure signal before the experiment | The user's own `pass-fail-conditions.md` | A pass rule that failed while nothing broke |

## Do less (with a tripwire)

| Pattern | Tripwire | Source |
|---|---|---|
| Designing by conversation | 2 or more approach changes in a session where the only new input was talk | Gall, *Systemantics* (a working simple system evolves; a designed complex one doesn't) |
| Presumptive features | An element justified by "eventually", "later" or "in case" | Fowler, "Yagni" (2015) |
| Abstraction with one user | A provider- or backend-agnostic layer with exactly one implementation | Metz, "The Wrong Abstraction" (2016) |
| Second-system expansion | Everything deferred from v1 arriving in the next design | Brooks, *The Mythical Man-Month* |
| Configuring ahead of a settled design | Dashboard, config or credential work started in the same session as the first design | Pre-mortem and spike practice above |
| Assistant elaboration | The assistant's proposal contains parts the user's own sequence doesn't need | Ask "what does this add that my sequence doesn't need?" |
| Undefined done | A gate or experiment with no stated stopping rule | The user's `pass-fail-conditions.md` |
