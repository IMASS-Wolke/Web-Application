import './App.css';
import 'reactflow/dist/style.css';
import { Route, Routes, Navigate } from 'react-router-dom';

import Navbar from "./components/Navbar/Navbar.js";

// import pages
import Home from "./components/Home/Home.js";
import Login from "./components/Login/Login.js";
import Signup from "./components/Signup/Signup.js";
import SceneBuilder from "./components/SceneBuilder/SceneBuilder.js";

// import models
import ModelRunner from "./components/Models/ModelRunner/ModelRunner.js";
import Fasst from "./components/Models/FASST/FASST.js";

function App() {
  return (
    <div className="App">
      <Navbar /> {/* Component hides Navbar on Login/Sign-up pages. */}
      <main className="App-body">
        {/* Declared Routes */}
        <Routes>
          <Route path="/" element={ <Navigate to="/home"/> } />
          <Route path="/home" element={ <Home />} />
          <Route path="/login" element={ <Login /> } />
          <Route path="/signup" element={ <Signup /> } />
          <Route path="/models" element={<ModelRunner />} />
          <Route path="/fasst" element={ <Fasst /> } />
          <Route path="/scene-builder" element={ <SceneBuilder /> } />
          <Route path="*" element={ <h1>404 Error</h1> } />
        </Routes>
      </main>
    </div>
  );
}

export default App;
