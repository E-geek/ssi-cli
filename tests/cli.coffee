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

resourcesStack = []

pushResource = (name, content) ->
  pathWay = path.join(__dirname, 'resources', name)
  resourcesStack.push pathWay
  tryCmd -> fs.writeFileSync pathWay, content
  return

describe 'test cli ssi', ->
  exec = ''
  templateArgv = ['-d', path.join(__dirname, 'resources'), 'test']

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
      ssi = child.spawn exec, argv
      ssi.on 'close', (code) ->
        assert.equal code, 1
        done()
    it 'data-path unknown type', (done) ->
      argv = templateArgv.slice(0)
      argv.push '-p', '-i', path.join __dirname, 'resources', 'end.ssi'
      ssi = child.spawn exec, argv
      ssi.on 'close', (code) ->
        assert.equal code, 2
        done()
    it 'incorrect object', (done) ->
      argv = templateArgv.slice(0)
      argv.push '-p', '-o', '{}}'
      ssi = child.spawn exec, argv
      ssi.on 'close', (code) ->
        assert.equal code, 3
        done()
    it 'fail parse ssi', (done) ->
      argv = templateArgv.slice(0)
      argv[2] = 'test_i'
      argv.push '-p'
      ssi = child.spawn exec, argv
      ssi.on 'close', (code) ->
        assert.equal code, 4
        done()
    it 'no -p, no output', (done) ->
      argv = templateArgv.slice(0)
      ssi = child.spawn exec, argv
      ssi.on 'close', (code) ->
        assert.equal code, 5
        done()
  describe 'behavior', ->
    it '-p', (done) ->
      argv = templateArgv.slice(0)
      argv.push '-p'
      ssi = child.spawn exec, argv
      buffer = ''
      ssi.stdout.on 'data', (data) -> buffer += data.toString()
      ssi.on 'close', (code) ->
        assert.equal code, 0
        assert.equal buffer, 'NyaaC'
        done()
    it '-p test_o -o {o:1}', (done) ->
      argv = templateArgv.slice(0)
      argv[2] = 'test_o'
      argv.push '-p', '-o', '{"o":1}'
      ssi = child.spawn exec, argv
      buffer = ''
      ssi.stdout.on 'data', (data) -> buffer += data.toString()
      ssi.on 'close', (code) ->
        assert.equal code, 0
        assert.equal buffer, 'NyaaC1'
        done()
    it '-p test_o -i resources/data.json', (done) ->
      argv = templateArgv.slice(0)
      argv[2] = 'test_o'
      jsonPath = path.join __dirname, 'resources', 'data.json'
      argv.push '-p', '-i', jsonPath
      ssi = child.spawn exec, argv
      buffer = ''
      ssi.stdout.on 'data', (data) -> buffer += data.toString()
      ssi.on 'close', (code) ->
        assert.equal code, 0
        assert.equal buffer, 'NyaaC1'
        done()
    it '-p test_o -i resources/data.cson', (done) ->
      argv = templateArgv.slice(0)
      argv[2] = 'test_o'
      jsonPath = path.join __dirname, 'resources', 'data.cson'
      argv.push '-p', '-i', jsonPath
      ssi = child.spawn exec, argv
      buffer = ''
      ssi.stdout.on 'data', (data) -> buffer += data.toString()
      ssi.on 'close', (code) ->
        assert.equal code, 0
        assert.equal buffer, 'NyaaC1'
        done()
    it 'test_o -o {o:1}', (done) ->
      argv = templateArgv.slice(0)
      argv[2] = 'test_o'
      out = path.join __dirname, 'resources', 'out'
      argv.push out, '-o', '{"o":1}'
      ssi = child.spawn exec, argv
      ssi.on 'close', (code) ->
        assert.equal code, 0
        assert.equal fs.readFileSync(out).toString(), 'NyaaC1'
        done()
    it '-p test_o -i resources/data.json', (done) ->
      argv = templateArgv.slice(0)
      argv[2] = 'test_o'
      out = path.join __dirname, 'resources', 'out'
      jsonPath = path.join __dirname, 'resources', 'data.json'
      argv.push out, '-i', jsonPath
      ssi = child.spawn exec, argv
      ssi.on 'close', (code) ->
        assert.equal code, 0
        assert.equal fs.readFileSync(out).toString(), 'NyaaC1'
        done()
    it '-p test_o -i resources/data.cson', (done) ->
      argv = templateArgv.slice(0)
      argv[2] = 'test_o'
      out = path.join __dirname, 'resources', 'out'
      jsonPath = path.join __dirname, 'resources', 'data.cson'
      argv.push out, '-i', jsonPath
      ssi = child.spawn exec, argv
      ssi.on 'close', (code) ->
        assert.equal code, 0
        assert.equal fs.readFileSync(out).toString(), 'NyaaC1'
        done()

