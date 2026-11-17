# Reporting Engine and Financial Calculations

We decided to structure financial reporting around three standardized analytical views (Cash Flow, Category Spending Breakdown, and Net Worth Trend) calculated over local calendar bounds with strict transfer exclusion and division-by-zero clamping.

Transfers move funds internally and must never count as income or expense; including them corrupts savings rate and spending metrics. Storing dates in UTC epoch milliseconds while computing report period queries against the user's local timezone midnight boundaries eliminates date-shift edge cases. Bounding mathematical formulas (such as clamping savings rate to zero when income is non-positive) prevents NaN/infinity UI rendering exceptions.

