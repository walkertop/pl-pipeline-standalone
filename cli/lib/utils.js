// =============================================================================
// utils.js — shared helpers for pl CLI
// =============================================================================

"use strict";

const { execSync } = require("child_process");
const path = require("path");
const fs = require("fs");

/**
 * Resolve PL_HOME: env var > cli package root (../../ from cli/lib/)
 */
function getPLHome() {
  if (process.env.PL_HOME) return process.env.PL_HOME;
  // cli/ lives inside pl-pipeline-standalone/cli/
  const plHome = path.resolve(__dirname, "..", "..");
  if (!fs.existsSync(path.join(plHome, "scripts"))) {
    die(`Cannot find pl-pipeline scripts. Set PL_HOME or install pl-pipeline globally.`);
  }
  process.env.PL_HOME = plHome;
  return plHome;
}

/**
 * Run a bash script from $PL_HOME/scripts/
 */
function runScript(scriptName, args = []) {
  const plHome = getPLHome();
  const script = path.join(plHome, "scripts", scriptName);
  if (!fs.existsSync(script)) {
    die(`Script not found: ${script}`);
  }
  const cmd = `bash "${script}" ${args.map(a => `"${a}"`).join(" ")}`;
  try {
    execSync(cmd, { stdio: "inherit", cwd: process.cwd(), env: { ...process.env, PL_HOME: plHome } });
  } catch (e) {
    process.exit(e.status || 1);
  }
}

/**
 * Find the active (non-ARCHIVE) change in pl/changes/
 */
function findActiveChange() {
  const changesDir = path.join(process.cwd(), "pl", "changes");
  if (!fs.existsSync(changesDir)) return null;

  const dirs = fs.readdirSync(changesDir, { withFileTypes: true })
    .filter(d => d.isDirectory())
    .map(d => d.name);

  // Find last change that is NOT in ARCHIVE stage
  for (let i = dirs.length - 1; i >= 0; i--) {
    const stateFile = path.join(changesDir, dirs[i], ".state.md");
    if (fs.existsSync(stateFile)) {
      const content = fs.readFileSync(stateFile, "utf-8");
      if (!content.includes("stage: ARCHIVE")) {
        return dirs[i];
      }
    }
  }

  // If all are archived, return the last one
  return dirs.length > 0 ? dirs[dirs.length - 1] : null;
}

function die(msg) {
  console.error(`❌ ${msg}`);
  process.exit(1);
}

function printHelp(commands) {
  console.log(`
  pl-pipeline CLI v0.1.0

  Usage: pl <command> [options]

  Commands:`);
  for (const [name, info] of Object.entries(commands)) {
    console.log(`    ${name.padEnd(12)} ${info.desc}`);
  }
  console.log(`
  Examples:
    pl init                    Initialize pl in current project
    pl init --adapter nextjs   Init + install adapter in one step
    pl adapter kotlin          Install adapter-kotlin
    pl new my-feature          Create a new change
    pl start SPEC              Start SPEC phase
    pl end SPEC pass           End SPEC phase with result
    pl gate A0 pass            Record gate evaluation
    pl task start T01          Start task T01
    pl task end T01            End task T01
    pl check tsc pass          Record check result
    pl artifact create x.ts    Record artifact
    pl done                    Mark workflow complete
    pl verify                  Run observability check
    pl status                  Show trace summary
    pl dashboard               Start Dashboard on port 8889
    pl dashboard --port 9000   Custom port
  `);
}

module.exports = { getPLHome, runScript, findActiveChange, die, printHelp };
