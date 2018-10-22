# logstash-test-runner

![image](http://i.imgur.com/hQm9yAb.gif)

Example tests are in the `__tests__` directory.
To add a tests, simply add a new directory with the given input `input.log`, the ETL configuration `logstash.conf`, and the expected output `output.log`.

## Prerequisites

* NodeJS > v8
* Docker
* Bash > v4

## Setup

* Clone repository
* Run `npm install`
* Setup your test directory as follows

```sh
__tests__
  crawlers
    input.log
    logstash.conf
    output.log
  mongo
    input.log
    logstash.conf
    output.log
  # ...
```

* Make sure docker is running
* Run your tests

```sh
# ./test.sh <test-parent-directory> [<logstash-docker-image>]

# Run tests using the official Logstash 5.5.1 docker image
./test.sh __tests__

# Run tests using a locally built logstash docker image
./test.sh __tests__ my_logstash_image
```

NOTE: Multiline logs in logstash need translate in reverse to filebeat in terms of `multiline.match` from `previous` => `after` and `next` => `before`.

## Ignoring Timestamps

By default, we ignore `timestamp` and `@timestamp` fields. You can customize this in the [./test.sh](./test.sh) where we use the ignore flag like so `./log-diff.js -i`.
