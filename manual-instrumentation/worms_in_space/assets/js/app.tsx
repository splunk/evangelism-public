import "../css/app.css";
import React from "react";
import { createRoot } from "react-dom/client";
import WormsInSpace from "./WormsInSpace";
import { initializeRUM } from "./rum";

// Initialize Splunk RUM
initializeRUM();

document.addEventListener("DOMContentLoaded", () => {
    const container = document.getElementById("WormsInSpace")
    if (!container) return;
    const root = createRoot(container);
    root.render(<WormsInSpace />);
})