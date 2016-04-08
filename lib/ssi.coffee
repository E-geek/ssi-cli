SSI       = require 'node-ssi'
optimist  = require 'optimist'
CSON      = require 'cson'
fs        = require 'fs'

argv = optimist
.usage 'Usage: ssi path/to/filename.type'
.demand 1

.string   'd'
.alias    'd', 'root-path'
.default  'd', './'
.describe 'd', 'Root path for include directory'

.string   'o'
.alias    'o', 'object'
.default  'o', '{}'
.describe 'o', 'Data in JSON format'

.string   'i'
.alias    'i', 'data-path'
.describe 'i', 'Path to data object file. JSON or CSON file type allowed. `data-path` has higher priority then `object`'

.boolean  'p'
.alias    'p', 'print'
.describe 'p', 'Print output'

.boolean  'h'
.alias    'h', 'help'
.describe 'h', 'This help'
.wrap(70)
.argv

if argv.h
  console.log optimist.help(), '\n\n`data-path` has higher priority then `object`'
  process.exit()

if not argv.p and argv._.length is 1
  optimist
  .usage "Usage: ssi #{argv._[0]} path/to/output"
  .demand 2
  console.log optimist.help()
  process.exit(5)

rootPath = argv['root-path']
print = argv['print']
dataObject = argv['object']
dataPath = argv['data-path']

isJSON = /.json$/i
isCSON = /.cson$/i

if dataPath?
  dataPath = dataPath.trim()
  if fs.existsSync dataPath
    if isJSON.test dataPath
      dataObject = require dataPath
    else if isCSON.test dataPath
      dataObject = CSON.parseCSONFile dataPath
    else
      console.log '`data-path` have unknown data type'
      process.exit 2
  else
    console.log '`data-path` is not valid!'
    process.exit 1
else
  if dataObject?
    try
      dataObject = JSON.parse dataObject
    catch e
      console.log '`object` parse error!', e
      process.exit 3
  else
    dataObject = {}

ssi = new SSI
  baseDir: rootPath
  encoding: 'utf-8'
  payload: dataObject

ssi.compile """<!--# include file="#{argv._[0]}" -->""",  (err, cnt) ->
  if err?
    console.log 'Parse file error:', err
    process.exit 4
    return
  if print
    process.stdout.write cnt.toString()
  else
    fs.writeFileSync argv._[1], cnt.toString()
  return true