/* istanbul ignore if */
if (!('.coffee' in require.extensions)) {
  require('coffee-script/register');
}

"use strict";

var bin = require("./ssi.coffee");

bin({
  stdin:  process.stdin,
  stdout: process.stdout,
  stderr: process.stderr,
  argv: process.argv,
  exit: function (code) {
    if (code == null) {
      code = 0;
    }
    process.exit(code);
  }
});