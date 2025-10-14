import React, { useState } from "react";
import "./ModelRunner.css";
import downloadLogo from "../../../assets/icons/download.svg";

function ModelRunner() {
  const [model, setModel] = useState("SNTHERM");
  const [label, setLabel] = useState("");
  const [testIn, setTestIn] = useState(null);
  const [metSweIn, setMetSweIn] = useState(null);
  const [status, setStatus] = useState("");
  const [result, setResult] = useState(null);
  const [outputs, setOutputs] = useState([]);

  // Run SNTHERM
  const runSntherm = async () => {
    if (!testIn || !metSweIn) {
      setStatus("Please select both input files for SNTHERM.");
      return;
    }

    const formData = new FormData();
    formData.append("TestIn", testIn);
    formData.append("MetSweIn", metSweIn);
    if (label) formData.append("Label", label);

    setStatus("Running SNTHERM...");
    setResult(null);

    try {
      const res = await fetch("http://localhost:5103/api/SnthermJob/run", {
        method: "POST",
        body: formData,
      });
      const data = await res.json();
      setResult(data);
      setStatus(`SNTHERM run complete (Exit code: ${data.exitCode})`);
    } catch (err) {
      setStatus("Error: " + err.message);
    }
  };

  // Run FASST
  const runFasst = async () => {
    setStatus("Running FASST model...");
    setResult(null);

    try {
      const res = await fetch("http://localhost:5103/api/FasstIntegration/run", {
        method: "POST",
      });
      if (!res.ok) throw new Error("Failed to start FASST model");
      const data = await res.json();
      setResult(data);
      setStatus("FASST run complete.");
    } catch (err) {
      setStatus("Error: " + err.message);
    }
  };

  // Fetch FASST outputs
  const fetchFasstOutputs = async () => {
    try {
      const res = await fetch("http://localhost:5103/api/FasstIntegration/outputs");
      const data = await res.json();
      setOutputs(data);
    } catch (err) {
      setStatus("Error loading FASST outputs.");
    }
  };

  // Download SNTHERM ZIP
  const downloadSnthermZip = async () => {
    if (!result?.runId) return;
    const response = await fetch(`http://localhost:5103/api/SnthermJob/runs/${result.runId}/zip`);
    const blob = await response.blob();
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `${result.runId}_results.zip`;
    a.click();
  };

  // Download FASST Output File
  const downloadFasstFile = async (filename) => {
    const res = await fetch(`http://localhost:5103/api/FasstIntegration/outputs/${filename}/stream`);
    const blob = await res.blob();
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = filename;
    a.click();
  };

  // Unified Handler
  const handleRun = async (e) => {
    e.preventDefault();
    if (model === "SNTHERM") {
      await runSntherm();
    } else {
      await runFasst();
    }
  };

  return (
    <div className="upload-container">
      <div className="input-group">
        <label className="model-selector-title">Select Model:</label>
        <select className="model-selector" value={model} onChange={(e) => setModel(e.target.value)}>
          <option value="SNTHERM">SNTHERM</option>
          <option value="FASST">FASST</option>
        </select>
        <button className="model-submit-button" onClick={handleRun}>Run {model}</button>
      </div>

      {model === "SNTHERM" && (
        <>
          <div className="input-group">
            <label>Label (optional):</label>
            <input
              type="text"
              value={label}
              onChange={(e) => setLabel(e.target.value)}
              placeholder="job label"
            />
          </div>
          <div className="input-group">
            <label>TEST.IN file:</label>
            <input type="file" onChange={(e) => setTestIn(e.target.files[0])} />
          </div>
          <div className="input-group">
            <label>METSWE.IN file:</label>
            <input type="file" onChange={(e) => setMetSweIn(e.target.files[0])} />
          </div>
        </>
      )}
      <div className="upload-status-container">
        <p className="upload-status">{status}</p>
      </div>

      {/* SNTHERM Results */}
      {model === "SNTHERM" && result && (
        <div className="results">
          <h3>SNTHERM Results</h3>
          <p><strong>Run ID:</strong> {result.runId}</p>
          <p><strong>Exit Code:</strong> {result.exitCode}</p>
          <button onClick={downloadSnthermZip}>Download ZIP</button>

          <h4>Output Files:</h4>
          <ul>
            {result.outputs?.map((f) => (
              <li key={f}>{f}</li>
            ))}
          </ul>
        </div>
      )}

      {/* FASST Results */}
      {model === "FASST" && (
        <div className="results">
          <text>Fasst Output File(s)</text>
          <button className="refresh-outputs-button" onClick={fetchFasstOutputs}>Refresh Outputs</button>
          <ul>
            {outputs.map((f) => (
              <li className="files" key={f}>
                {f} <button className="download-logo-button" onClick={() => downloadFasstFile(f)}>
                  <img className="download-logo" src={downloadLogo} alt="Download Logo" />
                </button>
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}

export default ModelRunner;
