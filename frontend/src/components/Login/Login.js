import './Login.css';

import { useState } from "react";
import { GoogleLogin, googleLogout } from "@react-oauth/google";
import { useNavigate, Link } from 'react-router-dom';

function Login() {

  const navigate = useNavigate();

  const [ username, setUsername ] = useState("");
  const [ password, setPassword ] = useState("");
  const [ error, setError ] = useState("");

  const handleSubmit = async (e) => {
    e.preventDefault();

    console.log("Username:", username, "Password:", password);

    try {
      const response = await fetch("http://localhost:5103/api/Accounts/Login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username, password }),
      });

      if (!response.ok) {
        throw new Error("Invalid credentials");
      }

      const data = await response.json();
      console.log("Login successful:", data);

      // Store tokens (your backend sends both)
      localStorage.setItem("accessToken", data.accessToken);
      localStorage.setItem("refreshToken", data.refreshToken);

      // Redirect or update UI
      navigate("/home");
    } catch (err) {
      setError(err.message);
    }
  };

  return (
    <div className="Login">

      <div className="Login-container">
        <form className="Login-info" onSubmit={ handleSubmit }>
          {error && <div className="Login-error">
            <span>{error}</span>
            <button className="Close-error" onClick={() => setError("")}>X</button>
          </div>}
          <div className="Email-container">
            <div className="Login-email-header">
              <text>Email Address</text>
            </div>
            <input 
              className="email" 
              type="email"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              required
            />
          </div>
          <div className="Password-container">
            <div className="Login-password-header">
              <text>Password</text>
              {/* <button className="Forgot-password-button">Forgot password?</button> */}
            </div>
            <input 
              className="password" 
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </div>
          <button className="Login-button" type="submit">Sign in</button>
        </form>
      <div className="Login-divider">
        <div className="divider"/>
        <text className="or-text">or</text>
        <div className="divider"/>
      </div>
        <div>
          <GoogleLogin
            className="Google-login"
            onSuccess={ () => { 
              console.log("Login success")
              navigate("/")
            }} 
            onError={ () => console.log("Login failed") }
          />
        </div>
        <div>
            <text className="Create-account-header">New here? </text>
            <Link className="Create-account-button" to="/signup">Create an account</Link>
        </div>
      </div>
    </div>
  );
}

export default Login;
