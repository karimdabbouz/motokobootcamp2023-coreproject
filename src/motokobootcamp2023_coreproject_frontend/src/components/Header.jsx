import * as React from 'react';
import { Nav, Navbar } from 'react-bootstrap';
import { Link } from 'react-router-dom';
import 'bootstrap/dist/js/bootstrap.bundle';


const Header = ({callbackConnect}) => {

    return (
        <header>
            <Navbar expand="lg" className="fixed-top p-2" style={{backgroundColor: "#00C9A7"}}>
                <Navbar.Brand><h2><strong><a href="./" style={{textDecoration: "none"}}>newsDAO_3000</a></strong></h2></Navbar.Brand>
                <Navbar.Toggle className="menu-button" aria-controls="basic-navbar-nav"></Navbar.Toggle>
                <Navbar.Collapse id="basic-navbar-nav" className="justify-content-end">
                    <Nav>
                        <Link to={'./submit'} className="nav-link">Submit a Proposal</Link>
                        <Nav.Link className="bg-dark" onClick={callbackConnect}><strong>Connect</strong></Nav.Link>
                    </Nav>
                </Navbar.Collapse>
            </Navbar>
        </header>
    )
};

export default Header;