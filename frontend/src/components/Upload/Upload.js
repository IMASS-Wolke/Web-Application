import { useState, useCallback } from "react";
import { useDropzone } from "react-dropzone";
import "./Upload.css";

function Upload() {
  const models = [
    { modelId: "sntherm", name: "SNTHERM" },
    { modelId: "faast", name: "FASST" },
  ];

  // --- State ---
  const [selectedModel, setSelectedModel] = useState("");
  const [files, setFiles] = useState([]);
  const [uploadStatus, setUploadStatus] = useState("");

  // --- Drop logic ---
  const onDrop = useCallback(
    (acceptedFiles) => {
      if (!selectedModel) {
        setUploadStatus("Please select a model.");
        return;
      }
      setFiles(acceptedFiles);
      setUploadStatus("File uploaded!");
    },
    [selectedModel]
  );

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    multiple: true,
  });

  return (
    <div className="upload-container">
      <text>Upload Input File</text>

      {/* Model Dropdown */}
      <select
        className="upload-dropdown"
        value={selectedModel}
        onChange={(e) => {
          setSelectedModel(e.target.value);
          setFiles([]);
          setUploadStatus("");
        }}
      >
        <option value="">Select Model...</option>
        {models.map((model) => (
          <option key={model.modelId} value={model.modelId}>
            {model.name}
          </option>
        ))}
      </select>

      {/* Drop Zone */}
      <div
        {...getRootProps()}
        className={`dropzone ${isDragActive ? "active" : ""}`}
      >
        <input {...getInputProps()} />
        {isDragActive ? (
          <p>Drop file(s) here ...</p>
        ) : (
          <p>Drop file(s) here, or click to browse</p>
        )}
      </div>

      {/* Upload Status */}
      <p className="upload-status">{uploadStatus}</p>

      {/* Display the file(s) list after upload */}
      {files.length > 0 && (
        <div className="file-list">
          <h4>Files:</h4>
          <ul>
            {files.map((file) => (
              <li key={file.name}>
                {file.name} ({Math.round(file.size / 1024)} KB)
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}

export default Upload;
