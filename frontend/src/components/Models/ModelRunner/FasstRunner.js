import { useState, useCallback, useMemo } from "react";
import "./ModelRunner.css";
import downloadLogo from "../../../assets/icons/download.svg";
import { API_BASE_URL } from "../../../config";
// Recharts
import {
  ResponsiveContainer,
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  Brush,
  ReferenceLine
} from "recharts";

import HealthPanel from "./Health Checker/HealthPanel.js";

function FasstRunner() {
  const [status, setStatus] = useState("");
  const [result, setResult] = useState(null);
  const [outputs, setOutputs] = useState([]);
  const [hasRun, setHasRun] = useState(false);
  const [selectedFile, setSelectedFile] = useState(null);
  const [isDragging, setIsDragging] = useState(false);

  // charts: { [filename]: { data: Array<Record<string,number|string>>, columns: string[] } }
  const [charts, setCharts] = useState({});

  const backendBase = `${API_BASE_URL}/api/FasstIntegration`;
  const targetFiles = useMemo(
    () => ["fasst.out", "ground.out", "fluxes.out", "veg_temp.out", "snow_info.out"],
    []
  );

  const onFileSelected = (file) => {
    if (!file) return;
    setSelectedFile(file);
    setStatus(`Selected: ${file.name}`);
    setHasRun(false);
    setResult(null);
    setOutputs([]);
    setCharts({});
  };

  const onInputChange = (e) => {
    const file = e.target.files?.[0];
    onFileSelected(file);
  };

  const onDragOver = (e) => {
    e.preventDefault();
    setIsDragging(true);
  };
  const onDragLeave = (e) => {
    e.preventDefault();
    setIsDragging(false);
  };
  const onDrop = (e) => {
    e.preventDefault();
    setIsDragging(false);
    const file = e.dataTransfer.files?.[0];
    onFileSelected(file);
  };

  const runFasst = async () => {
    if (!selectedFile) {
      setStatus("Please select an input file first.");
      return;
    }

    setStatus("Uploading and running FASST…");
    setResult(null);
    setHasRun(false);
    setCharts({});

    try {
      const form = new FormData();
      form.append("file", selectedFile, selectedFile.name);

      const res = await fetch(`${backendBase}/run`, {
        method: "POST",
        body: form,
      });

      if (!res.ok) {
        const text = await res.text();
        throw new Error(`Failed to run FASST (${res.status}): ${text}`);
      }

      const data = await res.json().catch(() => ({}));
      setResult(data || null);
      setStatus("FASST run complete.");
      setHasRun(true);

      // Pull outputs then charts
      await fetchFasstOutputs(true);
    } catch (err) {
      setStatus("Error: " + (err?.message ?? "Unknown error"));
    }
  };

  // --- parsing helpers -------------------------------------------------------
  const isNumeric = (v) => v !== "" && !Number.isNaN(Number(v));

  const parseTable = (text) => {
    // Split lines, strip comments that start with ! or #, drop empties
    const lines = text
      .split(/\r?\n/)
      .map((l) => l.trim())
      .filter((l) => l && !l.startsWith("!") && !l.startsWith("#"));

    if (lines.length === 0) return { data: [], columns: [] };

    // Try to detect header row: if first line contains any non-numeric tokens -> header
    const first = lines[0].split(/[,\s]+/).filter(Boolean);
    let columns;
    let startIdx = 0;

    const firstHasAlpha = first.some((tok) => /[A-Za-z_]/.test(tok));
    if (firstHasAlpha) {
      columns = first;
      startIdx = 1;
    } else {
      // Auto-generate names based on longest row we see
      const maxCols = Math.max(...lines.map((l) => l.split(/[,\s]+/).filter(Boolean).length));
      columns = Array.from({ length: maxCols }, (_, i) => `col${i + 1}`);
    }

    // Build records; coerce numeric-looking fields to Number
    const data = [];
    for (let i = startIdx; i < lines.length; i++) {
      const parts = lines[i].split(/[,\s]+/).filter(Boolean);
      const row = {};
      for (let c = 0; c < columns.length; c++) {
        const key = columns[c] ?? `col${c + 1}`;
        const val = parts[c] ?? "";
        row[key] = isNumeric(val) ? Number(val) : val;
      }
      data.push(row);
    }

    return { data, columns };
  };

  const fetchText = async (filename) => {
    const res = await fetch(`${backendBase}/outputs/${encodeURIComponent(filename)}`);
    if (!res.ok) throw new Error(`Failed to fetch ${filename} (${res.status})`);
    return res.text();
  };

  const buildChartsFromOutputs = useCallback(
    async (outputsList) => {
      const present = new Set(outputsList);
      const toLoad = targetFiles.filter((f) => present.has(f));
      if (toLoad.length === 0) {
        setCharts({});
        return;
      }

      const results = {};
      for (const file of toLoad) {
        try {
          const txt = await fetchText(file);
          const parsed = parseTable(txt);

          // Require at least 2 columns and some rows to chart
          if (parsed.columns.length >= 2 && parsed.data.length > 0) {
            results[file] = parsed;
          }
        } catch (e) {
          // Leave file out if fetch/parse fails
          // Optionally: console.warn(`Chart load failed for ${file}`, e);
        }
      }
      setCharts(results);
    },
    [targetFiles]
  );
  // ---------------------------------------------------------------------------

  const fetchFasstOutputs = useCallback(
    async (alsoLoadCharts = false) => {
      try {
        const res = await fetch(`${backendBase}/outputs`);
        if (!res.ok) throw new Error(`Outputs fetch failed (${res.status})`);
        const data = await res.json();
        const list = Array.isArray(data) ? data : data?.files || [];
        setOutputs(list);

        if (alsoLoadCharts) {
          await buildChartsFromOutputs(list);
          setStatus((s) => (s ? `${s} Charts updated.` : "Charts updated."));
        }
      } catch (e) {
        setStatus("Error loading FASST outputs.");
      }
    },
    [backendBase, buildChartsFromOutputs]
  );

  const downloadFasstFile = async (filename) => {
    try {
      const res = await fetch(
        `${backendBase}/outputs/${encodeURIComponent(filename)}/stream`
      );
      if (!res.ok) throw new Error(`Download failed (${res.status})`);
      const blob = await res.blob();
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = filename;
      document.body.appendChild(a);
      a.click();
      a.remove();
      window.URL.revokeObjectURL(url);
    } catch (e) {
      setStatus(`Error downloading ${filename}`);
    }
  };

  const renderChart = (file, parsed) => {
    const columns = parsed.columns;
    if (!columns || columns.length < 2) return null;

    const xKey = columns[0]; // first column as X
    const yKeys = columns.slice(1).filter((k) =>
      parsed.data.some((row) => typeof row[k] === "number")
    );

    if (yKeys.length === 0) return null;

    return (
      <div key={file} className="fasst-chart-card">
        <div className="fasst-chart-header">
          <h5 className="fasst-chart-title">{file}</h5>
        </div>
        <div className="fasst-chart-body">
          <ResponsiveContainer width="100%" height={320}>
            <LineChart data={parsed.data} margin={{ top: 10, right: 20, left: 0, bottom: 10 }}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey={xKey} />
              <YAxis />
              <Tooltip />
              {/*<Legend />*/}
              {yKeys.map((yk) => (
                <Line
                  key={yk}
                  type="monotone"
                  dataKey={yk}
                  dot={false}
                  strokeWidth={2}
                  isAnimationActive={false}
                />
              ))}
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>
    );
  };

  return (
    <div className="fasst-runner">
      {/* File chooser + dropzone */}
      <div
        className={`dropdown-input ${isDragging ? "active" : ""}`}
        onDragOver={onDragOver}
        onDragLeave={onDragLeave}
        onDrop={onDrop}
        onClick={() => document.getElementById("fasst-input").click()}
      >
        <input
          id="fasst-input"
          type="file"
          style={{ display: "none" }}
          onChange={onInputChange}
        />
        {selectedFile ? (
          <p className="file-name">Uploaded: {selectedFile.name}</p>
        ) : (
          <p>Drag & drop your FASST input file here, or click to browse.</p>
        )}
      </div>

      {/* Controls */}
      <div className="fasst-controls">
        <button className="fasst-run-button" onClick={runFasst} disabled={!selectedFile}>
          Run FASST
        </button>
        <button
          className="fasst-refresh-button"
          onClick={() => fetchFasstOutputs(true)} // <-- refresh outputs + charts
        >
          Refresh Outputs
        </button>
      </div>

      {/* Status */}
      <div className="fasst-status-container">
        <p className="fasst-status">{status}</p>
      </div>

      {/* Result summary */}
      {hasRun && (
        <div className="fasst-results">
          <h3>FASST Run Results</h3>
          {result && (
            <div className="fasst-result-grid">
              {"jobId" in (result || {}) && result.jobId && (
                <p>
                  <strong>Job ID:</strong> {result.jobId}
                </p>
              )}
              {"message" in (result || {}) && result.message && (
                <p>
                  <strong>Message:</strong> {result.message}
                </p>
              )}
              {"success" in (result || {}) && (
                <p>
                  <strong>Success:</strong> {String(result.success)}
                </p>
              )}
            </div>
          )}
        </div>
      )}

      {/* Outputs list */}
      {(hasRun || outputs.length > 0) && (
        <div className="fasst-outputs">
          <h4>FASST Output File(s)</h4>
          {outputs.length === 0 ? (
            <p className="fasst-empty">No outputs found yet.</p>
          ) : (
            <ul className="fasst-files-list">
              {outputs.map((f) => (
                <li className="fasst-file" key={f}>
                  <span className="fasst-file-name">{f}</span>
                  <button
                    className="fasst-download-button"
                    onClick={() => downloadFasstFile(f)}
                    title={`Download ${f}`}
                  >
                    <img className="fasst-download-logo" src={downloadLogo} alt="Download" />
                  </button>
                </li>
              ))}
            </ul>
          )}
        </div>
      )}

      {/* Charts */}
      {Object.keys(charts).length > 0 && (
        <div className="fasst-charts">
          <h3>FASST Charts</h3>
          <div className="fasst-chart-grid">
            {Object.entries(charts).map(([file, parsed]) => renderChart(file, parsed))}
          </div>
        </div>
      )}
      <div className="health-container">
        <HealthPanel title="FASST API Health" filterTag="FASST" />
      </div>
    </div>
  );
}

export default FasstRunner;
