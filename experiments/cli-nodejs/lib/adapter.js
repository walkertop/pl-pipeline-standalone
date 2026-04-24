// pl adapter <id>
"use strict";

const fs = require("fs");
const path = require("path");
const { getPLHome, runScript, die } = require("./utils");

module.exports = function adapter(_cmd, args) {
  const adapterId = args[0];
  if (!adapterId) die("Usage: pl adapter <id>  (e.g. nextjs-web, kotlin, python-fastapi)");

  const plHome = getPLHome();
  const adapterDir = path.join(plHome, "adapters", `adapter-${adapterId}`);

  if (!fs.existsSync(adapterDir)) {
    const available = listAdapters(plHome);
    die(`Adapter not found: adapter-${adapterId}\n   Available: ${available.join(", ")}`);
  }

  runScript("adapter-install.sh", [adapterDir, process.cwd()]);
};

function listAdapters(plHome) {
  const dir = path.join(plHome, "adapters");
  if (!fs.existsSync(dir)) return [];
  return fs.readdirSync(dir, { withFileTypes: true })
    .filter(d => d.isDirectory() && d.name.startsWith("adapter-"))
    .map(d => d.name.replace("adapter-", ""));
}
