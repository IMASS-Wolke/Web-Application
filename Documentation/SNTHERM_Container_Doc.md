# SNTHERM Container Handoff (batch runner)

Containerized build/run pipeline for the SNTHERM binary used by the backend. The image builds SNTHERM from Fortran sources, packages defaults, and exposes a simple entrypoint that runs the model in `/work`.

## What’s in this folder
- `Dockerfile.txt`: multi-stage build (Ubuntu 24.04) that compiles SNTHERM from `sntherm-src/`, installs the Fortran runtime, copies the binary to `/usr/local/bin/sntherm`, copies default inputs to `/defaults/`, and sets `/run-sntherm.sh` as the entrypoint.
- `howtorun.txt`: example build/run commands (single-run and persistent container modes).
- `sntherm-src/`: Fortran source and default input files; required for the build stage and used as defaults copied into `/work`.

## Build
```
docker build -t sntherm-job:1.0.0 -f Dockerfile.txt .
```

## Run modes
- **Single run (ephemeral, defaults):**
  ```
  docker run --rm sntherm-job:1.0.0
  ```
  Copies defaults from `/defaults` into `/work` (if missing) and runs `sntherm`.

- **Single run with host inputs/outputs:**
  ```
  docker run --rm -v "%cd%/data:/work" sntherm-job:1.0.0
  ```
  Mount a host `data` directory containing `TEST.IN` and `METSWE.IN` (or your inputs); outputs stay on the host volume.

- **Persistent container (matches backend exec pattern):**
  ```
  docker run -d --name sntherm-container --entrypoint tail -v %cd%/data:/work sntherm-job:1.0.0 -f /dev/null
  docker exec sntherm-container /run-sntherm.sh
  docker stop sntherm-container && docker rm sntherm-container
  ```
  The backend’s `SnthermRunner`/`SnthermTest` uses this style: start a long-lived container with `/work` bound to a temp dir, exec `/run-sntherm.sh`, then clean up.

## Files produced
The backend copies these from the container workdir to `Sntherm:RunsRoot/{runId}/results` and returns them to clients:
- `brock.out`
- `brock.flux`
- `filt.out`

## Integration points with the ASP.NET backend
- Config keys (see `backend/appsettings.*.json`):
  - `Sntherm:Image` (default `ethancxyz/sntherm-job:1.0.0`) — set to your built image/tag if different.
  - `Sntherm:RunsRoot` — host path where outputs are persisted (default `C:\SnthermRuns` in dev settings).
- Code paths:
  - `SnthermModel/SnthermTest.cs` and `SnthermRunner.cs` prepare `/work` (write inputs), exec `/run-sntherm.sh` in the container, and collect outputs.
  - `Controllers/SnthermJobController` exposes `POST /api/SnthermJob/run` (multipart `test_in`, `metswe_in`) and `GET /api/SnthermJob/runs/{runId}/zip` for downloads.
- Docker must be running on the host where the backend runs; the image must be pullable (or built locally) under the configured tag.

## Operational notes
- The Dockerfile normalizes line endings before build; keep sources in `sntherm-src/` with Unix-friendly endings.
- For production, pin the image tag and publish to a registry the backend can reach; update `Sntherm:Image` accordingly.
- If outputs grow, prune `Sntherm:RunsRoot` periodically; containers are already removed after runs.
- The entrypoint copies defaults only when missing; mounted `/work` contents are never overwritten.
