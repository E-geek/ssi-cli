stream = require 'mock-utf8-stream'
child = require 'child_process'
path = require 'path'
fs = require 'fs'

concat = require 'concat-stream'
{assert} = require 'chai'

tryCmd = (fn) ->
  try
    fn()
  catch e
    if e.code isnt 'EEXIST'
      throw e

glbErr = new stream.MockWritableStream()
emulateCli = (argv, onExitCb) ->
  bin = require '../lib/ssi.coffee'
  stdout = new stream.MockWritableStream()
  stderr = new stream.MockWritableStream()
  stdin = process.stdin
  exit = (code = 0) ->
    onExitCb code
    return
  process.nextTick ->
    bin {stdout, stderr, stdin, argv, exit}
    return
  return {stdout, stderr}

resourcesStack = []

pushResource = (name, content) ->
  pathWay = path.join(__dirname, 'resources', name)
  resourcesStack.push pathWay
  tryCmd -> fs.writeFileSync pathWay, content
  return

describe 'test emulate ssi', ->
  exec = ''
  templateArgv = ['node', 'ssi','-d', path.join(__dirname, 'resources'), 'test']

  before ->
    exec = path.join __dirname, '..', 'bin', 'ssi'

    tryCmd -> fs.mkdirSync path.join __dirname, 'resources'
    pushResource 'test', """N<!--# include file="end.ssi" -->C"""
    pushResource 'test_o', """N<!--# include file="end.ssi" -->C<!--# echo var="o" default="default" -->"""
    pushResource 'test_i', """<!--# include file="fail.ssi" -->"""
    pushResource 'end.ssi', """yaa"""
    pushResource 'data.json', """{"o":1}"""
    pushResource 'data.cson', """o: 1"""
    pushResource 'out', ''
    #process.exit()
    return
  after ->
    for pathWay in resourcesStack
      fs.unlinkSync pathWay
    fs.rmdirSync path.join __dirname, 'resources'
    return

  describe 'errors', ->
    it 'data-path not valid', (done) ->
      argv = templateArgv.slice(0)
      argv.push '-p', '-i', 'noPath'
      emulateCli argv, (code) ->
        assert.equal code, 1
        done()

    it 'data-path unknown type', (done) ->
      argv = templateArgv.slice(0)
      argv.push '-p', '-i', path.join __dirname, 'resources', 'end.ssi'
      emulateCli argv, (code) ->
        assert.equal code, 2
        done()

    it 'incorrect object', (done) ->
      argv = templateArgv.slice(0)
      argv.push '-p', '-o', '{}}'
      emulateCli argv, (code) ->
        assert.equal code, 3
        done()
    it 'fail parse ssi', (done) ->
      argv = templateArgv.slice(0)
      argv[2] = 'test_i'
      argv.push '-p'
      emulateCli argv, (code) ->
        assert.equal code, 4
        done()
    it 'no -p, no output', (done) ->
      argv = templateArgv.slice(0)
      emulateCli argv, (code) ->
        assert.equal code, 5
        done()
  describe 'behavior', ->
    it '-p', (done) ->
      argv = templateArgv.slice(0)
      argv.push '-p'
      buffer = ''
      err = ''
      {stdout, stderr} = emulateCli argv, (code) ->
        assert.equal code, 0
        assert.equal buffer, 'NyaaC'
        assert.lengthOf err, 0
        done()
      stdout.on 'data', (data) -> buffer += data.toString()
      stderr.on 'data', (data) -> err += data.toString()
    it '-p test_o -o {o:1}', (done) ->
      argv = templateArgv.slice(0)
      argv[4] = 'test_o'
      argv.push '-p', '-o', '{"o":1}'

      buffer = ''
      err = ''
      {stdout, stderr} = emulateCli argv, (code) ->
        assert.equal code, 0
        assert.equal buffer, 'NyaaC1'
        assert.lengthOf err, 0
        done()
      stdout.on 'data', (data) -> buffer += data.toString()
      stderr.on 'data', (data) -> err += data.toString()
    it '-p test_o -i resources/data.json', (done) ->
      argv = templateArgv.slice(0)
      argv[4] = 'test_o'
      jsonPath = path.join __dirname, 'resources', 'data.json'
      argv.push '-p', '-i', jsonPath

      buffer = ''
      err = ''
      {stdout, stderr} = emulateCli argv, (code) ->
        assert.equal code, 0
        assert.equal buffer, 'NyaaC1'
        assert.lengthOf err, 0
        done()
      stdout.on 'data', (data) -> buffer += data.toString()
      stderr.on 'data', (data) -> err += data.toString()
    it '-p test_o -i resources/data.cson', (done) ->
      argv = templateArgv.slice(0)
      argv[4] = 'test_o'
      jsonPath = path.join __dirname, 'resources', 'data.cson'
      argv.push '-p', '-i', jsonPath

      buffer = ''
      err = ''
      {stdout, stderr} = emulateCli argv, (code) ->
        assert.equal code, 0
        assert.equal buffer, 'NyaaC1'
        assert.lengthOf err, 0
        done()
      stdout.on 'data', (data) -> buffer += data.toString()
      stderr.on 'data', (data) -> err += data.toString()
    it 'test_o -o {o:1}', (done) ->
      argv = templateArgv.slice(0)
      argv[4] = 'test_o'
      out = path.join __dirname, 'resources', 'out'
      argv.push out, '-o', '{"o":1}'

      buffer = ''
      err = ''
      {stdout, stderr} = emulateCli argv, (code) ->
        assert.equal code, 0
        assert.equal fs.readFileSync(out).toString(), 'NyaaC1'
        assert.lengthOf err, 0
        assert.lengthOf buffer.trim(), 0
        done()
      stdout.on 'data', (data) -> buffer += data.toString()
      stderr.on 'data', (data) -> err += data.toString()
    it '-p test_o -i resources/data.json', (done) ->
      argv = templateArgv.slice(0)
      argv[4] = 'test_o'
      out = path.join __dirname, 'resources', 'out'
      jsonPath = path.join __dirname, 'resources', 'data.json'
      argv.push out, '-i', jsonPath

      buffer = ''
      err = ''
      {stdout, stderr} = emulateCli argv, (code) ->
        assert.equal code, 0
        assert.equal fs.readFileSync(out).toString(), 'NyaaC1'
        assert.lengthOf err, 0
        assert.lengthOf buffer.trim(), 0
        done()
      stdout.on 'data', (data) -> buffer += data.toString()
      stderr.on 'data', (data) -> err += data.toString()
    it '-p test_o -i resources/data.cson', (done) ->
      argv = templateArgv.slice(0)
      argv[4] = 'test_o'
      out = path.join __dirname, 'resources', 'out'
      jsonPath = path.join __dirname, 'resources', 'data.cson'
      argv.push out, '-i', jsonPath

      buffer = ''
      err = ''
      {stdout, stderr} = emulateCli argv, (code) ->
        assert.equal code, 0
        assert.equal fs.readFileSync(out).toString(), 'NyaaC1'
        assert.lengthOf err, 0
        #assert.lengthOf buffer.trim(), 0
        done()
      stdout.on 'data', (data) -> buffer += data.toString()
      stderr.on 'data', (data) -> err += data.toString()

