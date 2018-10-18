# logstash-test-runner

![image](http://i.imgur.com/hQm9yAb.gif)

Example tests are in the `__tests__` directory.
To add a tests, simply add a new directory with the given input `input.log`, the ETL configuration `logstash.conf`, and the expected output `output.log`.

## Prerequisites

* Install nodejs > 8
* Run `npm install`
* Install Docker

# Setup

* Clone repository
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

* Run your tests

```sh
# ./test.sh <test-parent-directory>
./test.sh __tests__
```

NOTE: Multiline logs in logstash need translate in reverse to filebeat in terms of `multiline.match` from `previous` => `after` and `next` => `before`.
