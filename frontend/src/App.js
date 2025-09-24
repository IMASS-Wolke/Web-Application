import './App.css';
import { Route, Routes, Navigate } from 'react-router-dom';

import Navbar from "./components/Navbar/Navbar.js";
import Layout from "./components/Layout/Layout.js";

// import pages
import Home from "./components/Home/Home.js";
import Login from "./components/Login/Login.js";
import Signup from "./components/Signup/Signup.js";

// import models
import FAAST from "./components/Models/FAAST/FAAST.js";

function App() {
  return (
    <div className="App">
      <Layout /> {/* Component hides Navbar on Login/Sign-up pages. */}
      <main className="App-body">
        {/* Declared Routes */}
        <Routes>
          <Route path="/" element={ <Navigate to="/login"/> } />
          <Route path="/home" element={ <Home />} />
          <Route path="/login" element={ <Login /> } />
          <Route path="/signup" element={ <Signup /> } />
          <Route path="/faast" element={ <FAAST /> } />
          <Route path="*" element={ <h1>404 Error</h1> } />
        </Routes>
      </main>
    </div>
  );
}

export default App;
