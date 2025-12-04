# IMASS Backend (ASP.NET Core)

Backend notes for the team taking over next year. This covers what the API does, how to run it, and where to change configuration.

## What the backend does
- ASP.NET Core 9 Web API that issues JWTs (Identity + EF Core + PostgreSQL) and exposes CRUD for scenarios, chains, jobs, and models.
- Runs scientific models: SNTHERM through a Docker image (`ethancxyz/sntherm-job:1.0.0`) and FASST by proxying to an external FastAPI service (`FasstApi:BaseUrl`, default `http://localhost:8000`).
- Orchestrates model runs (create scenario/chain/job + execute) and persists run metadata under `SnthermRunResults`.
- Publishes FASST health status over SignalR (`/hubs/health`) via a background service so the React client can show live status.

## Prerequisites
- .NET 9 SDK
- PostgreSQL reachable with the connection string in `backend/appsettings*.json`
- Docker Desktop/Engine running (required for SNTHERM runs)
- Optional: FASST API running at the URL configured in `FasstApi:BaseUrl`

## Local run checklist
1) Configure `backend/appsettings.Development.json` (copy secrets from your secret store, do not commit real values):
   - `ConnectionStrings:DefaultConnection`
   - `JWT:ValidIssuer`, `JWT:ValidAudience`, `JWT:Secret` (32+ chars)
   - `Google:ClientId`, `Google:ClientSecret` (leave blank to disable)
   - `Sntherm:Image`, `Sntherm:RunsRoot` (default `C:\SnthermRuns`)
   - `FasstApi:BaseUrl` and `Fasst:BaseUrl`/`Fasst:HealthPath` for health polling
2) Apply migrations: `dotnet ef database update --project backend/IMASS.csproj --startup-project backend`
3) Run: `dotnet run --project backend/IMASS.csproj --urls http://localhost:5103`
4) Verify: open Swagger at `http://localhost:5103/swagger/index.html`

## Configuration map (appsettings)
- `ConnectionStrings:DefaultConnection`: PostgreSQL connection string.
- `JWT:*`: issuer/audience/secret used by JWT bearer auth.
- `Google:*`: OAuth client for Google sign-in; backend callback is `/signin-google`.
- `Sntherm:Image`, `Sntherm:RunsRoot`: Docker image tag and output root for SNTHERM runs.
- `FasstApi:BaseUrl`: FastAPI host used by `/api/FasstIntegration`.
- `Fasst:BaseUrl`, `Fasst:HealthPath`: host/path polled by the health publisher that feeds SignalR clients.
- CORS origins are hard-coded in `backend/Program.cs` (localhost:5173/4200/3000); adjust there if frontend host changes.

## Data model and migrations
- Identity tables plus:
  - `TokenInfo` (username, refresh token, expiry)
  - `Models`, `Jobs`, join table `JobModels`
  - `Scenarios` -> `Chains` -> `Jobs` (one-to-many each)
  - `SnthermRunResults` for SNTHERM outputs metadata
- `DbSeeder` (`backend/Data/DbSeeder.cs`) applies pending migrations on startup and, if no users exist, creates an admin user `admin@example.com` / `Admin@123` and an `Admin` role. Change or disable this for production.
- `ApplicationUser.GoogleSub` has a unique index (see migrations) to prevent multiple accounts per Google subject.

## Auth flow (AccountsController)
- `POST /api/Accounts/signup`: create user, assign `User` role.
- `POST /api/Accounts/login`: returns `{ accessToken, refreshToken }` (access expires in 15 minutes; refresh stored in `TokenInfo` for 7 days).
- `POST /api/Accounts/token/refresh`: requires expired access token + refresh token; rotates refresh token.
- `POST /api/Accounts/token/revoke`: clears refresh token for the caller (requires auth).
- `POST /api/Accounts/google`: validates Google ID token against configured `Google:ClientId`, issues JWT/refresh, links `GoogleSub`.
- `GET /api/Accounts/me`: echoes caller claims; useful for debugging auth.

## API surface (by controller)
- Accounts: auth endpoints above.
- User: `GET /api/User` lists users and roles (currently `[AllowAnonymous]` for convenience).
- Scenario: `GET /api/Scenario`, `POST /api/Scenario`, `DELETE /api/Scenario/{id}`.
- Chain: `GET /api/Chain`, `GET /api/Chain/scenarioId/{scenarioId}`, `POST /api/Chain/scenario/{scenarioId}`, `DELETE /api/Chain/{id}`.
- Job: `GET /api/Job`, `GET /api/Job/chainId/{chainId}`, `POST /api/Job`, `POST /api/Job/chainId/{chainId}`, `POST /api/Job/{jobId}/assign-model/{modelId}`, `DELETE /api/Job/{id}`.
- Model: `GET /api/Model`, `POST /api/Model`, `DELETE /api/Model/{id}`.
- ScenarioBuilder: orchestrated runs.
  - `POST /api/ScenarioBuilder/run` (multipart): optional `model_name`/`scenario_name`, `inputFile1` (required), `inputFile2` (optional). Creates scenario/chain/job if needed and runs the requested model.
  - `POST /api/ScenarioBuilder/create-scenario`: creates scenario + default chain.
  - `POST /api/ScenarioBuilder/create-job-and-run`: supply `model_name`, `scenario_id`, `chain_id`, `inputFile1` (required), `inputFile2` (optional); creates job and runs.
- SnthermJob:
  - `POST /api/SnthermJob/run` (multipart): `test_in`, `metswe_in`, optional `label`. Runs SNTHERM Docker image, persists `SnthermRunResults`, returns run id and outputs list.
  - `GET /api/SnthermJob/runs`: last 20 runs.
  - `GET /api/SnthermJob/runs/{runId}/zip`: streams a zip of run outputs.
- FasstIntegration:
  - `POST /api/FasstIntegration/run` (multipart `file`): forwards to FastAPI `/run-fasst`.
  - `GET /api/FasstIntegration/outputs`: list files from FastAPI `/outputs`.
  - `GET /api/FasstIntegration/outputs/{filename}`: fetch file contents as text.
  - `GET /api/FasstIntegration/outputs/{filename}/stream`: streams/downloads file from FastAPI `/outputs/{filename}/download`.
  - `POST /api/FasstIntegration/run-coupled`: multipart `fasstFile` + `snthermFile` routed to FastAPI `/run-coupled/`.

## Model execution internals
- SNTHERM (`backend/SnthermModel/SnthermTest.cs`, used by `ModelRunner`):
  - Writes inputs to a temp work dir, binds it into the SNTHERM Docker container, runs, copies `brock.out`, `brock.flux`, `filt.out` to `Sntherm:RunsRoot/{runId}/results`, and cleans up the container/temp dir.
  - `Sntherm:RunsRoot` must be writable; default `C:\SnthermRuns`.
- FASST (`backend/Services/FasstApiService.cs`): plain HTTP client to the FastAPI host; 5s timeout configured in `Program.cs` via named client `FasstHealth`.
- `ModelRunner` routes by `modelName` (`sntherm`/`sn` -> SNTHERM, `fasst` -> FastAPI).
- `ScenarioBuilder` composes scenario + chain + job creation and then calls `ModelRunner`; updates model `Status` to Completed/Failed for SNTHERM runs.

## Background services and messaging
- `FasstHealthPublisherService` polls `Fasst:BaseUrl` + `Fasst:HealthPath` every 5 seconds and broadcasts a health payload on SignalR hub `/hubs/health`. Frontend health panel listens for `healthUpdate`.
- Hub is registered in `backend/Program.cs` via `app.MapHub<HealthHub>("/hubs/health")`.

