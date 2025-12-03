// src/components/SceneBuilder/SceneBuilder.jsx
import React, { useState, useRef, useCallback } from "react";
import ReactFlow, {
  Background,
  Controls,
  addEdge,
  useNodesState,
  useEdgesState,
  Handle,
  Position,
  MarkerType,
} from "reactflow";

import "reactflow/dist/style.css";
import "./SceneBuilder.css";

// ---------------------------------------------------------
// Input Node (auto-selects mode based on outgoing connection)
// ---------------------------------------------------------
const InputNode = ({ id, data }) => {
  const mode = data.mode;
  const files = data.files;

  const handleFasstFile = (e) => {
    const file = e.target.files?.[0];
    data.onFileSelect(id, { fasstFile: file });
  };

  const handleSnthermTest = (e) => {
    const file = e.target.files?.[0];
    data.onFileSelect(id, { ...files, testIn: file });
  };

  const handleSnthermMetSwe = (e) => {
    const file = e.target.files?.[0];
    data.onFileSelect(id, { ...files, metSweIn: file });
  };

  return (
    <div className="scene-node scene-node-io">
      <Handle type="source" position={Position.Right} />
      <div className="scene-node-label">Input ({mode})</div>

      {mode === "FASST" && (
        <>
          <input type="file" onChange={handleFasstFile} className="node-file-input" />
          {files?.fasstFile && <p className="node-file-name">{files.fasstFile.name}</p>}
        </>
      )}

      {mode === "SNTHERM" && (
        <>
          <input type="file" onChange={handleSnthermTest} className="node-file-input" />
          {files?.testIn && <p className="node-file-name">{files.testIn.name}</p>}

          <input type="file" onChange={handleSnthermMetSwe} className="node-file-input" />
          {files?.metSweIn && <p className="node-file-name">{files.metSweIn.name}</p>}
        </>
      )}
    </div>
  );
};

// ---------------------------------------------------------
// FASST Node
// ---------------------------------------------------------
const FasstNode = () => (
  <div className="scene-node scene-node-model scene-node-fasst">
    <Handle type="target" position={Position.Left} />
    <div className="scene-node-label">FASST</div>
    <Handle type="source" position={Position.Right} />
  </div>
);

// ---------------------------------------------------------
// SNTHERM Node
// ---------------------------------------------------------
const SnthermNode = () => (
  <div className="scene-node scene-node-model scene-node-sntherm">
    <Handle type="target" position={Position.Left} />
    <div className="scene-node-label">SNTHERM</div>
    <Handle type="source" position={Position.Right} />
  </div>
);

// ---------------------------------------------------------
// Output Node
// ---------------------------------------------------------
const OutputNode = () => (
  <div className="scene-node scene-node-io scene-node-output">
    <Handle type="target" position={Position.Left} />
    <div className="scene-node-label">Output</div>
  </div>
);

// Register node types
const nodeTypes = {
  inputNode: InputNode,
  fasstNode: FasstNode,
  snthermNode: SnthermNode,
  outputNode: OutputNode,
};

