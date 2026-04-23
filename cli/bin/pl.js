#!/usr/bin/env node
// =============================================================================
// pl — pl-pipeline CLI entry point
// =============================================================================
// Thin wrapper: parses subcommand, delegates to lib/*.js which call bash scripts.
// No third-party dependencies. Works in any terminal (VS Code, Claude Code, iTerm).
// =============================================================================

"use strict";

const path = require("path");
const { getPLHome, die, printHelp } = require("../lib/utils");

const COMMANDS = {
  init:      { mod: "../lib/init",      desc: "Initialize pl-pipeline in current project" },
  adapter:   { mod: "../lib/adapter",   desc: "Install a stack adapter" },
  new:       { mod: "../lib/new",       desc: "Create a new change" },
  start:     { mod: "../lib/phase",     desc: "Start a pipeline phase" },
  end:       { mod: "../lib/phase",     desc: "End a pipeline phase" },
  gate:      { mod: "../lib/phase",     desc: "Record gate evaluation" },
  task:      { mod: "../lib/phase",     desc: "Record task start/end" },
  check:     { mod: "../lib/phase",     desc: "Record check result" },
  artifact:  { mod: "../lib/phase",     desc: "Record artifact create/update" },
  done:      { mod: "../lib/phase",     desc: "Mark workflow completed" },
  verify:    { mod: "../lib/verify",    desc: "Run observability check" },
  status:    { mod: "../lib/status",    desc: "Show trace summary" },
  dashboard: { mod: "../lib/dashboard", desc: "Start Dashboard server" },
};

// ── main ─────────────────────────────────────────────────────
function main() {
  const args = process.argv.slice(2);
  const cmd = args[0];

  if (!cmd || cmd === "--help" || cmd === "-h") {
    printHelp(COMMANDS);
    process.exit(0);
  }

  if (!COMMANDS[cmd]) {
    console.error(`❌ Unknown command: ${cmd}`);
    console.error(`   Run "pl --help" for available commands.`);
    process.exit(1);
  }

  // Ensure PL_HOME is resolvable
  getPLHome();

  // Delegate
  const handler = require(COMMANDS[cmd].mod);
  handler(cmd, args.slice(1));
}

main();
