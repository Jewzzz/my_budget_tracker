# State Management: Flutter Bloc with Feature-Driven Clean Architecture

We decided to use `flutter_bloc` (Bloc and Cubit) as the presentation-layer state management solution, structured according to Feature-Driven Clean Architecture (`lib/features/<feature>/{domain, data, presentation}`).

Bloc enforces strict unidirectional data flow and immutable state transitions, separating presentation widgets entirely from business logic. Pure Dart Use Cases and Blocs enable isolated, deterministic unit testing via `bloc_test` without widget tree dependencies. The feature-driven package layout organizes the codebase around cohesive business capabilities (accounts, transactions, budgets, savings goals, reports) rather than technical layers.

