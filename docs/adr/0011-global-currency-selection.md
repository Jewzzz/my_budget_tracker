# Global Primary Currency Selection and Display Formatting

We decided to store the user's selected Primary Currency in a Drift `AppSettings` key-value table (managed via `SettingsCubit`), map supported currencies through a centralized catalog with explicit symbols and space-separated formatting (`$ 25,000.00`, `Rs 25,000.00`), and preserve uniform 2-decimal display precision across all currencies without converting stored minor units.

Reusing Drift avoids introducing a separate preferences package (`ADR-0005`), provides reactive persistence, and allows optional backward-compatible inclusion in JSON backups. Explicitly formatting `Currency` symbols rather than relying on `intl`'s `NumberFormat.simpleCurrency` prevents undesired code fallbacks (such as `LKR` instead of `Rs`) and avoids silent rounding of fractional minor units on zero-decimal currencies like `JPY`, while Unicode directional isolation (`\u2066...\u2069`) keeps RTL symbols like `د.إ` aligned with LTR signs and digits.
