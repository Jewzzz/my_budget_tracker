# Personal Budget Tracker

Domain language for the Personal Budget Tracker application.

## Language

**Account**:
A designated financial container (such as a checking account, savings account, cash wallet, or credit card) holding a balance against which transactions occur.
_Avoid_: Pot, bucket, payment method

**Transaction**:
A record of money movement that occurs on a specific date within or between accounts.
_Avoid_: Entry, log, item

**Income**:
A transaction representing an inflow of money from an external source that increases the balance of an Account and counts toward total earnings.
_Avoid_: Deposit, credit

**Expense**:
A transaction representing an outflow of money to an external entity that decreases the balance of an Account and counts toward budget spending.
_Avoid_: Debit, payout, bill

**Transfer**:
A transaction representing an atomic movement of money from a source Account to a destination Account, adjusting individual account balances without changing overall net worth or registering as an Income or Expense.
_Avoid_: Internal transaction, movement

**Money**:
An immutable value object representing a financial quantity stored as an integer in minor units (e.g., cents), guaranteeing exact arithmetic without floating-point error.
_Avoid_: Amount (as a type), price, float value

**Primary Currency**:
The single user-selected fiat currency (e.g., USD, EUR, LKR) governing the display symbol and currency code for all accounts, transactions, budgets, savings goals, and financial reports throughout the application. Changing the Primary Currency updates only how monetary amounts are labeled and does not convert or alter stored financial values.
_Avoid_: Base currency, default currency, exchange currency

**Category**:
A classification assigned to a transaction denoting its functional purpose, strictly partitioned by type as an Expense Category or an Income Category.
_Avoid_: Tag, label, folder, group

**Budget**:
An allocated maximum spending limit established for a specific Expense Category over a defined calendar month.
_Avoid_: Allowance, target, quota, envelope

**Over-Budget**:
The condition wherein the cumulative expenses for a category exceed its allocated Budget limit within a calendar month.
_Avoid_: Deficit, overdraft, in the red

**Savings Goal**:
A target financial objective specifying a desired monetary target (`targetAmount`), an optional completion deadline, and an accumulated balance (`savedAmount`) backed by verified account funds.
_Avoid_: Piggy bank, wishlist, pot, fund

**Goal Contribution**:
An auditable financial record representing an allocation or transfer of money from an Account toward a Savings Goal.
_Avoid_: Top-up, manual adjustment

**Backup**:
An exportable, point-in-time snapshot of the complete application database and user records used for device-to-device migration and disaster recovery without an external cloud backend.
_Avoid_: Dump, sync archive, export (when referring specifically to the full database snapshot)

**Cash Flow**:
The net financial difference between total Income and total Expenses within a defined reporting period, strictly excluding Transfers.
_Avoid_: Profit, revenue, net income (when referring to period cash flow)

**Savings Rate**:
The mathematical ratio of positive Cash Flow to total Income expressed as a percentage bounded between 0% and 100%, safely defaulting to 0% when income is zero or non-positive.
_Avoid_: Profit margin, savings percentage

**Net Worth**:
The cumulative aggregate balance across all Accounts evaluated at a given point in time.
_Avoid_: Wealth, assets (as a single aggregate metric)

