// pl start <PHASE>
// pl end <PHASE> [result]
// pl gate <GATE> <result>
// pl task <start|end> <TASK_ID> [result]
// pl check <name> <result> [detail]
// pl artifact <create|update> <path>
// pl done
"use strict";

const { runScript, findActiveChange, die } = require("./utils");

module.exports = function phase(cmd, args) {
  // For all phase commands, we need the active change
  const changeId = findActiveChange();
  if (!changeId) die("No active change found. Run: pl new <change-id>");

  switch (cmd) {
    case "start":
      if (!args[0]) die("Usage: pl start <PHASE>");
      runScript("pl-phase.sh", [changeId, "start", ...args]);
      break;

    case "end":
      if (!args[0]) die("Usage: pl end <PHASE> [result=pass]");
      if (!args[1]) args.push("pass"); // default result
      runScript("pl-phase.sh", [changeId, "end", ...args]);
      break;

    case "gate":
      if (!args[0] || !args[1]) die("Usage: pl gate <GATE> <pass|fail>");
      runScript("pl-phase.sh", [changeId, "gate", ...args]);
      break;

    case "task":
      if (!args[0] || !args[1]) die("Usage: pl task <start|end> <TASK_ID>");
      runScript("pl-phase.sh", [changeId, "task", ...args]);
      break;

    case "check":
      if (!args[0] || !args[1]) die("Usage: pl check <name> <pass|fail> [detail]");
      runScript("pl-phase.sh", [changeId, "check", ...args]);
      break;

    case "artifact":
      if (!args[0] || !args[1]) die("Usage: pl artifact <create|update> <path>");
      runScript("pl-phase.sh", [changeId, "artifact", ...args]);
      break;

    case "done":
      runScript("pl-phase.sh", [changeId, "done"]);
      break;

    default:
      die(`Unknown phase command: ${cmd}`);
  }
};
