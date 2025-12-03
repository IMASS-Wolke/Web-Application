# Running the App (Local or Docker)

This guide is for a first-time setup on a fresh machine.

## Prerequisites
- Docker Desktop (needed for Postgres, FASST API, and SNTHERM job image).
- .NET 9 SDK.
- Node 20 + npm.

## Option A: Docker Compose (easiest)
1) Copy `.env.example` → `.env` and set a strong `JWT__Secret` (32+ chars). Leave Google keys empty if unused.
2) Start everything:
   ```bash
   docker compose --env-file .env up --build
   ```
3) Visit:
   - Frontend: http://localhost:3000
   - Backend Swagger: http://localhost:5103/swagger/index.html

## Option B: Local host (backend + frontend, with helper containers)
You still need Docker for Postgres + FASST + SNTHERM job image; only the app processes run on the host.

1) Start Postgres (terminal 1, keep open):
   ```bash
   docker run --rm -p 5432:5432 -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=imass postgres:16-alpine
   ```
2) Start FASST API (terminal 2, keep open):
   ```bash
   docker run --rm -p 8000:8000 seund123/fasst-api-server
   ```
3) Backend (terminal 3):
   ```powershell
   cd "C:\Users\chris\CMPS 401\Web-Application\backend"
   $env:ConnectionStrings__DefaultConnection="Host=localhost;Port=5432;Database=imass;Username=postgres;Password=postgres"
   $env:FasstApi__BaseUrl="http://localhost:8000"
   $env:Sntherm__RunsRoot="C:\SnthermRuns"      # any writable path
   $env:Sntherm__Image="ethancxyz/sntherm-job:1.0.0"
   $env:Sntherm__VolumeName="sntherm-runs"
   $env:JWT__Secret="<your 32+ char secret>"
   $env:JWT__ValidIssuer="http://localhost:5103"
   $env:JWT__ValidAudience="http://localhost:5103"
   dotnet run --urls http://localhost:5103
   ```
   Notes:
   - Backend auto-applies migrations and seeds an admin user on first run.
   - Keep Docker Desktop running so SNTHERM jobs can launch `ethancxyz/sntherm-job:1.0.0`.
4) Frontend (terminal 4):
   ```powershell
   cd "C:\Users\chris\CMPS 401\Web-Application\frontend"
   npm install
   $env:REACT_APP_API_BASE_URL="http://localhost:5103"
   $env:REACT_APP_HUB_BASE_URL="http://localhost:5103"
   npm start
   ```
   Opens http://localhost:3000.

## Troubleshooting
- Port in use (5103/3000): stop the process using it or change ports (set `ASPNETCORE_URLS` and matching `REACT_APP_*` vars).
- FASST downloads not working: ensure the FASST API container is running and `FasstApi__BaseUrl` matches.
- SNTHERM outputs missing: verify `Sntherm__RunsRoot` is writable and Docker Desktop is running (the backend launches a container to produce outputs).
