// pl new <change-id> [--name <name>] [--domain <domain>] [--complexity <l|m|h>]
"use strict";

const { runScript, die } = require("./utils");

module.exports = function newChange(_cmd, args) {
  if (!args[0]) die("Usage: pl new <change-id> [--name <name>] [--domain <d>] [--complexity <l|m|h>]");
  runScript("pl-state-init.sh", args);
};
