import './App.css';
import { Route, Routes } from 'react-router-dom';

// import pages
import Home from "./components/Home/Home.js";
import Login from "./components/Login/Login.js";

function App() {
  return (
    <div className="App">
      <main className="App-body">
        {/* Declared Routes */}
        <Routes>
          <Route path="/" element={ <Home /> } />
          <Route path="/login" element={ <Login /> } />
          <Route path="*" element={ <h1>404 Error</h1> } />
        </Routes>
      </main>
    </div>
  );
}

export default App;
