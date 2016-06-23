SSI       = require 'node-ssi'
optimist  = require 'optimist'
CSON      = require 'cson'
fs        = require 'fs'
globalProcess = process

bin = (process) ->
  #console.log process.argv
  ### istanbul ignore if ###
  if process.argv is globalProcess.argv
    return run globalProcess

  {argv, stdin, stdout, stderr, exit} = globalProcess
  globalProcess.argv    = process.argv
  globalProcess.stdin   = process.stdin
  globalProcess.stdout  = process.stdout
  globalProcess.stderr  = process.stderr
  globalProcess.exit    = process.exit
  delete require.cache[require.resolve('optimist')]
  optimist  = require 'optimist'
  globalProcess.nextTick ->
    run process
    globalProcess.argv    = argv
    globalProcess.stdin   = stdin
    globalProcess.stdout  = stdout
    globalProcess.stderr  = stderr
    globalProcess.exit    = exit
  return

run = (process) ->

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

  #console.dir argv

  if argv.h
    process.stdout.write [optimist.help(),
              '\n\n`data-path` has higher priority then `object`', ''].join '\n'
    process.exit()

  if not argv.p and argv._.length is 1
    optimist
    .usage "Usage: ssi #{argv._[0]} path/to/output"
    .demand 2
    process.stdout.write optimist.help() + '\n'
    process.exit 5
    return

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
        dataObject = CSON.parseJSONFile dataPath
      else if isCSON.test dataPath
        dataObject = CSON.parseCSONFile dataPath
      else
        process.stderr.write "`data-path` have unknown data type\n"
        process.exit 2
    else
      process.stderr.write "`data-path` is not valid!\n"
      process.exit 1
  else
    if dataObject?
      try
        dataObject = JSON.parse dataObject
      catch e
        process.stderr.write ['`object` parse error!', e.toString(), ''].join '\n'
        process.exit 3
    else
      dataObject = {}

  ssi = new SSI
    baseDir: rootPath
    encoding: 'utf-8'
    payload: dataObject
  ssi.compile """<!--# include file="#{argv._[0]}" -->""",  (err, cnt) ->
    if err?
      process.stderr.write ['Parse file error:', err.toString(), ''].join "\n"
      process.exit 4
      return
    if print
      process.stdout.write cnt.toString()
    else
      fs.writeFileSync argv._[1], cnt.toString()
    process.exit 0
    return true

module.exports = bin