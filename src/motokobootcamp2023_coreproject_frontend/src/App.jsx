import 'bootstrap/dist/css/bootstrap.min.css';
import * as React from 'react';
import { useState, useEffect } from 'react';
import { Route, Routes } from 'react-router-dom';

import Header from "./components/Header";
import FrontPage from "./pages/FrontPage";
import SubmitPage from "./pages/SubmitPage";


const App = () => {

    const [loggedInUser, setLoggedInUser] = useState();
    const whitelist = ["xyfu2-4yaaa-aaaak-aeaaa-cai"];


    useEffect(() => {
        verifyConnection();
    }, []);


    const explicitConnect = async () => {
        const connection = await window.ic.plug.requestConnect(whitelist[0]);
        setLoggedInUser(window.ic.plug.sessionManager.sessionData);
    };

    const verifyConnection = async () => {
        const connected = await window.ic.plug.isConnected();
        if (!connected) {
            await window.ic.plug.requestConnect(whitelist[0]);
        } else {
            setLoggedInUser(window.ic.plug.sessionManager.sessionData.principalId);
        };
    };
      

  
    return (
        <>
            <Header callbackConnect={explicitConnect}></Header>
            <Routes>
                <Route exact path="/" element={<FrontPage whitelist={whitelist}/>}></Route>
                <Route exact path="/submit" element={<SubmitPage whitelist={whitelist}/>}></Route>
            </Routes>
        </>
    )
};


export default App;