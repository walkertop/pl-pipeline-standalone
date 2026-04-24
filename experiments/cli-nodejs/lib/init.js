// pl init [--adapter <id>]
"use strict";

const fs = require("fs");
const path = require("path");
const { getPLHome, runScript, die } = require("./utils");

module.exports = function init(_cmd, args) {
  const plHome = getPLHome();
  const projectRoot = process.cwd();

  // Parse --adapter option
  let adapterId = null;
  const adapterIdx = args.indexOf("--adapter");
  if (adapterIdx !== -1) {
    adapterId = args[adapterIdx + 1];
    if (!adapterId) die("--adapter requires an adapter id (e.g. nextjs-web, kotlin)");
  }

  console.log(`▶ pl init @ ${projectRoot}`);

  // 1. Create directories
  const dirs = [
    "pl", "pl/changes",
    ".codebuddy", ".codebuddy/agents", ".codebuddy/skills", ".codebuddy/rules",
    "scripts", "pipeline-output/trace",
  ];
  for (const d of dirs) {
    const full = path.join(projectRoot, d);
    if (!fs.existsSync(full)) {
      fs.mkdirSync(full, { recursive: true });
      console.log(`  ✅ mkdir ${d}/`);
    }
  }

  // 2. Copy config.default.yaml → pl/config.yaml
  const configSrc = path.join(plHome, "assets", "pl", "config.default.yaml");
  const configDst = path.join(projectRoot, "pl", "config.yaml");
  if (!fs.existsSync(configDst)) {
    fs.copyFileSync(configSrc, configDst);
    console.log(`  ✅ pl/config.yaml`);
  } else {
    console.log(`  ⏭  pl/config.yaml (already exists)`);
  }

  console.log(`\n✅ pl-pipeline initialized`);

  // 3. Auto-install adapter if specified
  if (adapterId) {
    console.log(`\n▶ Installing adapter: ${adapterId}`);
    const adapterDir = path.join(plHome, "adapters", `adapter-${adapterId}`);
    if (!fs.existsSync(adapterDir)) {
      die(`Adapter not found: adapter-${adapterId}\n   Available: ${listAdapters(plHome).join(", ")}`);
    }
    runScript("adapter-install.sh", [adapterDir, projectRoot]);
  }

  // 4. Next steps
  console.log(`
📋 Next steps:
   1. Install an adapter:  pl adapter nextjs-web
   2. Create a change:     pl new my-feature --name "My Feature"
   3. Start working:       pl start SPEC
  `);
};

function listAdapters(plHome) {
  const dir = path.join(plHome, "adapters");
  if (!fs.existsSync(dir)) return [];
  return fs.readdirSync(dir, { withFileTypes: true })
    .filter(d => d.isDirectory() && d.name.startsWith("adapter-"))
    .map(d => d.name.replace("adapter-", ""));
}
