from flask import Flask, jsonify
import subprocess
import os

app = Flask(__name__)

SNTHERM_BIN = "/app/sntherm"   # Path inside container
SNTHERM_WORKDIR = "/app/workdir"

# Ensure workdir exists
os.makedirs(SNTHERM_WORKDIR, exist_ok=True)

# Health check
@app.route("/", methods=["GET"])
def index():
    return {"status": "SNTHERM service running"}

# Run SNTHERM
@app.route("/run", methods=["GET", "POST"])
def run_sntherm():
    try:
        # List files before run
        before = os.listdir(SNTHERM_WORKDIR)

        # Run SNTHERM (reads FILENAME inside /app/workdir)
        result = subprocess.run(
            [SNTHERM_BIN],
            cwd=SNTHERM_WORKDIR,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )

        after = os.listdir(SNTHERM_WORKDIR)

        return jsonify({
            "status": "completed",
            "exit_code": result.returncode,
            "stdout": result.stdout,
            "stderr": result.stderr,
            "workdir_files_before": before,
            "workdir_files_after": after
        })
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

# Get Outputs
@app.route("/outputs", methods=["GET"])
def get_outputs():
    outputs = {}
    try:
        # Hardcoded list of expected SNTHERM outputs
        output_files = [
            "filt.out",
            "brock.out",
            "brock.flux",
            "brock.dum",
            "brock.temp"
        ]

        for filename in output_files:
            path = os.path.join(SNTHERM_WORKDIR, filename)
            if os.path.exists(path):
                with open(path, "r") as f:
                    outputs[filename] = f.read()
            else:
                outputs[filename] = None

        return jsonify(outputs)
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
