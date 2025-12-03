import { useState } from "react";
import FasstOutput from "../../Outputs/Fasst-outputs";
import "./FASST.css";
import { API_BASE_URL } from "../../../config";

function Fasst() {
    const [temperatureC, setTemperatureC] = useState("");
    const [humidity, setHumidity] = useState("");
    const [message, setMessage] = useState("");

    const handleSubmit = async (e) => {
        e.preventDefault();

        try {
            const jobId = 123; // Hardcode ID's until further notice
            const modelId = 321; // Hardcode ID's until further notice

            const response = await fetch(`${API_BASE_URL}/api/Job/${jobId}/models/${modelId}/Fasst`, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify({
                    temperatureC: parseFloat(temperatureC),
                    humidity: parseFloat(humidity),
                }),
            });

            if (response.ok) {
                setMessage("Successful!");
                setTemperatureC("");
                setHumidity("");
            } else {
                setMessage("Failed!");
            }
        } catch (error) {
            console.error("Error submitting: ", error);
            setMessage("Error!");
        }
    }

    return (
    <div className="fasst-container">
        <h1>Fasst</h1>
        <div className="fasst-graph">
            <FasstOutput />
        </div>
        {/*}
        <form onSubmit={handleSubmit}>
            <div>
                <label>Temperature (°C)</label>
                <input
                    type="number"
                    step="0.1"
                    value={ temperatureC }
                    onChange={(e) => setTemperatureC(e.target.value)}
                    required
                />
            </div>
            <div>
                <label>Humidity (%)</label>
                <input
                    type="number"
                    step="0.1"
                    value={ humidity }
                    onChange={(e) => setHumidity(e.target.value)}
                    required
                />
            </div>
            <button type="submit">Submit</button>
        </form>
        {message && <p>{message}</p>}*/}
    </div>
)
};

export default Fasst;
