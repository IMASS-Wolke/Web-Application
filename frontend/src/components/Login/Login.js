import './Login.css';

import { GoogleLogin, googleLogout } from "@react-oauth/google";
import { useNavigate } from 'react-router-dom';

function Login() {

  const navigate = useNavigate();

  return (
    <div className="Login">
      <div className="Login-container">
        <form className="Login-info">
          <div className="Email-container">
            <div className="Login-email-header">
              <text>Email Address</text>
            </div>
            <input className="email" type="text"/>
          </div>
          <div className="Password-container">
            <div className="Login-password-header">
              <text>Password</text>
              <button className="Forgot-password-button">Forgot password?</button>
            </div>
            <input className="password" type="text"/>
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
      </div>
    </div>
  );
}

export default Login;
