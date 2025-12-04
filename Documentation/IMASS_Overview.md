# IMASS Web App Overview

Guide for running and extending IMASS locally. The app runs directly on your machine; only the model runtimes rely on Docker/FASST (SNTHERM image pulled by the backend; FASST API is ran separately).

## Stack and Layout
- **Backend:** ASP.NET Core 9 Web API, EF Core (PostgreSQL), Identity + JWT auth, SignalR, Docker.DotNet (launches SNTHERM jobs in a container).
- **Frontend:** React (Create React App) with React Router, React Flow, Recharts, react-dropzone, SignalR client.
- **External:** PostgreSQL, FASST API (FastAPI, typically `http://localhost:8000`), Docker Engine required for SNTHERM runs.

Repo directories:
- `backend/` API, data models, migrations, Sntherm job runner.
- `frontend/` React app (pages, model runners, charts).
- `Documentation/` project docs (this file and other notes).

## Data Model
- **ApplicationUser** extends IdentityUser with `Name`, optional `GoogleSub` (unique).
- **TokenInfo** stores refresh tokens (`Username`, `RefreshToken`, `ExpiredAt`).
- **Model** <-> **Job** one-to-many (join table `JobModels`), `Status` tracks run state.
- **Scenario** -> **Chain** -> **Job** hierarchy (Scenario has many Chains, Chain has many Jobs).
- **Scenario** is the blueprint, **Chain** is a singular run/instance of a Scenario, **Job** is a singular run/instance of a Model
- **SnthermRunResult** persists SNTHERM run metadata and output file paths.

## Backend Overview (port 5103)
- `Program.cs` wires services, CORS (localhost 5173/4200/3000), Identity, JWT bearer, Google auth, Swagger, SignalR hub `/hubs/health`, hosted health publisher, and seeds an admin if no users.
- **AccountsController (`/api/Accounts`)**: signup, login (JWT + refresh token in `TokenInfo`), refresh/revoke, Google login, `/me` to inspect claims. Seeded admin: `admin@example.com` / `Admin@123` (only created when DB has no users).
- **Scenario/Chain/Job/Model controllers**: CRUD for scenarios, chains, jobs, models; assign models to jobs.
- **ScenarioBuilderController**: orchestration endpoints that can create scenario/chain/job and run a model in one call.
- **SnthermJobController**: runs SNTHERM via Docker image `ethancxyz/sntherm-job:1.0.0`, stores results, lists runs, and serves a zip of outputs.
- **FasstIntegrationController**: proxies to the external FASST API (`FasstApi:BaseUrl`) for run, outputs listing, and downloads.
- **Services**: `IModelRunner` (SNTHERM/FASST routing), `IScenarioBuilder`, `IFasstApiService`, `FasstHealthPublisherService` (polls FASST and publishes SignalR health).
- **SnthermModel**: `SnthermTest.RunAsync` writes inputs to a temp workdir, pulls/runs the SNTHERM Docker image, collects `brock.out`, `brock.flux`, `filt.out`, and saves them to `Sntherm:RunsRoot` (default `C:\SnthermRuns`).

## Frontend Overview (port 3000)
- `Navbar` routes to Home, Models, Scene Builder; login/sign-up links always visible.
- `Login` / `Signup` call `/api/Accounts/login` and `/api/Accounts/signup`; tokens go to `localStorage` (no auto-refresh yet).
- `ModelRunner` toggles between:
  - **SnthermRunner**: dropzones for `TEST.IN` and `METSWE.IN`, posts to `/api/SnthermJob/run`, shows run ID, exit code, outputs, and zip download.
  - **FasstRunner**: uploads one input file to `/api/FasstIntegration/run`, lists outputs, downloads files, and charts common outputs (`fasst.out`, `ground.out`, `fluxes.out`, `veg_temp.out`, `snow_info.out`). Includes a SignalR health panel.
- `SceneBuilder` uses React Flow as a simple graphing scaffold (start -> SNTHERM -> FASST -> end).
- `Outputs/Fasst-outputs` shows a chart from static sample data; `Upload` is a UI-only dropzone example.
- `Health Checker/HealthPanel` connects to `/hubs/health` for FASST health updates.

## Configuration (local)
Set these in `backend/appsettings.Development.json` or as environment variables:

| Setting | Purpose |
| --- | --- |
| `ConnectionStrings:DefaultConnection` | PostgreSQL connection string. |
| `JWT:ValidIssuer`, `JWT:ValidAudience`, `JWT:Secret` | JWT validation and signing key (Secret must be strong/32+ chars). |
| `Google:ClientId`, `Google:ClientSecret` | Needed for Google login; leave blank to disable. |
| `Sntherm:RunsRoot`, `Sntherm:Image` | Where SNTHERM writes outputs and which Docker image to run. |
| `FasstApi:BaseUrl` | URL for the external FASST API used by run/output endpoints (default `http://localhost:8000`). |
| `Fasst:BaseUrl`, `Fasst:HealthPath` | Base URL/path used by the health poller that feeds SignalR (defaults: `http://localhost:8000`, `/`). |
| `Cors:AllowedOrigins` | CORS origins; code currently allows localhost:5173/4200/3000. |

