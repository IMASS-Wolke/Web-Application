// src/components/SceneBuilder/SceneBuilder.jsx
import React, { useCallback, useMemo, useRef, useState } from "react";
import ReactFlow, {
  Background,
  Controls,
  MiniMap,
  addEdge,
  useNodesState,
  useEdgesState,
  MarkerType,
  Handle,
  Position,
} from "reactflow";
import "reactflow/dist/style.css";
import "./SceneBuilder.css";

// -------- Custom Node Components --------

const IoNode = ({ data }) => {
  // data.type: 'input' | 'output'
  const isInput = data.type === "input";
  const isOutput = data.type === "output";

  return (
    <div className={`scene-node scene-node-io scene-node-${data.type}`}>
      {/* Target handle (from previous step) for Output only */}
      {isOutput && (
        <Handle type="target" position={Position.Left} style={{ borderRadius: 0 }} />
      )}

      <div className="scene-node-label">{data.label}</div>

      {/* Source handle (to next step) for Input only */}
      {isInput && (
        <Handle type="source" position={Position.Right} style={{ borderRadius: 0 }} />
      )}
    </div>
  );
};

const ModelNode = ({ data }) => {
  // data.model: 'SNTHERM' | 'FASST'
  return (
    <div className={`scene-node scene-node-model scene-node-${data.model.toLowerCase()}`}>
      <Handle type="target" position={Position.Left} style={{ borderRadius: 0 }} />
      <div className="scene-node-label">{data.label}</div>
      <Handle type="source" position={Position.Right} style={{ borderRadius: 0 }} />
    </div>
  );
};

const nodeTypes = {
  ioNode: IoNode,
  modelNode: ModelNode,
};

// ------- Utility: connection validation -------

function isValidConnection(connection, nodes) {
  const sourceNode = nodes.find((n) => n.id === connection.source);
  const targetNode = nodes.find((n) => n.id === connection.target);
  if (!sourceNode || !targetNode) return false;

  const sType = sourceNode.data.type;
  const tType = targetNode.data.type;

  // Can't draw edge out of an output node
  if (sType === "output") return false;

  // Can't draw edge into an input node
  if (tType === "input") return false;

  // Prevent self loops
  if (connection.source === connection.target) return false;

  return true;
}

// ------- Main Component -------

