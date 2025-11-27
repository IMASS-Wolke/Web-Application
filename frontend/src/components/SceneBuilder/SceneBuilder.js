// src/components/SceneBuilder/SceneBuilder.jsx
import React, { useState, useRef, useCallback } from "react";
import ReactFlow, {
  Background,
  Controls,
  addEdge,
  useNodesState,
  useEdgesState,
  MarkerType,
  Handle,
  Position,
} from "reactflow";

import "reactflow/dist/style.css";
import "./SceneBuilder.css";

// ---------------------------------------------------------
// Input Node
// ---------------------------------------------------------
const InputNode = ({ id, data }) => {
  const handleFileChange = (e) => {
    const file = e.target.files?.[0];
    data.onFileSelect(id, file);
  };

  return (
    <div className="scene-node scene-node-io">
      <Handle type="source" position={Position.Right} />

      <div className="scene-node-label">Input</div>

      <input
        type="file"
        onChange={handleFileChange}
        className="node-file-input"
      />

      {data.file && (
        <p className="node-file-name">{data.file.name}</p>
      )}
    </div>
  );
};

// ---------------------------------------------------------
// FASST Node
// ---------------------------------------------------------
const FasstNode = () => {
  return (
    <div className="scene-node scene-node-model scene-node-fasst">
      <Handle type="target" position={Position.Left} />
      <div className="scene-node-label">FASST</div>
      <Handle type="source" position={Position.Right} />
    </div>
  );
};

// ---------------------------------------------------------
// Output Node
// ---------------------------------------------------------
const OutputNode = () => {
  return (
    <div className="scene-node scene-node-io scene-node-output">
      <Handle type="target" position={Position.Left} />
      <div className="scene-node-label">Output</div>
    </div>
  );
};

const nodeTypes = {
  inputNode: InputNode,
  fasstNode: FasstNode,
  outputNode: OutputNode,
};

// ---------------------------------------------------------
// Scene Builder Component
// ---------------------------------------------------------
export default function SceneBuilder() {
  const apiBase = "http://localhost:5103/api/FasstIntegration";

  const idRef = useRef(1);
  const nextId = () => `${idRef.current++}`;

  // Pre-wired Input → FASST → Output chain
  const initialNodes = [
    {
      id: nextId(),
      type: "inputNode",
      position: { x: 50, y: 150 },
      data: {
        file: null,
        onFileSelect: handleFileSelect,
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

  function handleFileSelect(nodeId, file) {
    setNodes((nds) =>
      nds.map((n) =>
        n.id === nodeId ? { ...n, data: { ...n.data, file } } : n
      )
    );
  }

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

  const onConnect = useCallback(
    (params) =>
      setEdges((eds) =>
        addEdge(
          { ...params, markerEnd: { type: MarkerType.ArrowClosed } },
          eds
        )
      ),
    []
  );

  // ---------------------------------------------------------
  // Run the FASST container
  // ---------------------------------------------------------
  const runScene = async () => {
    setStatus("Running FASST...");

    const inputNode = nodes.find((n) => n.type === "inputNode");

    if (!inputNode?.data?.file) {
      setStatus("No input file selected.");
      return;
    }

    try {
      const form = new FormData();
      form.append("file", inputNode.data.file, inputNode.data.file.name);

      // RUN THE FASST CONTAINER
      const runRes = await fetch(`${apiBase}/run`, {
        method: "POST",
        body: form,
      });

      if (!runRes.ok) {
        const msg = await runRes.text();
        throw new Error(msg);
      }

      const result = await runRes.json().catch(() => ({}));

      // GET OUTPUT FILE LIST
      const outRes = await fetch(`${apiBase}/outputs`);
      const outputs = await outRes.json();

      setOutputArea({ result, outputs });
      setStatus("FASST completed.");
    } catch (err) {
      setStatus("Error: " + err.message);
    }
  };

  // ---------------------------------------------------------
  return (
    <div className="scene-builder-root">
      {/* Toolbar */}
      <div className="scene-builder-toolbar">
        <button className="scene-builder-run-button" onClick={runScene}>
          Run Scene
        </button>
        <span className="scene-status">{status}</span>
      </div>

      {/* Canvas */}
      <div className="scene-builder-main">
        <div className="scene-builder-canvas">
          <ReactFlow
            nodes={nodes}
            edges={edges}
            onNodesChange={onNodesChange}
            onEdgesChange={onEdgesChange}
            onConnect={onConnect}
            nodeTypes={nodeTypes}
            fitView
          >
            <Background variant="dots" gap={16} size={1} />
            <Controls />
          </ReactFlow>
        </div>
      </div>

      {/* Output Panel */}
      {outputArea && (
        <div className="scene-output-panel">
          <h3>FASST Output</h3>

          <pre className="output-json">
            {JSON.stringify(outputArea.result, null, 2)}
          </pre>

          <h4>Output Files</h4>
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
