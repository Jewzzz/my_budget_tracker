# Account-Backed Savings Goals

We decided to model Savings Goals as account-backed entities whose contributions and withdrawals must be linked to real Account balances via auditable ledger records, rather than isolated manual counters.

Isolated goal counters produce a "phantom money" problem where user-reported savings can exceed actual liquid funds, creating contradictory states between account balances and goal progress. Binding goal contributions to verified accounts enforces domain invariants, ensures mathematical consistency across dashboard summaries, and provides an immutable audit trail of how goals are funded.

