// HealthPanel.js
import { useEffect, useState } from "react";
import * as signalR from "@microsoft/signalr";

export default function HealthPanel() {
  const [connected, setConnected] = useState(false);
  const [payload, setPayload] = useState(null);
  const hubUrl = "${process.env.REACT_APP_API_URL}/hubs/health";

  useEffect(() => {
    const conn = new signalR.HubConnectionBuilder()
      .withUrl(hubUrl, { withCredentials: true })
      .withAutomaticReconnect()
      .build();

    conn.on("healthUpdate", (data) => setPayload(data));

    conn.start()
      .then(() => setConnected(true))
      .catch((e) => console.error("SignalR start error:", e));

    return () => { conn.stop(); };
  }, []);

  return (
    <div style={{ padding: 12 }}>
      <text>Health Monitor {connected ? "🟢" : "🔴"}</text>
      {!payload ? <p>Waiting for updates…</p> : (
        <>
          <p><b>Status:</b> {payload.status}</p>
          <ul>
            {(payload.entries || []).map(e => (
              <li key={e.name}>
                {e.name} — {e.status} ({e.durationMs.toFixed(3)} ms)
              </li>
            ))}
          </ul>
        </>
      )}
    </div>
  );
}