function SceneBuilder({ apiBaseUrl = "http://localhost:5103" }) {
  // Node ID counter
  const idRef = useRef(1);
  const getNextId = () => `${idRef.current++}`;

  const initialNodes = useMemo(
    () => [
      {
        id: getNextId(),
        type: "ioNode",
        position: { x: 50, y: 150 },
        data: { label: "Input", type: "input" },
      },
      {
        id: getNextId(),
        type: "modelNode",
        position: { x: 300, y: 100 },
        data: { label: "SNTHERM", type: "model", model: "SNTHERM" },
      },
      {
        id: getNextId(),
        type: "modelNode",
        position: { x: 300, y: 220 },
        data: { label: "FASST", type: "model", model: "FASST" },
      },
      {
        id: getNextId(),
        type: "ioNode",
        position: { x: 550, y: 150 },
        data: { label: "Output", type: "output" },
      },
    ],
    []
  );

  const [nodes, setNodes, onNodesChange] = useNodesState(initialNodes);
  const [edges, setEdges, onEdgesChange] = useEdgesState([]);
  const [runResult, setRunResult] = useState(null);

  const onConnect = useCallback(
    (connection) => {
      setEdges((eds) => {
        if (!isValidConnection(connection, nodes)) {
          // silently ignore invalid connections for now
          return eds;
        }

        return addEdge(
          {
            ...connection,
            type: "smoothstep",
            markerEnd: {
              type: MarkerType.ArrowClosed,
              width: 18,
              height: 18,
            },
          },
          eds
        );
      });
    },
    [nodes, setEdges]
  );

  const addIoNode = useCallback(
    (type) => {
      const isInput = type === "input";
      const label = isInput ? "Input" : "Output";

      const newNode = {
        id: getNextId(),
        type: "ioNode",
        position: { x: isInput ? 50 : 550, y: 50 + nodes.length * 40 },
        data: { label, type },
      };
      setNodes((nds) => nds.concat(newNode));
    },
    [nodes.length, setNodes]
  );

  const addModelNode = useCallback(
    (model) => {
      const label = model.toUpperCase(); // SNTHERM / FASST
      const newNode = {
        id: getNextId(),
        type: "modelNode",
        position: { x: 300, y: 50 + nodes.length * 40 },
        data: { label, type: "model", model },
      };
      setNodes((nds) => nds.concat(newNode));
    },
    [nodes.length, setNodes]
  );

  // Build a simple linear chain for each Input -> ... -> Output path
  const buildChains = useCallback(() => {
    const nodeById = Object.fromEntries(nodes.map((n) => [n.id, n]));
    const outgoing = {};
    edges.forEach((e) => {
      if (!outgoing[e.source]) outgoing[e.source] = [];
      outgoing[e.source].push(e.target);
    });

    const inputNodes = nodes.filter((n) => n.data.type === "input");

    const chains = inputNodes.map((inputNode) => {
      const steps = [];
      const visited = new Set();
      let currentId = inputNode.id;

      while (currentId && !visited.has(currentId)) {
        visited.add(currentId);
        const n = nodeById[currentId];
        if (!n) break;

        const { type, model } = n.data;
        steps.push({
          id: n.id,
          kind: type === "model" ? "job" : type, // 'input' | 'output' | 'job'
          model: model || null, // SNTHERM/FASST or null for I/O
          label: n.data.label,
        });

        const nextTargets = outgoing[currentId] || [];
        // For now, assume at most 1 linear successor
        currentId = nextTargets[0];
      }

      return steps;
    });

    return chains;
  }, [nodes, edges]);

  const chainPreview = useMemo(() => buildChains(), [buildChains]);

  const handleRunScene = useCallback(async () => {
    const chains = buildChains();

    const payload = {
      nodes: nodes.map((n) => ({
        id: n.id,
        type: n.data.type,
        model: n.data.model || null,
        label: n.data.label,
        position: n.position,
      })),
      edges: edges.map((e) => ({
        source: e.source,
        target: e.target,
      })),
      chains,
    };

    try {
      // Change this endpoint to whatever your team created
      const res = await fetch(`${apiBaseUrl}/api/Scene/run`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      if (!res.ok) {
        throw new Error(`Backend returned ${res.status}`);
      }

      const data = await res.json();
      setRunResult(data);
    } catch (err) {
      console.error(err);
      setRunResult({ error: err.message });
    }
  }, [apiBaseUrl, buildChains, nodes, edges]);

  return (
    <div className="scene-builder-root">
      <div className="scene-builder-toolbar">
        <div className="scene-builder-toolbar-group">
          <span className="scene-builder-toolbar-label">Add nodes:</span>
          <button onClick={() => addIoNode("input")}>+ Input</button>
          <button onClick={() => addModelNode("SNTHERM")}>+ SNTHERM</button>
          <button onClick={() => addModelNode("FASST")}>+ FASST</button>
          <button onClick={() => addIoNode("output")}>+ Output</button>
        </div>

        <div className="scene-builder-toolbar-group">
          <button className="scene-builder-run-button" onClick={handleRunScene}>
            Run Scene
          </button>
        </div>
      </div>

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

        <div className="scene-builder-sidepanel">
          <h3>Current Chain(s)</h3>
          <pre className="scene-builder-json">
            {JSON.stringify(chainPreview, null, 2)}
          </pre>

          <h3>Last Run Result</h3>
          <pre className="scene-builder-json">
            {runResult ? JSON.stringify(runResult, null, 2) : "// Run Scene to see backend response"}
          </pre>
        </div>
      </div>
    </div>
  );
}

export default SceneBuilder;
