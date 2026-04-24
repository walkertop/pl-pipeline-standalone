// pl verify [change-id]
"use strict";

const { runScript, findActiveChange } = require("./utils");

module.exports = function verify(_cmd, args) {
  const changeId = args[0] || findActiveChange();
  const scriptArgs = changeId ? [changeId] : [];
  runScript("pl-observe-check.sh", scriptArgs);
};
