# Backend Overview

The backend implements the persistence layer implied by the DFD:

- onboarding creates `Player` records
- progress tracking uses `SaveSlot`
- threat generation reads `ThreatScenario`, `ThreatChoice`, and `EventPool`
- trust token and cyber status processing write to ledger tables
- report generation writes `SecurityReport`

The authoritative schema lives in `prisma/schema.prisma`. Seeded scenario content lives in `prisma/seed-data/threat-scenarios.json`.