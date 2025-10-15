import './Home.css';

import Upload from '../Upload/Upload.js';
import ModelRunner from "../Models/ModelRunner/ModelRunner.js";

function Home() {
  return (
    <div className="Home">
      <header className="Home-header">
        Welcome to IMASS
      </header>
      <div className="Upload-container">
        {/*<Upload />*/}
        <ModelRunner />
      </div>
    </div>
  );
}

export default Home;
