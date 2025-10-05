import { Link } from 'react-router-dom';
import './Navbar.css';
import logo from "../../assets/icons/cloud.svg";

function Navbar() {

    return (
        <div className="nav-container">
            <nav className="navbar">
                <div className="navlink-container">
                    <header className="Navbar-title-container">
                        <img className="Navbar-logo" src={logo} alt="IMASS Logo" />
                        <span className="Navbar-title">IMASS</span>
                    </header>
                <Link className="nav-link" to="/">Home</Link>
                <Link className="nav-link" to="/fasst">FASST</Link>
                </div>
                <div className="login-signup-container">
                    <Link className="nav-link-loginsignup" to="/login">Login</Link>
                    <div className="separator" />
                    <Link className="nav-link-loginsignup" to="/signup">Sign up</Link>
                </div>
            </nav>
        </div>
    );
}

export default Navbar;