Frontend:
- CRA env vars must start with `REACT_APP_`; the Google OAuth provider currently reads `process.env.CLIENT_ID`. Export `CLIENT_ID` (or align to `REACT_APP_CLIENT_ID`) before `npm start` if you need Google sign-in.
- API base URLs are hard-coded to `http://localhost:5103` in components; update if you change backend ports.

## Prerequisites
- .NET 9 SDK.
- Node.js 18.x + npm.
- PostgreSQL 15+ running locally and reachable via `DefaultConnection`.
- Docker Desktop/Engine running (required for SNTHERM jobs; backend pulls `ethancxyz/sntherm-job:1.0.0`).
- Optional: a running FASST API at `http://localhost:8000` (start your FastAPI service locally or run the public image if you prefer).

## First-Time Local Setup (local run)
1) **Clone**: `git clone` then `cd Web-Application`.
2) **Configure backend**:
   - Open `backend/backend.sln` in your IDE if you prefer a GUI, set `ConnectionStrings:DefaultConnection` in `backend/appsettings.json` (or the .Development version), then run with `dotnet run` or the IDE’s run profile.
   - From CLI, keep using steps below.
3) **Provision database**:  
   `dotnet ef database update --project backend/IMASS.csproj --startup-project backend`
4) **Run backend** (Docker must be running for SNTHERM):  
   `dotnet run --project backend/IMASS.csproj --urls http://localhost:5103`
5) **Run frontend** (first clone setup):  
   ```
   cd frontend
   npm install
   npm install react-router-dom
   npm install @microsoft/signalr
   npm install react-dropzone
   npm install reactflow
   npm install jszip
   npm install recharts
   npm install @react-oauth/google@latest
   npm install --save-dev ajv@^7    # fixes “Cannot find module 'ajv/dist/compile/codegen'”
   npm run convert:fasst            # build JSON from fasst.out before start
   npm run start
   ```
   CRA opens `http://localhost:3000`. Export `CLIENT_ID` if using Google login. On subsequent runs, usually just `cd frontend && npm run start` is enough.
6) **Verify**: browse `http://localhost:5103/swagger/index.html`; log in via UI or Swagger with `admin@example.com` / `Admin@123` (seeded only when DB has no users).

## Common Workflows
- **Run SNTHERM (UI)**: Models -> SNTHERM, drop `TEST.IN` and `METSWE.IN`, run, then download the zip. Outputs land under `Sntherm:RunsRoot`.
- **Run SNTHERM (cURL)**:  
  ```
  curl -F "test_in=@./TEST.IN" -F "metswe_in=@./METSWE.IN" http://localhost:5103/api/SnthermJob/run
  ```
  Then `GET /api/SnthermJob/runs/{runId}/zip` to download results.
- **Run FASST**: Models -> FASST, choose one input file, Run, then Refresh Outputs. Download files or view charts for known outputs.
- **Scenario builder APIs**: create scenario (`POST /api/ScenarioBuilder/create-scenario`), then `POST /api/ScenarioBuilder/create-job-and-run` with `model_name`, `scenario_id`, `chain_id`, `inputFile1`, `inputFile2`; or use `POST /api/ScenarioBuilder/run` to create and run in one step.
- **Auth tokens**: `login` returns `accessToken` (15 min) and `refreshToken` (7 days). Store both; refresh via `POST /api/Accounts/token/refresh` with expired access token + refresh token.

## Troubleshooting
- **DB connection errors**: verify `DefaultConnection`, ensure DB exists, rerun `dotnet ef database update`.
- **SNTHERM failures**: confirm Docker is running and `ethancxyz/sntherm-job:1.0.0` can be pulled; ensure `Sntherm:RunsRoot` is writable.
- **FASST unavailable**: start the FASST API and check `FasstApi:BaseUrl`; HealthPanel shows status from SignalR.
- **CORS issues**: adjust allowed origins in `Program.cs` or config if you change frontend port.
- **Google login**: needs valid OAuth client ID/secret and authorized redirect (`/signin-google` on backend port).

## Hand-off Notes

- Unify naming conventions properly: Bad leftovers like:`/api/SnthermJob/run` and `/api/FasstIntegration/run`
- **Model** <-> **Job** is a many-to-many still even tough it SHOULD be a one-to-many (1 model -> many Jobs | 1 Job -> only 1 model)
- Default admin credentials are for development only; rotate or remove for production.
- Frontend API URLs are hard-coded; centralizing via env vars would be a good follow-up.
- There's is a branch called "containerized-web-app" that contains the a version of the web-application that is fully containerized and working

## Potential Next things to do

- Implement kubernetes + Terraform (smart job management)
- Add new model support + automatic integration
- integrate data visualization/charts for any output type
- Account Linked Job History, Chain History, Scene blueprints, etc.
