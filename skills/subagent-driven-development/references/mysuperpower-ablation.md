# mySuperpower: Ablation pass before the final review

Once every task's ledger line reads `complete` — including
`complete (... parked)` after a tripped breaker — and before running
`scripts/review-package` for the final review, the controller runs one
ablation pass over the branch itself. No subagent:

1. List every abstraction the branch added: helpers, interfaces, base
   classes, config knobs, wrappers, layers, indirection of any kind.
2. For each one, replace it with the direct thing — inline the single-use
   helper, call the one implementation, write the never-changing value —
   and run the full test suite. Behavior stays; only the layer goes.
3. Name what failed: a test, a spec requirement, or a second caller that
   now has nothing to call. "It might be useful later" is not a failure.
4. If something failed, restore the abstraction and move on. If nothing
   failed, commit the removal. The review package diffs MERGE_BASE..HEAD,
   so an uncommitted removal is invisible to the final reviewer.
5. Record each removal, and each restore with its reason, as a decision
   card in the implementation notes and a `Ruling:` line in the ledger.

The final reviewer then reviews the ablated branch. Run this once, at the
end; per-task ablation removes scaffolding before its consumer exists.
