// SceneBuilder.js
// Minimal ReactFlow skeleton with external CSS for styling.

import { useMemo } from 'react';
import ReactFlow, {
    Background,
    Controls,
    Panel,
    useNodesState,
    useEdgesState,
    addEdge,
    useReactFlow
} from 'reactflow';
import 'reactflow/dist/style.css';
import './SceneBuilder.css';

function ResetPanel({ initialNodes, initialEdges, setNodes, setEdges }) {
    const { fitView } = useReactFlow();

    const reset = () => {
        setNodes(initialNodes);
        setEdges(initialEdges);
        setTimeout(() => fitView({ padding: 0.2 }), 0);
    };

    return (
        <Panel position="top-left">
            <button className="btn-reset" onClick={reset}>Reset Scene Builder</button>
        </Panel>
    );
}

export default function SceneBuilder() {
    const initialNodes = useMemo(
        () => [
            { id: 'start', position: { x: 50, y: 120 }, data: { label: 'Start' }, type: 'input' },
            { id: 'sntherm', position: { x: 300, y: 100 }, data: { label: 'SNTHERM' } },
            { id: 'fasst', position: { x: 550, y: 100 }, data: { label: 'FASST' } },
            { id: 'end', position: { x: 800, y: 120 }, data: { label: 'End' }, type: 'output' },
        ],
        []
    );

    const initialEdges = useMemo(
        () => [],
        []
    );

    const [nodes, setNodes, onNodesChange] = useNodesState(initialNodes);
    const [edges, setEdges, onEdgesChange] = useEdgesState(initialEdges);

    const onConnect = (connection) => setEdges((eds) => addEdge({ ...connection, animated: true }, eds));

    return (
        <div className="scene-container">
            <div className="scene-header">
                <text>IMASS Scene Builder</text>
            </div>
            <div className="react-flow-table">
                {/*** React Flow Scene Builder Component ***/}
                <ReactFlow
                    nodes={nodes}
                    edges={edges}
                    onNodesChange={onNodesChange}
                    onEdgesChange={onEdgesChange}
                    onConnect={onConnect}
                    fitView
                    proOptions={{ hideAttribution: true }}
                >
                    <ResetPanel
                        initialNodes={initialNodes}
                        initialEdges={initialEdges}
                        setNodes={setNodes}
                        setEdges={setEdges}
                    />
                    <Controls />
                    <Background />
                </ReactFlow>
            </div>
        </div>
    );
}
