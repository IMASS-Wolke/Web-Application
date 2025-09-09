import './Signup.css';
import { use, useState } from "react";
import { useNavigate } from 'react-router-dom';

function Signup() {
    
    const navigate = useNavigate();

    const [name, setName] = useState("");
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [error, setError] = useState("");

    const handleSubmit = async (e) => {
        e.preventDefault();

        console.log("Signup Attempt:", { name, email, password });

        try {
            const response = await fetch("http://localhost:5103/api/Accounts/signup", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    name: name,
                    email: email,
                    password: password
                }),
            });

            if (!response.ok) {
                const msg = await response.text();
                throw new Error(msg || "Signup failed");
            }

            console.log("Signup successful");
            navigate("/login");
        } catch (err) {
            setError(err.message);
        }
    };

    return (
        <div className="Signup">
      <div className="Signup-container">
        <form className="Signup-info" onSubmit={handleSubmit}>
          <div className="Signup-field">
            <label>Name</label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
            />
          </div>
          <div className="Signup-field">
            <label>Email Address</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </div>
          <div className="Signup-field">
            <label>Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </div>

          {error && (
            <div className="Signup-error">
              {error}
              <button
                type="button"
                className="close-btn"
                onClick={() => setError("")}
              >
                X
              </button>
            </div>
          )}

          <button className="Signup-button" type="submit">
            Sign Up
          </button>
        </form>
      </div>
    </div>
    );
}

export default Signup;
