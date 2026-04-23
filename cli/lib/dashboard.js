// pl dashboard [--port N]
"use strict";

const { runScript } = require("./utils");

module.exports = function dashboard(_cmd, args) {
  const scriptArgs = ["--project", process.cwd()];

  const portIdx = args.indexOf("--port");
  if (portIdx !== -1 && args[portIdx + 1]) {
    scriptArgs.push("--port", args[portIdx + 1]);
  }

  if (args.includes("--open")) scriptArgs.push("--open");
  if (args.includes("--static-only")) scriptArgs.push("--static-only");

  runScript("pl-dashboard.sh", scriptArgs);
};
