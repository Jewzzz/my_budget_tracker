# Technical Specification: Personal Budget Tracker

**Status**: `ready-for-agent`  
**Target Platform**: Android (Flutter / Dart)  
**Architecture**: Feature-Driven Clean Architecture (`flutter_bloc` + Drift SQLite)  
**References**: [GLOSSARY.md](file:///c:/Jeewaka/Flutter/my_budget_tracker/GLOSSARY.md), [ADR-0001](file:///c:/Jeewaka/Flutter/my_budget_tracker/docs/adr/0001-account-based-transaction-model.md) to [ADR-0009](file:///c:/Jeewaka/Flutter/my_budget_tracker/docs/adr/0009-navigation-and-ui-design-system.md)

---

## Problem Statement

Individuals seeking to take control of their personal finances frequently struggle with existing mobile budgeting solutions for three major reasons:
1. **Reporting Distortion & Transfer Confusion**: Basic expense trackers treat all money movements as either income or expense. When users move money between their own accounts (e.g. withdrawing ATM cash or funding a savings goal), the app logs it as spending, corrupting cash flow reports and monthly budget limits.
2. **Rounding Errors & Calculation Inconsistencies**: Apps using floating-point math accumulate rounding drift over time, causing discrepancies between reported account balances and actual bank statements.
3. **Data Privacy & Lock-in Vulnerability**: Cloud-reliant apps require sensitive banking credentials, mandate monthly subscriptions, and risk total data loss if the service shuts down or the user is offline. Conversely, simple offline apps lack robust backup mechanisms, risking permanent data loss if a phone is lost or replaced.

Users need an offline-first, mathematically exact, and private personal finance manager that supports genuine account-based tracking with native transfers, category-based monthly budgeting, auditable savings goals, and reliable disaster recovery.

---

## Solution

The Personal Budget Tracker is an Android-first, 100% offline-capable personal finance application built with Flutter, Dart, and Clean Architecture.

Key aspects of the solution:
* **Account-Based Architecture with Native Transfers**: Every transaction belongs to a designated Account (Checking, Savings, Cash, Credit Card). Transfers move funds between accounts atomically without altering net worth or corrupting income/expense metrics.
* **Exact Integer Monetary Math**: Every financial amount is stored as integer minor units (cents) wrapped in an immutable `Money` Value Object, ensuring zero floating-point rounding errors across all queries and views.
* **Monthly Category Budgets**: Clean monthly spending limits per expense category with immediate over-budget detection and zero recursive calculation lag.
* **Account-Backed Savings Goals**: Savings goals are directly funded via verifiable transfers from active accounts, maintaining an immutable ledger trail and eliminating "phantom money".
* **On-Device Security & Data Sovereignty**: Biometric/PIN authentication protects sensitive financial data locally, while atomic file-based backup/restore and CSV export ensure users retain complete ownership of their data without requiring an external cloud server.

---

## User Stories

### 1. Account Management
1. As a user, I want to create multiple Accounts with a name, type (Checking, Savings, Cash, Credit Card), and initial balance, so that I can mirror my real-world financial setup.
2. As a user, I want to edit an Account's name, icon, or color, so that my account list stays organized and recognizable.
3. As a user, I want to view the current balance of each Account, so that I always know how much liquid money I have in each container.
4. As a user, I want the system to prevent deleting an Account that has existing transactions, so that my historical ledger and reports are protected from corruption.
5. As a user, I want to archive an inactive Account rather than delete it, so that historical transactions remain intact while hiding the account from daily entry pickers.

### 2. Transaction Tracking & Transfers
6. As a user, I want to log an Expense by specifying amount, Account, Expense Category, date, and optional note, so that my spending is accurately categorized.
7. As a user, I want to log an Income by specifying amount, Account, Income Category, date, and optional note, so that my earnings are properly recorded.
8. As a user, I want to execute a Transfer between two Accounts (Source and Destination), so that funds move between accounts without being counted as an expense or income.
9. As a user, I want a persistent Floating Action Button (FAB) accessible from any tab, so that I can open the transaction entry form and record an expense in under five seconds.
10. As a user, I want to edit or delete any existing Transaction, so that I can correct accidental entry errors with automatic balance recalculation.
11. As a user, I want to search and filter transactions by keyword, Account, Category, Type (Income, Expense, Transfer), and date range, so that I can audit past spending easily.

### 3. Categories & Monthly Budgets
12. As a user, I want predefined default Categories (e.g. Groceries, Housing, Dining, Salary) and the ability to add custom Categories with distinct icons and colors, so that my transactions match my lifestyle.
13. As a user, I want Categories to be strictly partitioned into Expense Categories and Income Categories, so that I cannot accidentally classify an expense under an income category.
14. As a user, I want to set a monthly spending limit (Budget) for any Expense Category for the current calendar month, so that I can control my discretionary spending.
15. As a user, I want to view visual progress meters showing how much I have spent and how much remains for each budgeted category, so that I can pace my spending throughout the month.
16. As a user, I want an immediate visual warning when a category exceeds 100% of its budget (Over-Budget), so that I know I have overspent without the negative debt automatically cascading into the next month.
17. As a user, I want to navigate between different calendar months to review past budget performance, so that I can identify recurring spending patterns.

### 4. Savings Goals
18. As a user, I want to create a Savings Goal with a title, target amount, optional deadline date, icon, and color, so that I can save toward specific life milestones.
19. As a user, I want to deposit money into a Savings Goal by selecting a funding Account, so that money moves from my account into the goal with an auditable transaction.
20. As a user, I want the system to reject a goal contribution if the funding Account has insufficient funds, so that phantom savings cannot be created.
21. As a user, I want to withdraw funds from a Savings Goal back to an Account, so that I can access saved funds in an emergency.
22. As a user, I want to mark a Savings Goal as completed when the target is reached, so that my active goal dashboard stays focused on in-progress objectives.

### 5. Financial Reports & Analytics
23. As a user, I want to view a monthly Cash Flow report showing Total Income, Total Expenses, Net Cash Flow, and Savings Rate, so that I can monitor my financial health.
24. As a user, I want Transfers to be strictly excluded from Cash Flow and spending charts, so that internal money movements do not distort my analytics.
25. As a user, I want a Category Spending Breakdown donut chart and ranked list, so that I can visualize what percentage of my money goes to each category.
26. As a user, I want a Net Worth trend chart tracking the cumulative sum of all account balances over time, so that I can see my overall wealth trajectory.
27. As a user, I want report calculations to handle edge cases safely (e.g. 0% savings rate when income is zero or net cash flow is negative), so that charts never crash or render `NaN`.

### 6. Security, Backup & System Settings
28. As a user, I want to choose my Primary Currency (e.g. USD, EUR, LKR, GBP) during onboarding or in Settings, so that all currency symbols and formatting match my locale.
29. As a user, I want to enable Biometric authentication (Fingerprint / Face Unlock) or a fallback PIN, so that unauthorized people cannot view my financial data.
30. As a user, I want the application to automatically lock when backgrounded or closed, so that my financial privacy is maintained.
31. As a user, I want to export a point-in-time database backup file (`.mbk` / JSON snapshot), so that I can safeguard my financial data or migrate to a new device.
32. As a user, I want to restore my data from an existing backup file with atomic rollback on failure, so that I can recover my data without corruption.
33. As a user, I want to export all transactions into a standard CSV file, so that I can analyze my finances in spreadsheet applications like Microsoft Excel or Google Sheets.

---

## Implementation Decisions

### 1. Application Architecture: Feature-Driven Clean Architecture
The application is structured into four concentric layers following Clean Architecture principles, organized feature-first under `lib/features/`:

```
lib/
├── core/
│   ├── database/             # Drift database definition, tables, DAOs, migrations
│   ├── error/                # Domain failures, exceptions, error mapper
│   ├── theme/                # Material 3 light/dark color schemes, typography, dimensions
│   ├── utils/                # Date/time formatters, currency formatters
│   └── value_objects/        # Immutable Money Value Object
└── features/
    ├── accounts/             # data/ (models, repo impl), domain/ (entities, use cases), presentation/ (cubit, pages, widgets)
    ├── transactions/         # data/, domain/, presentation/
    ├── budgets/              # data/, domain/, presentation/
    ├── savings_goals/        # data/, domain/, presentation/
    ├── reports/              # data/, domain/, presentation/
    └── settings/             # data/, domain/, presentation/ (currency, security, backup/export)
```

#### Layer Boundaries & Invariants:
* **Domain Layer (`domain/`)**: Pure Dart with zero Flutter or third-party database dependencies. Contains:
  * Entities (immutable domain objects with business logic).
  * Value Objects (`Money`).
  * Repository Interfaces (contracts defining data operations).
  * Use Cases (single-responsibility business workflows, e.g. `ExecuteTransferUseCase`).
  * Failures (`DomainFailure` hierarchy).
* **Data Layer (`data/`)**: Implements Repository interfaces using Drift DAOs. Responsible for converting Drift Table Data classes into pure Domain Entities and enforcing persistence transactions.
* **Presentation Layer (`presentation/`)**: Built on `flutter_bloc` / Cubit. Cubits consume Use Cases and emit immutable UI States. Widgets are dumb renderers that listen to states and trigger methods/events.

---

### 2. Domain Models & Invariants

#### `Money` Value Object
* Stored internally as `final int minorUnits` (e.g. \$15.75 = `1575`).
* Implements operators: `+`, `-`, `* (int)`, `>` , `<`, `>=`, `<=`, `==`.
* Invariant: Division by another currency is forbidden; scaling requires an integer or explicit rounding mode.
* Formatted according to the user's `PrimaryCurrency` and system locale via `intl.NumberFormat.currency`.

#### `Account` Entity
* Fields: `id` (UUID string), `name` (String), `type` (Enum: `checking`, `savings`, `cash`, `creditCard`), `initialBalance` (`Money`), `currentBalance` (`Money`), `isArchived` (bool), `icon` (String), `color` (int).
* Invariant: Current balance must equal:
  $$\text{Initial Balance} + \sum(\text{Income}) - \sum(\text{Expenses}) + \sum(\text{Transfers In}) - \sum(\text{Transfers Out})$$

#### `Transaction` Entity
* Fields: `id` (UUID string), `accountId` (UUID string), `type` (Enum: `income`, `expense`, `transfer`), `amount` (`Money`), `categoryId` (UUID string, null for transfers), `destinationAccountId` (UUID string, required only for transfers), `date` (DateTime UTC), `note` (String?), `createdAt` (DateTime UTC).
* Invariants:
  * `amount.minorUnits > 0` (zero or negative transaction amounts are strictly prohibited).
  * If `type == transfer`, `destinationAccountId` must be non-null and distinct from `accountId`.
  * If `type == expense` or `type == income`, `categoryId` must be non-null.

#### `Category` Entity
* Fields: `id` (UUID string), `name` (String), `type` (Enum: `expense`, `income`), `icon` (String), `color` (int), `isDefault` (bool).
* Invariant: An expense transaction cannot reference an income category; an income transaction cannot reference an expense category.

#### `Budget` Entity
* Fields: `id` (UUID string), `categoryId` (UUID string), `year` (int), `month` (int: 1-12), `limitAmount` (`Money`).
* Invariants:
  * Exactly one budget entry allowed per `(categoryId, year, month)` tuple (enforced by a composite unique constraint in database).
  * Category must be of type `expense`.

#### `SavingsGoal` Entity
* Fields: `id` (UUID string), `name` (String), `targetAmount` (`Money`), `savedAmount` (`Money`), `targetDate` (DateTime?), `status` (Enum: `inProgress`, `completed`, `cancelled`), `icon` (String), `color` (int).
* Invariants:
  * `savedAmount.minorUnits >= 0`.
  * Cannot contribute more funds than are available in the funding Account.

#### `GoalContribution` Entity
* Fields: `id` (UUID string), `goalId` (UUID string), `accountId` (UUID string), `amount` (`Money`), `type` (Enum: `deposit`, `withdrawal`), `date` (DateTime UTC), `note` (String?).

---

### 3. Database Design & Relational Schema (Drift / SQLite)

Relational schema enforced via Drift table declarations:

```sql
-- Accounts Table
CREATE TABLE accounts (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    account_type TEXT NOT NULL,
    initial_balance_minor_units INTEGER NOT NULL DEFAULT 0,
    current_balance_minor_units INTEGER NOT NULL DEFAULT 0,
    is_archived INTEGER NOT NULL DEFAULT 0,
    icon TEXT NOT NULL,
    color INTEGER NOT NULL,
    created_at INTEGER NOT NULL
);

-- Categories Table
CREATE TABLE categories (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    category_type TEXT NOT NULL, -- 'expense' | 'income'
    icon TEXT NOT NULL,
    color INTEGER NOT NULL,
    is_default INTEGER NOT NULL DEFAULT 0
);

-- Transactions Table
CREATE TABLE transactions (
    id TEXT PRIMARY KEY NOT NULL,
    account_id TEXT NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT,
    transaction_type TEXT NOT NULL, -- 'income' | 'expense' | 'transfer'
    amount_minor_units INTEGER NOT NULL,
    category_id TEXT REFERENCES categories(id) ON DELETE RESTRICT,
    destination_account_id TEXT REFERENCES accounts(id) ON DELETE RESTRICT,
    transaction_date INTEGER NOT NULL, -- UTC epoch milliseconds
    note TEXT,
    created_at INTEGER NOT NULL
);

-- Budgets Table
CREATE TABLE budgets (
    id TEXT PRIMARY KEY NOT NULL,
    category_id TEXT NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    limit_minor_units INTEGER NOT NULL,
    UNIQUE(category_id, year, month)
);

-- Savings Goals Table
CREATE TABLE savings_goals (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    target_amount_minor_units INTEGER NOT NULL,
    saved_amount_minor_units INTEGER NOT NULL DEFAULT 0,
    target_date INTEGER,
    status TEXT NOT NULL DEFAULT 'inProgress',
    icon TEXT NOT NULL,
    color INTEGER NOT NULL,
    created_at INTEGER NOT NULL
);

-- Goal Contributions Table
CREATE TABLE goal_contributions (
    id TEXT PRIMARY KEY NOT NULL,
    goal_id TEXT NOT NULL REFERENCES savings_goals(id) ON DELETE CASCADE,
    account_id TEXT NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT,
    amount_minor_units INTEGER NOT NULL,
    contribution_type TEXT NOT NULL, -- 'deposit' | 'withdrawal'
    contribution_date INTEGER NOT NULL,
    note TEXT
);

-- Performance Indexes
CREATE INDEX idx_transactions_date ON transactions(transaction_date);
CREATE INDEX idx_transactions_account ON transactions(account_id);
CREATE INDEX idx_transactions_category ON transactions(category_id);
CREATE INDEX idx_budgets_lookup ON budgets(year, month);
CREATE INDEX idx_goal_contributions_goal ON goal_contributions(goal_id);
```

#### Database Rules & Integrity:
* `ON DELETE RESTRICT` on `account_id` and `category_id` prevents accidental deletion of entities that have active transactions.
* Atomic transfers execute inside `transaction(() async { ... })`: inserting the transfer transaction and updating both source and destination account balances atomically.
* Reactive streams (`watch()`) are exposed through repositories, allowing UI components to automatically re-render when transactions alter balances.

---

### 4. Financial Calculation Rules & Edge Cases

1. **Account Balance Calculation**:
   $$\text{Balance}_{\text{new}} = \text{Balance}_{\text{current}} + \begin{cases} 
   +\text{Amount} & \text{if Income} \\ 
   -\text{Amount} & \text{if Expense} \\ 
   -\text{Amount} & \text{if Transfer Out (Source)} \\ 
   +\text{Amount} & \text{if Transfer In (Destination)} 
   \end{cases}$$
2. **Monthly Budget Status**:
   * Evaluated strictly within local calendar boundaries:
     $$\text{StartOfMonth} = \text{DateTime}(year, month, 1, 0, 0, 0)\text{.toUtc().millisecondsSinceEpoch}$$
     $$\text{EndOfMonth} = \text{DateTime}(year, month + 1, 0, 23, 59, 59, 999)\text{.toUtc().millisecondsSinceEpoch}$$
   * Category Spend: $\text{Spent} = \sum \text{amount}$ for all expenses in category where $\text{transaction\_date} \in [\text{StartOfMonth}, \text{EndOfMonth}]$.
   * Remaining Budget: $\text{Limit} - \text{Spent}$.
   * Over-budget condition: $\text{Spent} > \text{Limit}$. When true, UI renders amber/red alert styling, but remaining budget is reported as negative allowance without cascading into subsequent months.
3. **Cash Flow & Savings Rate**:
   * $\text{Net Cash Flow} = \sum \text{Income} - \sum \text{Expense}$. (Transfers excluded).
   * **Savings Rate Formula (Clamped)**:
     $$\text{Savings Rate} = \begin{cases} 
     0.0 & \text{if } \text{Income} \le 0 \text{ or } \text{Net Cash Flow} \le 0 \\ 
     \min(100.0, \frac{\text{Net Cash Flow}}{\text{Total Income}} \times 100.0) & \text{if } \text{Income} > 0 \text{ and } \text{Net Cash Flow} > 0 
     \end{cases}$$
4. **Category Breakdown Percentage**:
   $$\text{Category Share} = \begin{cases} 0.0 & \text{if } \text{Total Expenses} \le 0 \\ \frac{\text{Category Spend}}{\text{Total Expenses}} \times 100.0 & \text{otherwise} \end{cases}$$

---

### 5. Application Navigation & UI/UX

* **Scaffold Structure**: 5-Tab Navigation Bar built on Material 3:
  1. **Dashboard**: Summary cards for Total Net Worth, Monthly Cash Flow, Quick Budget Progress, Recent Transactions list, and Top App Bar with Settings icon.
  2. **Transactions**: Search bar, multi-select filters (Account, Category, Date range, Type), sticky date section headers, transaction detail view.
  3. **Budgets**: Month selector header (`< May 2026 >`), Total Budget vs Total Spent banner, list of category progress cards with progress bars (Green < 80%, Orange 80-100%, Red > 100%).
  4. **Goals**: Active goals cards, completion percentage radial gauges, "Contribute" / "Withdraw" modal dialogs, completed goals archive.
  5. **Reports**: Tabbed analytics (Cash Flow bar chart, Category donut chart via `fl_chart`, Net Worth trend line chart).
* **Global Quick-Add FAB**:
  * Centered Floating Action Button docked above the bottom bar.
  * Tapping instantly opens a bottom modal sheet with transaction type tabs (Expense [default], Income, Transfer).
  * Auto-focuses the numeric keypad for rapid entry in under five seconds.
* **Theme & Colors**:
  * Material 3 color system with dynamic Light and Dark theme support.
  * Semantic financial colors:
    * Income: Emerald Green (`#10B981`)
    * Expense: Crimson / Coral (`#EF4444`)
    * Transfer: Indigo / Blue (`#3B82F6`)

---

### 6. Error Handling Architecture

The application adopts a functional error-handling approach using a sealed `DomainFailure` hierarchy returned in Dart `Either<DomainFailure, T>` or thrown as typed domain exceptions caught by Blocs:

```dart
sealed class DomainFailure {
  final String message;
  const DomainFailure(this.message);
}

class InsufficientFundsFailure extends DomainFailure {
  const InsufficientFundsFailure() : super('Selected account has insufficient funds for this action.');
}

class AccountHasTransactionsFailure extends DomainFailure {
  const AccountHasTransactionsFailure() : super('Cannot delete an account with existing transactions. Archive it instead.');
}

class CategoryHasTransactionsFailure extends DomainFailure {
  const CategoryHasTransactionsFailure() : super('Cannot delete category in use by existing transactions.');
}

class DatabaseFailure extends DomainFailure {
  const DatabaseFailure(super.message);
}

class BackupCorruptionFailure extends DomainFailure {
  const BackupCorruptionFailure(super.message);
}
```

UI layers catch domain failures and display user-friendly SnackBar banners or inline form validation messages without ever exposing raw database exceptions.

---

### 7. Security & Backup Engine

1. **Authentication (`local_auth` & `flutter_secure_storage`)**:
   * Uses Android `BiometricPrompt` for Fingerprint and Face Unlock.
   * Fallback 4-to-6 digit PIN.
   * PIN verification hash stored in encrypted Android Keystore via `flutter_secure_storage`.
   * App listens to `WidgetsBindingObserver` `didChangeAppLifecycleState`: when app enters `AppLifecycleState.paused` or `detached`, authentication state resets to locked.
2. **File-Based Backup & Restore**:
   * Export Backup: Generates a timestamped JSON/SQLite snapshot containing schema version, checksum, and all table records. User can share or save to local storage/Google Drive using `share_plus` / `file_picker`.
   * Import Backup: Validates JSON structure, verifies schema version compatibility, and executes the entire restore inside an atomic SQLite transaction. If any record fails insertion, transaction rolls back automatically.
3. **CSV Export (`csv`)**:
   * Standard header: `Date,Type,Account,Category,Amount,Currency,Note`.
   * Formats UTC timestamps to local ISO-8601 dates and minor units to formatted decimal strings (`1050` -> `10.50`).

---

## Testing Decisions

### Testing Seams (Highest Level Possible)
1. **Primary High Seam (The Core Seam)**: **Domain Use Cases / Blocs tested against an in-memory Drift SQLite database**.
   * By instantiating `AppDatabase.inMemory()`, we run tests against real SQLite foreign keys, real SQL queries, real transactions, and real reactive streams without mocking data tables.
   * Tests exercise end-to-end business flows (e.g. creating an account, executing a transfer, verifying both account balances and transaction entries) at lightning speed in pure Dart test runners.
2. **Secondary Seam (Presentation / Widget Seam)**: **Widget Tests with Mocked Blocs**.
   * Pumping widget trees with pre-determined Bloc states (`Loading`, `Success`, `Failure`) to verify UI layout, color semantics, and form validations without database overhead.
3. **Unit Seam**:
   * Pure unit tests for the `Money` Value Object (addition, subtraction, formatting, edge cases).
   * Pure unit tests for financial report calculation utilities (savings rate clamped boundaries, zero-division protection).

---

## Out of Scope

The following features were intentionally excluded from this release:
1. **Multi-Currency Conversions**: No real-time or historical exchange rate engines; single primary currency per user.
2. **Cloud Synchronization & Accounts**: No Firebase/Supabase/REST backend; strictly offline-first.
3. **Automated Bank Account Linking (Plaid / OpenBanking)**: Manual transaction entry only.
4. **Receipt Image OCR / AI Scanning**: Out of scope for initial core release.
5. **Cumulative Budget Rollover**: Budgets reset each calendar month without carrying over unspent surplus or deficit debt.
6. **Multi-User / Shared Household Budgets**: Single-user local application.

---

## Implementation Phases

* **Phase 1: Foundation & Data Architecture**
  * Scaffold directory structure under `lib/core/` and `lib/features/`.
  * Implement `Money` Value Object with 100% unit test coverage.
  * Define Drift tables, foreign keys, DAOs, and in-memory test setup.
  * Implement Material 3 themes, semantic financial colors, and base routing.
* **Phase 2: Accounts & Transaction Engine**
  * Implement `accounts` domain, data, and presentation layers.
  * Implement `transactions` domain, data, and presentation layers (Income, Expense, Transfer).
  * Build the persistent Global Quick-Add FAB modal sheet.
  * Verify account balance invariants and transfer atomicity via integration tests.
* **Phase 3: Categories & Monthly Budgets**
  * Seed default categories (Groceries, Housing, Dining, Transportation, Utilities, Entertainment, Healthcare, Salary, Investments).
  * Implement Category management (Expense vs Income partitioning).
  * Implement `budgets` feature: monthly limit definition, progress bar widgets, and over-budget indicators.
* **Phase 4: Account-Backed Savings Goals**
  * Implement `savings_goals` entity, Drift tables, and DAOs.
  * Implement atomic Goal Contribution and Withdrawal use cases linked to real accounts.
  * Build goal cards, visual progress dials, and history timeline.
* **Phase 5: Financial Reports & Analytics**
  * Implement reporting use cases (Cash Flow, Category Breakdown, Net Worth Trend).
  * Integrate `fl_chart` for interactive donut and bar visualizations.
  * Verify local timezone boundary filtering and division-by-zero clamping.
* **Phase 6: Security, Backup & Polish**
  * Implement Biometric / PIN app lock with `local_auth` and `flutter_secure_storage`.
  * Implement file-based backup export/import with atomic restore verification.
  * Implement CSV export.
  * Final end-to-end integration and widget testing pass.

