# Category-Based Monthly Spending Limits

We decided to model budgeting as monthly spending limits assigned to specific expense categories, resetting each calendar month without automatic cumulative rollover by default.

Category-based spending limits provide an intuitive mental model for users without the high cognitive barrier of zero-based envelope budgeting. From an architectural standpoint, bounded monthly spending limits allow queries to execute in $O(1)$ relative to total historical data (scoping sums strictly within the current month's timestamp bounds) and eliminate complex recursive balance recalculations across past months.

