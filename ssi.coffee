SSI = require 'node-ssi'
optimist = require 'optimist'

o = optimist
.string 'd'
.alias 'd', 'root-path'
.describe 'd', 'Root path for include directory'
.boolean 'p'
.alias 'p', 'print'
.describe 'p', 'Print output'
.boolean 'h'
.alias 'h', 'help'
.describe 'h', 'This help'
.argv

if o.h
  console.log optimist.help()
else
  console.log o