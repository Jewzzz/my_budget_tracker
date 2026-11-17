# Account-Based Transaction Model with Native Transfers

We decided to structure the domain around Accounts (e.g., checking, savings, cash, credit card) supporting Income, Expense, and atomic Transfers, rather than a flat transaction log.

A flat transaction log cannot distinguish between external spending and internal funds relocation (such as moving money to a savings account or paying off a credit card), which corrupts income/expense analytics and budget tracking. An account-based model guarantees mathematically verifiable balances and clean reporting boundaries while establishing Accounts as distinct domain aggregates.

