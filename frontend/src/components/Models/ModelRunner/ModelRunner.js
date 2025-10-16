import { useState } from "react";
import "./ModelRunner.css";
import FasstRunner from "./FasstRunner";
import SnthermRunner from "./SnthermRunner";

function ModelRunner() {
  const [model, setModel] = useState("SNTHERM");

  return (
    <div className="model-runner">
      <div className="model-selector-wrapper">
        <label className="model-selector-title">Select Model:</label>
        <select
          className="model-selector"
          value={model}
          onChange={(e) => setModel(e.target.value)}
        >
          <option value="SNTHERM">SNTHERM</option>
          <option value="FASST">FASST</option>
        </select>
      </div>

      <div className="model-divider" />

      {/* Fade-in transition for the selected model */}
      <div key={model} className="model-fade">
        {model === "SNTHERM" && <SnthermRunner />}
        {model === "FASST" && <FasstRunner />}
      </div>
    </div>
  );
}

export default ModelRunner;
