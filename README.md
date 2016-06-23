# ssi-cli
[![Build Status](https://travis-ci.org/E-geek/ssi-cli.svg?branch=master)](https://travis-ci.org/E-geek/ssi-cli)
[![Coverage Status](https://coveralls.io/repos/github/E-geek/ssi-cli/badge.svg?branch=master)](https://coveralls.io/github/E-geek/ssi-cli?branch=master)

> The command line tool to build files with SSI directives.

## Installation

```bash
    $ npm install -g ssi-cli 
```
For test go to module directory and run
```bash
    $ npm test
```

## Usage

With output file:
```bash
ssi path/to/filename path/to/output
```
Print to console:
```bash
ssi -p path/to/filename  
```

### Example
Structure:
```
+usage_dir
|--root.ssi
|-+resources/
  |--resource.ssi
  |--other.ssi
```
For example `root.ssi` include `/resources/resource.ssi` and you want print output. Then run example:
 
```bash
ssi -p -d usage_dir root.ssi
```

Path to the file has root dir ./ by default. You can change the root directory, 
and then path to the file it should ask for a new path. (`-d` or `--data-path` 
directive)

If you want to use an object with parameters to building files then you can use 
the object directly in the command line in the parameter object 
(`-o` or `--object`) or by specifying the path (`-i` or `--data-path`) to the 
file containing the object. Accept JSON and CSON formats.

## Result call help:
```bash
Options:
  -d, --root-path  Root path for include directory     [default: "./"]
  -o, --object     Data in JSON format                 [default: "{}"]
  -i, --data-path  Path to data object file. JSON or CSON file type
                   allowed. `data-path` has higher priority then
                   `object`                                           
  -p, --print      Print output                                       
  -h, --help       This help
```