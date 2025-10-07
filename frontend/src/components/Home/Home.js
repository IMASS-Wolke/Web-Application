import './Home.css';

import Upload from '../Upload/Upload.js';

function Home() {
  return (
    <div className="Home">
      <header className="Home-header">
        Welcome to IMASS
      </header>
      <div className="Upload-container">
        <Upload />
      </div>
    </div>
  );
}

export default Home;
