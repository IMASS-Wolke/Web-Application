import './Signup.css';
import logo from "../../assets/images/IMASS-logo.png";

import { use, useState } from "react";
import { useNavigate, Link } from 'react-router-dom';

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
          <img src={logo} alt="IMASS Logo" />
          <form className="Signup-info" onSubmit={handleSubmit}>
            {error && (
              <div className="Signup-error">
                {error}
                <button
                  className="Close-error"
                  type="button"
                  onClick={() => setError("")}
                >
                  X
                </button>
              </div>
            )}
            <div className="Signup-field">
              <div className="Signup-header">
                <label>Name</label>
              </div>
              <input
                className="Signup-input"
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                required
              />
            </div>
            <div className="Signup-field">
              <div className="Signup-header">
                <label>Email</label>
              </div>
              <input
                className="Signup-input"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
            </div>
            <div className="Signup-field">
              <div className="Signup-header">
                <label>Password</label>
              </div>
              <input
                className="Signup-input"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
            </div>
            <button className="Signup-button" type="submit">
              Sign Up
            </button>
          </form>
          <div>
            <text className="Login-account-header">Already have an account? </text>
            <Link className="Login-account-button" to="/login">Login</Link>
          </div>
        </div>
      </div>
    );
}

export default Signup;
