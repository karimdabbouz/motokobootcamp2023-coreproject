import 'bootstrap/dist/css/bootstrap.min.css';
import * as React from 'react';
import { render } from 'react-dom';
import { HashRouter } from 'react-router-dom';

import App from './App';


render(
  <HashRouter>
    <App />
  </HashRouter>, 
document.getElementById("app"));