import { useState } from "react";
import "./ModelRunner.css";
import downloadLogo from "../../../assets/icons/download.svg";

function FasstRunner() {
    const [status, setStatus] = useState("");
    const [result, setResult] = useState(null);
    const [outputs, setOutputs] = useState([]);

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

    const fetchFasstOutputs = async () => {
        try {
            const res = await fetch("http://localhost:5103/api/FasstIntegration/outputs");
            const data = await res.json();
            setOutputs(data);
        } catch {
            setStatus("Error loading FASST outputs.");
        }
    };

    const downloadFasstFile = async (filename) => {
        const res = await fetch(
            `http://localhost:5103/api/FasstIntegration/outputs/${filename}/stream`
        );
        const blob = await res.blob();
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = url;
        a.download = filename;
        a.click();
    };

    return (
        <div className="fasst-runner">
            <div className="fasst-controls">
                <button className="fasst-run-button" onClick={runFasst}>
                    Run FASST
                </button>
            </div>

            <div className="fasst-status-container">
                <p className="fasst-status">{status}</p>
            </div>

            {result && (
                <div className="fasst-results">
                    <h3>FASST Run Results</h3>
                    <p><strong>Status:</strong> {status}</p>
                </div>
            )}

            <div className="fasst-outputs">
                <h4>FASST Output File(s)</h4>
                <button
                    className="fasst-refresh-button"
                    onClick={fetchFasstOutputs}
                >
                    Refresh Outputs
                </button>
                <ul>
                    {outputs.map((f) => (
                        <li className="fasst-file" key={f}>
                            {f}
                            <button
                                className="fasst-download-button"
                                onClick={() => downloadFasstFile(f)}
                            >
                                <img
                                    className="fasst-download-logo"
                                    src={downloadLogo}
                                    alt="Download"
                                />
                            </button>
                        </li>
                    ))}
                </ul>
            </div>
        </div>
    );
}

export default FasstRunner;
