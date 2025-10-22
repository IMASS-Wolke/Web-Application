import './Home.css';
import { useNavigate } from 'react-router-dom';
import Upload from '../Upload/Upload.js';
import ModelRunner from "../Models/ModelRunner/ModelRunner.js";

function Home() {
  const navigate = useNavigate();
  const handleClick = () => {
    navigate("/models");
  };

  return (
    <div className="Home home-fade">
      <header className="Home-header">
        Welcome to IMASS
      </header>

      <div className="what-is-imass">
        <h1 className="landing-title">What is IMASS?</h1>
        <p className="landing-paragraph">
          The <strong>Integrated Modeling and Simulation System (IMASS)</strong> is a unified digital platform designed to bring multiple environmental and physical process models together into a single, easy-to-use interface...
        </p>

        <h2 className="landing-subtitle">A Unified Approach to Modeling</h2>
        <p className="landing-paragraph">
          IMASS allows users to visualize, compare, and analyze results from different models in one place...
        </p>

        <h2 className="landing-subtitle">Built for Efficiency and Integration</h2>
        <p className="landing-paragraph">
          IMASS enhances efficiency by consolidating model execution, data management, and visualization...
        </p>
      </div>

      <div className="get-started-wrapper">
        <button className="get-started-button" onClick={handleClick}>
          Get Started
        </button>
      </div>
    </div>
  );
}

export default Home;
