# Persistence Engine: Drift (Type-Safe SQLite)

We decided to use Drift (SQLite with Dart code generation) as the local persistence engine for the offline-first application, rejecting raw `sqflite` and NoSQL alternatives (Hive, Isar).

Financial applications require strict relational integrity (foreign keys with cascade/restrict rules), atomic multi-table transactions (ensuring transfers never leave partial updates), and high-performance SQL aggregation for financial reports. Drift provides compile-time verified queries, reactive streams for automated UI updates, and testable schema migrations.

