import { useLocation } from "react-router-dom";
import Navbar from "../Navbar/Navbar.js";

function Layout({ children }) {
    const location = useLocation();

    const hideNavbar = location.pathname === "/login" || location.pathname === "/signup";

    return (
        <>
            {!hideNavbar && <Navbar />}
            <main>{ children }</main>
        </>
    );
}

export default Layout;