# Security and Offline Backup Strategy

We decided to protect the application with optional on-device Biometric/PIN authentication (via `local_auth` and Android Keystore) and provide user-controlled file-based database backup/restore and CSV export, rather than a remote cloud synchronization backend.

An offline-first personal finance app requires robust data privacy to protect sensitive financial records on physical devices, and an explicit disaster recovery mechanism to prevent permanent data loss upon device upgrades or uninstalls. User-controlled backup snapshots and CSV exports maintain 100% data sovereignty, work completely offline, and require zero cloud server infrastructure or recurring maintenance costs.

