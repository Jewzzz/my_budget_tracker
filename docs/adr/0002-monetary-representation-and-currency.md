# Monetary Representation and Single Primary Currency

We decided to store all monetary amounts as integer minor units (e.g., cents, where \$10.50 is 1050) encapsulated in a domain `Money` Value Object, and restrict the application scope to a single user-configured primary currency.

Floating-point numbers (`double`) introduce precision drift and rounding errors inherent to IEEE 754 representations, causing balance inconsistencies in financial sums. Integer minor units ensure 100% exact arithmetic in code and database aggregations. Restricting to a single primary currency avoids offline exchange-rate synchronization issues while keeping financial calculations deterministic.

