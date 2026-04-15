# ICT-114 EducGame

This repository is split into two parts:

- `frontend/` contains the Unity client.
- `backend/` contains the Node.js and Prisma service that stores player progress, threat scenarios, save slots, and security reports.

## Backend quick start

1. Start PostgreSQL with `docker compose up -d`.
2. Copy `backend/.env.example` to `backend/.env`.
3. In `backend/`, run `npm install`.
4. Run `npm run prisma:generate`.
5. Run `npm run prisma:migrate -- --name init`.
6. Run `npm run prisma:seed`.
7. Run `npm run dev`.

## Unity frontend

The existing Unity project now lives in `frontend/`. Open that folder in Unity Hub to continue client-side development.

## Initial API surface

- `GET /api/health`
- `POST /api/players`
- `GET /api/players/:playerId/save-slots`
- `POST /api/players/:playerId/save-slots`
- `GET /api/save-slots/:saveSlotId`
- `GET /api/scenarios/random`
- `POST /api/attempts`
- `POST /api/reports`