// ---------------------------------------------------------
// MAIN SCENE BUILDER
// ---------------------------------------------------------
export default function SceneBuilder() {
  const scenarioApi = "http://localhost:5103/api/ScenarioBuilder/run";

  const idRef = useRef(1);
  const nextId = () => `${idRef.current++}`;

  // -------------------------------------------------------
  // Initial graph: Input → FASST → Output
  // -------------------------------------------------------
  const initialNodes = [
    {
      id: nextId(),
      type: "inputNode",
      position: { x: 50, y: 150 },
      data: {
        mode: "FASST",
        files: {},
        onFileSelect: handleFileSelect,
        onAutoDetect: autoDetectMode,
      },
    },
    {
      id: nextId(),
      type: "fasstNode",
      position: { x: 300, y: 150 },
      data: {},
    },
    {
      id: nextId(),
      type: "outputNode",
      position: { x: 550, y: 150 },
      data: {},
    },
  ];

  const [nodes, setNodes, onNodesChange] = useNodesState(initialNodes);
  const [edges, setEdges, onEdgesChange] = useEdgesState([
    {
      id: "e1",
      source: initialNodes[0].id,
      target: initialNodes[1].id,
      markerEnd: { type: MarkerType.ArrowClosed },
    },
    {
      id: "e2",
      source: initialNodes[1].id,
      target: initialNodes[2].id,
      markerEnd: { type: MarkerType.ArrowClosed },
    },
  ]);

  const [status, setStatus] = useState("");
  const [outputArea, setOutputArea] = useState(null);

  // ----------------------------------------
  // ADD NODE BUTTONS
  // ----------------------------------------
  const addNode = (type) => {
    const node = {
      id: nextId(),
      type,
      position: { x: 100 + Math.random() * 200, y: 100 + Math.random() * 200 },
      data:
        type === "inputNode"
          ? {
              connectedModel: null,
              files: {},
              onFileUpdate: handleFileUpdate,
            }
          : {},
    };
    setNodes((nds) => nds.concat(node));
  };

  function handleFileUpdate(nodeId, newFiles) {
    setNodes((nds) =>
      nds.map((n) =>
        n.id === nodeId
          ? { ...n, data: { ...n.data, files: { ...newFiles } } }
          : n
      )
    );
  }

  // AUTO-DETECT MODEL
  function autoDetectMode(inputNodeId) {
    const outgoing = edges.find((e) => e.source === inputNodeId);
    if (!outgoing) return "FASST";

    const target = nodes.find((n) => n.id === outgoing.target);
    if (!target) return "FASST";

    if (target.type === "snthermNode") return "SNTHERM";
    if (target.type === "fasstNode") return "FASST";

    return "FASST";
  }

  function handleFileSelect(nodeId, newFiles) {
    setNodes((nds) =>
      nds.map((n) =>
        n.id === nodeId
          ? {
              ...n,
              data: {
                ...n.data,
                files: { ...n.data.files, ...newFiles },
              },
            }
          : n
      )
    );
  }

  const updateInputMode = () => {
    setNodes((nds) =>
      nds.map((n) => {
        if (n.type !== "inputNode") return n;
        const newMode = autoDetectMode(n.id);
        return { ...n, data: { ...n.data, mode: newMode } };
      })
    );
  };

  const onConnect = useCallback((params) => {
    setEdges((eds) =>
      addEdge({ ...params, markerEnd: { type: MarkerType.ArrowClosed } }, eds)
    );
    setTimeout(updateInputMode, 0);
  }, []);

  const onEdgesUpdated = (...args) => {
    onEdgesChange(...args);
    setTimeout(updateInputMode, 0);
  };

  // -------------------------------------------------------
  // RUN MODEL (FASST or SNTHERM)
  // -------------------------------------------------------
  const runScene = async () => {
    const input = nodes.find((n) => n.type === "inputNode");
    const modelNode = nodes.find(
      (n) => n.type === "fasstNode" || n.type === "snthermNode"
    );

    if (!input || !modelNode) {
      setStatus("Invalid chain.");
      return;
    }

    const mode = input.data.mode;
    const files = input.data.files;

    try {
      setStatus("Running model...");
      let result = null;
      let outputs = [];

      const form = new FormData();

      if (mode === "FASST") {
        if (!files.fasstFile)
          return setStatus("Missing FASST input file.");

        form.append("model_name", "FASST");
        form.append("scenario_name", "Auto Scene");
        form.append("inputFile1", files.fasstFile);
      }

      if (mode === "SNTHERM") {
        if (!files.testIn || !files.metSweIn)
          return setStatus("SNTHERM requires TEST.IN and METSWE.IN");

        form.append("model_name", "SNTHERM");
        form.append("scenario_name", "Auto Scene");
        form.append("inputFile1", files.testIn);
        form.append("inputFile2", files.metSweIn);
      }

      const runRes = await fetch(scenarioApi, {
        method: "POST",
        body: form,
      });

      result = await runRes.json();
      outputs = result.Outputs || [];

      setOutputArea({ result, outputs });
      setStatus("Completed.");
    } catch (err) {
      setStatus("Error: " + err.message);
    }
  };

  // -------------------------------------------------------
  return (
    <div className="scene-builder-root">
      <div className="scene-builder-toolbar">
        <button onClick={() => addNode("inputNode")}>+ Input</button>
        <button onClick={() => addNode("snthermNode")}>+ SNTHERM</button>
        <button onClick={() => addNode("fasstNode")}>+ FASST</button>
        <button onClick={() => addNode("outputNode")}>+ Output</button>
        <button className="scene-builder-run-button" onClick={runScene}>
          Run Scene
        </button>
        <span className="scene-status">{status}</span>
      </div>

      <div className="scene-builder-main">
        <div className="scene-builder-canvas">
          <ReactFlow
            nodes={nodes}
            edges={edges}
            nodeTypes={nodeTypes}
            onNodesChange={onNodesChange}
            onEdgesChange={onEdgesUpdated}
            onConnect={onConnect}
            fitView
          >
            <Background variant="dots" gap={20} size={1} />
            <Controls />
          </ReactFlow>
        </div>
      </div>

      {outputArea && (
        <div className="scene-output-panel">
          <h3>Output</h3>

          <pre className="output-json">
            {JSON.stringify(outputArea.result, null, 2)}
          </pre>

          <h4>Files</h4>
          <ul>
            {outputArea.outputs?.map((f) => (
              <li key={f}>{f}</li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}
