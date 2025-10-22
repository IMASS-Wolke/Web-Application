import { useState, useCallback } from "react";
import { useDropzone } from "react-dropzone";
import "./ModelRunner.css";

function SnthermRunner() {
    const [label, setLabel] = useState("");
    const [testIn, setTestIn] = useState(null);
    const [metSweIn, setMetSweIn] = useState(null);
    const [status, setStatus] = useState("");
    const [result, setResult] = useState(null);
    // Allows us to display the user input job label
    const [finalLabel, setFinalLabel] = useState("");

    const runSntherm = async () => {
        if (!testIn || !metSweIn) {
            setStatus("Please select both input files for SNTHERM.");
            return;
        }

        const formData = new FormData();
        formData.append("test_in", testIn);
        formData.append("metswe_in", metSweIn);
        if (label) formData.append("Label", label);

        setFinalLabel(label); // Sets the job label
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

    const downloadSnthermZip = async () => {
        if (!result?.runId) return;
        const response = await fetch(
            `http://localhost:5103/api/SnthermJob/runs/${result.runId}/zip`
        );
        const blob = await response.blob();
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = url;
        a.download = `${result.runId}_results.zip`;
        a.click();
    };

    const onDropTestIn = useCallback((acceptedFiles) => setTestIn(acceptedFiles[0]), []);
    const onDropMetSweIn = useCallback((acceptedFiles) => setMetSweIn(acceptedFiles[0]), []);

    const {
        getRootProps: getTestRoot,
        getInputProps: getTestInput,
        isDragActive: isTestActive,
    } = useDropzone({ onDrop: onDropTestIn, multiple: false });

    const {
        getRootProps: getMetRoot,
        getInputProps: getMetInput,
        isDragActive: isMetActive,
    } = useDropzone({ onDrop: onDropMetSweIn, multiple: false });

    return (
        <div className="sntherm-runner">
            <div className="label-input-wrapper">
                <label className="label-input-title">Label (optional):</label>
                <input
                    className="label-input"
                    type="text"
                    value={label}
                    onChange={(e) => setLabel(e.target.value)}
                    placeholder="job label"
                />
            </div>

            <div className={`dropdown-input ${isTestActive ? "active" : ""}`} {...getTestRoot()}>
                <input {...getTestInput()} />
                {testIn ? (
                    <p className="file-name">Uploaded: {testIn.name}</p>
                ) : (
                    <p>Drag & drop your TEST.IN file here, or click to browse.</p>
                )}
            </div>

            <div className={`dropdown-input ${isMetActive ? "active" : ""}`} {...getMetRoot()}>
                <input {...getMetInput()} />
                {metSweIn ? (
                    <p className="file-name">Uploaded: {metSweIn.name}</p>
                ) : (
                    <p>Drag & drop your METSWE.IN file here, or click to browse.</p>
                )}
            </div>

            <div className="sntherm-status-container">
                <p className="sntherm-status">{status}</p>
            </div>

            <div className="sntherm-controls">
                <button className="sntherm-run-button" onClick={runSntherm}>
                    Run SNTHERM
                </button>
            </div>

            {result && (
                <div className="sntherm-results">
                    <h3>SNTHERM Results</h3>
                    {finalLabel && (<p><strong>Job Label:</strong> {finalLabel}</p>)}
                    <p><strong>Run ID:</strong> {result.runId}</p>
                    <p><strong>Exit Code:</strong> {result.exitCode}</p>
                    <button className="sntherm-download-button" onClick={downloadSnthermZip}>
                        Download ZIP
                    </button>

                    <h4>Output Files:</h4>
                    <ul>
                        {result.outputs?.map((f) => (
                            <li key={f}>{f}</li>
                        ))}
                    </ul>
                </div>
            )}
        </div>
    );
}

export default SnthermRunner;
