#!/usr/bin/env node
const fs = require('fs')
const program = require('commander')

program
  .version('0.1.0')
  .usage('[options] -c <file1>,<file2>')
  .option('-c, --compareFiles <files>', 'Compare two json log files', val =>
    val.split(',')
  )
  .option(
    '-i, --ignoreProps [properties]',
    'Properties to ignore',
    val => val.split(','),
    []
  )
  .parse(process.argv)

program.ignoreProps.length &&
  console.log('Ignoring properties:', program.ignoreProps.join(', '))
program.compareFiles.length &&
  console.log('Comparing files:', program.compareFiles.join(', '))
// parse JSON from each line in each file
const results = program.compareFiles.map(filename =>
  fs
    .readFileSync(filename, 'utf8') // read contents of each passed filename
    .split('\n') // split each line
    .map(str => str.trim()) // trim whitespace
    .filter(str => str.length) // not empty
    .filter(str => /^\{.*\}$/.test(str)) // starts with '{' and ends with '}'
    .map(JSON.parse)
)

// diff json
const jsondiffpatch = require('jsondiffpatch').create({
  propertyFilter: name => !program.ignoreProps.includes(name)
})
const formatters = require('jsondiffpatch/src/formatters')

const file1 = results[0]
const file2 = results[1]
const delta = jsondiffpatch.diff(file1, file2)
const output = formatters.console.format(delta)
if (output.length) {
  process.stderr.write(output + '\n')
  process.exit(1)
} else {
  console.log(`${program.compareFiles.join(' and ')} are identitcal`)
  process.exit(0)
}
