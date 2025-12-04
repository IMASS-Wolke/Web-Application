# FASST Container (FastAPI wrapper)

FastAPI microservice that wraps the compiled FASST binary. The .NET backend calls it through `FasstIntegrationController` to run FASST jobs and fetch outputs.

## What’s here
- `app.py`: FastAPI app that runs `./FASST <input>` and serves outputs.
- `Dockerfile (1).txt`: Ubuntu 22.04 base; installs Python + gfortran runtime, copies `fasst/` (binary + data) and `app.py`, installs requirements, starts Uvicorn on port 8000. Rename to `Dockerfile` when building.
- `requirements.txt`: `fastapi`, `uvicorn[standard]`, `python-multipart`.
- `README.md`: high-level overview of the SNTHERM→FASST coupling workflow and required inputs.
- `fasst/`: must contain the compiled `FASST` binary and any dependency files (e.g., `gr1_zip.inp` and the companion inputs it references).

## Build and run
1) Ensure `fasst/` contains the `FASST` executable and required inputs.
2) Build (rename the Dockerfile if needed):
   ```
   docker build -t fasst-api -f Dockerfile (1).txt .
   ```
3) Run (mount to keep outputs on host):
   ```
   docker run --rm -p 8000:8000 -v "%cd%/fasst:/app/fasst" fasst-api
   ```
   - Service listens on `0.0.0.0:8000`.
   - Outputs land in `/app/fasst`; the bind mount preserves them.

## API surface 
- `POST /run-fasst/` (multipart form): field `file` is the FASST input. Returns `{ stdout, stderr, outputs[] }`. This is what the React UI calls via the .NET proxy `/api/FasstIntegration/run`.
- `GET /outputs/`: returns `{ files: [...] }` (the .NET client tolerates either an array or this object).
- `GET /outputs/{filename}`: returns file content as text.
- `GET /outputs/{filename}/json`: best-effort tabular parse into JSON (header detection is heuristic).
- `GET /outputs/{filename}/download`: binary download; the React UI uses this via `/api/FasstIntegration/outputs/{filename}/stream`.

Known outputs checked in `app.py`: `fasst.out`, `ground.out`, `fluxes.out`, `veg_temp.out`, `snow_info.out`.

## Notes and behavior
- Uploaded filename is sanitized (`os.path.basename`) and deleted after the run; outputs remain in place.
- Stdout/stderr from the FASST run are returned in the response only.
- No health endpoint; the .NET health poller currently hits the base URL (`/`) and treats non-5xx as reachable.
- Coupled run: the .NET backend exposes `POST /api/FasstIntegration/run-coupled` expecting a FastAPI route `/run-coupled/` that accepts `fasst_file` + `sntherm_file`. This is **not implemented** in `app.py`; add it if you want the coupled endpoint to work end-to-end.

## Example cURL
```
# Run a job
curl -X POST http://localhost:8000/run-fasst/ \
  -F "file=@./gr1_zip.inp"

# List outputs
curl http://localhost:8000/outputs/

# Download one output
curl -O http://localhost:8000/outputs/fasst.out
```
