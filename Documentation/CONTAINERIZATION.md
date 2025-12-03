# Containerization Guide

This project ships with Docker/Compose so it can be run locally without manual installs. Everything runs as containers: Postgres, backend (ASP.NET 9), frontend (CRA + nginx), FASST API, and SNTHERM jobs.

## Prerequisites
- Docker Desktop (or Docker Engine) with Compose v2.
- Access to the host Docker socket is required for SNTHERM jobs (compose mounts `/var/run/docker.sock` into the backend).

## Environment
Copy `.env.example` to `.env` and set values:

| Key | Purpose |
| --- | --- |
| `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` | Database credentials (must match the connection string). |
| `ConnectionStrings__DefaultConnection` | EF Core connection string to Postgres (defaults use the vars above). |
| `JWT__ValidIssuer`, `JWT__ValidAudience`, `JWT__Secret` | JWT auth settings; set `JWT__Secret` to a strong 32+ char random string. |
| `Google__ClientId`, `Google__ClientSecret` | Optional; leave blank to disable Google OAuth. |
| `FasstApi__BaseUrl`, `FasstApi__HealthPath` | Backend->FASST API target (defaults to `http://fasst:8000`). |
| `Sntherm__RunsRoot`, `Sntherm__Image`, `Sntherm__VolumeName` | SNTHERM working path inside backend, job image, shared volume name. |
| `Cors__AllowedOrigins__*` | CORS origins for the frontend. |
| `REACT_APP_API_BASE_URL`, `REACT_APP_HUB_BASE_URL` | Frontend runtime API/hub endpoints (use host URLs, e.g., `http://localhost:5103`). |

## Services (docker-compose.yml)
- **db**: Postgres 16 (volume `pgdata`).
- **backend**: ASP.NET 9 API on port 5103, talks to Postgres, FASST, and launches SNTHERM jobs (needs Docker socket).
- **frontend**: React build served by nginx on port 3000.
- **fasst**: Uses image `seund123/fasst-api-server` on port 8000.
- **sntherm**: Not a service; jobs are launched by backend using image `ethancxyz/sntherm-job:1.0.0` and volume `sntherm-runs`.

Volumes:
- `pgdata` for Postgres data.
- `sntherm-runs` for SNTHERM inputs/outputs; wipe with `docker volume rm sntherm-runs` if you need a clean slate.

## Run
```bash
docker compose --env-file .env up --build
```
URLs:
- Frontend: http://localhost:3000
- Backend Swagger: http://localhost:5103/swagger/index.html

## Common notes
- Google OAuth is optional; if `Google__ClientId/Secret` are empty, the handler is skipped.
- Backend CORS origins come from `Cors:AllowedOrigins`.
- SNTHERM outputs are limited to `brock.out`, `brock.flux`, `filt.out`.
- FASST downloads proxy to the `/outputs/{file}` endpoint of the FASST API container.

## Dockerfiles (brief)
- **backend/Dockerfile**: .NET 9 multi-stage; restores/publishes API and runs on port 5103 with `ASPNETCORE_URLS=http://+:5103`.
- **frontend/Dockerfile**: Node 20 build stage (`npm ci && npm run build`), then nginx serving `/usr/share/nginx/html` with `nginx.conf`; exposed on port 80 (mapped to 3000).
- **FASST**: No local Dockerfile used; Compose pulls `seund123/fasst-api-server` (listens on 8000).
- **SNTHERM**: No Dockerfile here; backend pulls `ethancxyz/sntherm-job:1.0.0` when running jobs via Docker socket.
