import './App.css';
import { Route, Routes, Navigate } from 'react-router-dom';

// import pages
import Home from "./components/Home/Home.js";
import Login from "./components/Login/Login.js";
import Signup from "./components/Signup/Signup.js";

function App() {
  return (
    <div className="App">
      <main className="App-body">
        {/* Declared Routes */}
        <Routes>
          <Route path="/" element={ <Navigate to="/login"/> } />
          <Route path="/home" element={ <Home />} />
          <Route path="/login" element={ <Login /> } />
          <Route path="/signup" element={ <Signup /> } />
          <Route path="*" element={ <h1>404 Error</h1> } />
        </Routes>
      </main>
    </div>
  );
}

export default App;
