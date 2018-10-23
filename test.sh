#!/usr/bin/env bash
# set -x
set -euo pipefail

# COLORS
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

TEST_RESULT_FILE="test_output.log"
TEST_PARENT_DIRECTORY=$1

if [[ "$2" != "" ]]; then
    TEST_LOGSTASH_IMAGE=$2
else
    TEST_LOGSTASH_IMAGE="docker.elastic.co/logstash/logstash:5.5.1"
fi

declare -A benchmarks

spinner() {
  spin='-\|/'
  pid="$1"

  i=0
  while kill -0 "$pid" 2>/dev/null
  do
    i=$(( (i+1) %4 ))
    printf "\r%s" "${spin:$i:1}"
    sleep .1
  done
}

log() {
  CASE=$1
  TEST_NAME=$2
  TIME=""

  if [[ $CASE == "pass" ]]
  then
    SYMBOL="✔"
    COLOR=$GREEN
    CONTENT="passed"
  elif [[ $CASE == "time" ]]
  then
    SYMBOL="⏰"
    COLOR=$YELLOW
    CONTENT="time spent"
    TIME=${benchmarks[$TEST_NAME]}
  else
    SYMBOL="𝗫"
    COLOR=$RED
    CONTENT="failed"
  fi
  echo -e "${COLOR}${SYMBOL} ${CONTENT}${NC} - ${TEST_NAME} ${TIME}"
}

logstashTest() {
  TEST_DIRECTORY="$1"
  echo '' > $TEST_RESULT_FILE
  chmod 777 $TEST_RESULT_FILE

  START=$(date +%s)

  docker run \
    --rm \
    -i \
    -v "$PWD/config/logstash.yml":/usr/share/logstash/config/logstash.yml \
    -v "$PWD/$TEST_DIRECTORY/logstash.conf":/usr/share/logstash/pipeline/logstash.conf \
    -v "$PWD/logstash-common.conf":/usr/share/logstash/pipeline/logstash-common.conf \
    -v "$PWD/$TEST_RESULT_FILE":/output.log \
    "$TEST_LOGSTASH_IMAGE" < "$TEST_DIRECTORY/input.log" 2>/dev/null &

  # SPINNER
  test_pid=$!
  spinner $test_pid # Process Id of the previous running command
  wait $test_pid
  test_status=$?
  END=$(date +%s)
  DIFF=$(( $END - $START ))
  benchmarks[$TEST_DIRECTORY]="${DIFF}s"

  # here we ignore comparison of timestamp fields. You can ignore any other fields you need to
  [ "$test_status" = "0" ] && ./log-diff.js -i '@timestamp,timestamp' -c "$TEST_DIRECTORY/output.log,$TEST_RESULT_FILE"
}

# TODO: Check if docker is running
# if ! docker info 2&>1 > /dev/null
# then
#   log fail "docker might not be running"
#   false
# fi

# RUN TESTS
EXIT_CODE=0
TESTS_DIRECTORIES="$TEST_PARENT_DIRECTORY/*"
declare -A results
for d in $TESTS_DIRECTORIES ; do
    echo "Testing $d"
    logstashTest "$d"
    results[$d]="$?"

    if [[ ${results[$d]} == 0 ]]
    then
      log time "$d"
      log pass "$d"
    else
      log time "$d"
      log fail "$d"
      EXIT_CODE=1
    fi
done

# PRINT RESULTS
echo ""
echo "TEST SUMMARY"
echo "------------"
for K in "${!results[@]}"
do
  if [[ ${results[$K]} == 0 ]]
  then
    log pass "$K ${benchmarks[$K]}"
  else
    log fail "$K ${benchmarks[$K]}"
    EXIT_CODE=1
  fi
done

if [[ $EXIT_CODE == 0 ]]
then
  log pass "All tests"
else
  log fail "Some tests"
fi
exit $EXIT_CODE
