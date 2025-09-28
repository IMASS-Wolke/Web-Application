import { Link } from 'react-router-dom';
import './Navbar.css';
import logo from "../../assets/icons/cloud.svg";

function Navbar() {

    return (
        <div className="nav-container">
            <nav className="navbar">
                <header className="Navbar-title-container">
                    <img className="Navbar-logo" src={logo} alt="IMASS Logo" />
                    <span className="Navbar-title">IMASS</span>
                </header>
                <Link className="nav-link" to="/">Home</Link>
                <Link className="nav-link" to="/login">Login</Link>
                <Link className="nav-link" to="/signup">Sign up</Link>
                <Link className="nav-link" to="/faast">FAAST</Link>
            </nav>
        </div>
    );
}

export default Navbar;