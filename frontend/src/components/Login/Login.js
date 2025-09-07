import './Login.css';

import { GoogleLogin, googleLogout } from "@react-oauth/google";
import { useNavigate } from 'react-router-dom';

function Login() {

  const navigate = useNavigate();

  return (
    <div className="Login">
      <>
        <GoogleLogin 
          onSuccess={ () => { 
            console.log("Login success")
            navigate("/")
          }} 
          onError={ () => console.log("Login failed") }
        />
      </>
    </div>
  );
}

export default Login;
