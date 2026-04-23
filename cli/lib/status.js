// pl status [change-id]
"use strict";

const { runScript, findActiveChange } = require("./utils");

module.exports = function status(_cmd, args) {
  const changeId = args[0] || findActiveChange();
  if (changeId) {
    runScript("pl-phase.sh", [changeId, "status"]);
  } else {
    runScript("pl-status.sh", []);
  }
};
