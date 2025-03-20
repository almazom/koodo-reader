import React from "react";
import ReactDOM from "react-dom";
import "./assets/styles/reset.css";
import "./assets/styles/global.css";
import "./assets/styles/style.css";
import { Provider } from "react-redux";
import "./i18n";
import store from "./store";
import Router from "./router/index";
import StyleUtil from "./utils/reader/styleUtil";
import { initSystemFont, initTheme } from "./utils/reader/launchUtil";
import * as serviceWorkerRegistration from './serviceWorkerRegistration';

initTheme();
initSystemFont();
ReactDOM.render(
  <Provider store={store}>
    <Router />
  </Provider>,
  document.getElementById("root")
);
StyleUtil.applyTheme();

// If you want your app to work offline and load faster, you can change
// unregister() to register() below.
serviceWorkerRegistration.register();
