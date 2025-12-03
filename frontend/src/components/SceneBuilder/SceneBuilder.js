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

import JSZip from "jszip";

import "reactflow/dist/style.css";
import "./SceneBuilder.css";

// ---------------------------------------------------------
// Input Node
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
          <input type="file" onChange={handleFasstFile} />
          {files?.fasstFile && <p>{files.fasstFile.name}</p>}
        </>
      )}

      {mode === "SNTHERM" && (
        <>
          <input type="file" onChange={handleSnthermTest} />
          {files?.testIn && <p>{files.testIn.name}</p>}

          <input type="file" onChange={handleSnthermMetSwe} />
          {files?.metSweIn && <p>{files.metSweIn.name}</p>}
        </>
      )}
    </div>
  );
};

// ---------------------------------------------------------
// Model Nodes
// ---------------------------------------------------------
const FasstNode = () => (
  <div className="scene-node scene-node-model scene-node-fasst">
    <Handle type="target" position={Position.Left} />
    <div className="scene-node-label">FASST</div>
    <Handle type="source" position={Position.Right} />
  </div>
);

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
  const runApi = "http://localhost:5103/api/ScenarioBuilder/run";
  const snthermOutputApi = "http://localhost:5103/api/SnthermJob/runs";

  const idRef = useRef(1);
  const nextId = () => `${idRef.current++}`;

  // -------------------------------------------------------
  // Initial graph
  // -------------------------------------------------------
  const initialNodes = [
    {
      id: nextId(),
      type: "inputNode",
      position: { x: 50, y: 150 },
      data: {
        mode: "SNTHERM",
        files: {},
        onFileSelect: handleFileSelect,
        onAutoDetect: autoDetectMode,
      },
    },
  ];

  const [nodes, setNodes, onNodesChange] = useNodesState(initialNodes);
  const [edges, setEdges, onEdgesChange] = useEdgesState([]);
  const [status, setStatus] = useState("");
  const [outputArea, setOutputArea] = useState({ sntherm: null, fasst: null });

  // -------------------------------------------------------
  // Add Nodes
  // -------------------------------------------------------
  const addNode = (type) => {
    const node = {
      id: nextId(),
      type,
      position: { x: 150 + Math.random() * 200, y: 150 + Math.random() * 150 },
      data:
        type === "inputNode"
          ? {
            files: {},
            onFileSelect: handleFileSelect,
          }
          : {},
    };
    setNodes((nds) => nds.concat(node));
  };

  // -------------------------------------------------------
  // File Handling
  // -------------------------------------------------------
  function handleFileSelect(nodeId, newFiles) {
    setNodes((nds) =>
      nds.map((n) =>
        n.id === nodeId
          ? { ...n, data: { ...n.data, files: { ...n.data.files, ...newFiles } } }
          : n
      )
    );
  }

  // -------------------------------------------------------
  // Auto-Detect Model Type
  // -------------------------------------------------------
  function autoDetectMode(inputNodeId) {
    const outgoing = edges.find((e) => e.source === inputNodeId);
    if (!outgoing) return "SNTHERM";

    const target = nodes.find((n) => n.id === outgoing.target);
    if (!target) return "SNTHERM";

    if (target.type === "snthermNode") return "SNTHERM";
    if (target.type === "fasstNode") return "FASST";

    return "SNTHERM";
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
  // GRAPH EXECUTION ORDER (TOPOLOGICAL SORT)
  // -------------------------------------------------------
  function computeExecutionOrder() {
    const map = {};
    nodes.forEach((n) => {
      map[n.id] = { node: n, incoming: [], outgoing: [] };
    });

    edges.forEach((e) => {
      map[e.source].outgoing.push(e.target);
      map[e.target].incoming.push(e.source);
    });

    const order = [];
    const queue = [];

    Object.values(map)
      .filter((x) => x.incoming.length === 0)
      .forEach((x) => queue.push(x));

    while (queue.length) {
      const current = queue.shift();
      order.push(current.node);

      current.outgoing.forEach((targetId) => {
        const t = map[targetId];
        t.incoming = t.incoming.filter((id) => id !== current.node.id);
        if (t.incoming.length === 0) queue.push(t);
      });
    }

    return order;
  }

  // -------------------------------------------------------
  // RUN SNTHERM
  // -------------------------------------------------------
  async function runSntherm(files) {
    // --- send job to backend ---
    const form = new FormData();
    form.append("model_name", "SNTHERM");
    form.append("scenario_name", "Scene");
    form.append("inputFile1", files.testIn);
    form.append("inputFile2", files.metSweIn);

    const res = await fetch(runApi, { method: "POST", body: form });

    const text = await res.text();
    let json;
    try {
        json = JSON.parse(text);
    } catch {
        console.error("Invalid JSON from SNTHERM:", text);
        throw new Error("SNTHERM returned invalid JSON");
    }

    setOutputArea((o) => ({ ...o, sntherm: json }));

    const runId = json.runId ?? json.runID ?? json.runid;
    if (!runId) throw new Error("SNTHERM did not return runId");

    // --- download ZIP with results ---
    const zipRes = await fetch(`${snthermOutputApi}/${runId}/zip`);
    const zipBlob = await zipRes.blob();

    // --- load ZIP with JSZip ---
    const jszipData = await JSZip.loadAsync(zipBlob);
    
    let brockFile = null;

    for (let path in jszipData.files) {
        if (path.toLowerCase().includes("brock.out")) {
            const content = await jszipData.files[path].async("blob");
            brockFile = new File([content], "brock.out");
        }
    }

    if (!brockFile) {
        throw new Error("brock.out not found in ZIP");
    }

    return brockFile;
}



  // -------------------------------------------------------
  // RUN FASST WITH SNTHERM OUTPUT
  // -------------------------------------------------------
  async function runFasst(inputFile) {
    const form = new FormData();
    form.append("model_name", "FASST");
    form.append("scenario_name", "Scene");
    form.append("inputFile1", inputFile);

    const res = await fetch(runApi, { method: "POST", body: form });
    const json = await res.json();

    setOutputArea((o) => ({ ...o, fasst: json }));

    return json;
  }

  // -------------------------------------------------------
  // RUN CHAIN (SNTHERM → FASST)
  // -------------------------------------------------------
  const runScene = async () => {
    setStatus("Running chain...");

    const order = computeExecutionOrder();

    let snthermInput = null;
    let snthermOutputFile = null;

    for (const n of order) {
      if (n.type === "inputNode") {
        if (n.data.mode === "SNTHERM") {
          snthermInput = n.data.files;
        }
      }

      if (n.type === "snthermNode") {
        snthermOutputFile = await runSntherm(snthermInput);
      }

      if (n.type === "fasstNode") {
        await runFasst(snthermOutputFile);
      }
    }

    setStatus("Completed.");
  };

  // -------------------------------------------------------
  // UI
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

      {/* OUTPUT PANEL */}
      <div className="scene-output-panel">
        <h3>SNTHERM Output</h3>
        <pre className="output-json">
          {JSON.stringify(outputArea.sntherm, null, 2)}
        </pre>

        <h3>FASST Output</h3>
        <pre className="output-json">
          {JSON.stringify(outputArea.fasst, null, 2)}
        </pre>
      </div>
    </div>
  );
}
