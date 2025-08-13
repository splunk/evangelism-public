import "../css/app.css";
import React from "react";
import { createRoot } from "react-dom/client";
import WormsInSpace from "./WormsInSpace";

document.addEventListener("DOMContentLoaded", () => {
    const container = document.getElementById("WormsInSpace")
    if (!container) return;
    const root = createRoot(container);
    root.render(<WormsInSpace />);
})