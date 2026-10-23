# Pass conditions

A gate's pass condition names a measured signal of failure, not a rule of thumb.

Before a gate runs, ask "what would actually break, and how would we see it?" Write the pass condition from that answer. Name the source of the number (counter, command, log), its unit, and the threshold.

Example (NanoClaw migration, G10, 2026-10-21): "Windows Available above 1 GB" failed four times while nothing broke. Windows fills spare RAM with cache by design, so Available measured nothing about failure. The working condition: commit stays clearly below the commit limit, no Resource-Exhaustion event 2004, no sustained hard-fault spikes, no OOM kills, the workload's tasks complete, and the operator doesn't notice slowness.

## When the expected signal is corrupted

Report these caveats with the result. Don't quietly pass or fail.

- **A counter mixes causes.** Pages Input/sec counts pagefile reads and ordinary file loads together, so a single spike isn't memory pressure. Look for sustained values plus a second, corroborating signal.
- **A different counter than intended.** A free-memory reading that excludes standby isn't comparable with one that includes it. Record which counter produced each number.
- **The load window is too short.** An agent that backgrounds its work ends the run in seconds. Check that the load actually ran for the stated duration before trusting the samples.
- **The measurement disturbs the system.** Cache drops, extra sampling processes and restarts change what you measure. Note them.
- **Self-reported state.** "Done" from a peer session, a tool, or a status page is a claim. Verify it with an independent observation where you can, and say when you couldn't.
- **No baseline.** A delta needs a before-reading taken the same way. If none exists, say the number is a single point.

## Tri-state results

Record gates as Pass, Pass with change, Fail, or Not applicable, with a column for what changed. The changes are the lessons the next plan needs.
