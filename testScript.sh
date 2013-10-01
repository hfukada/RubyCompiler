#!/bin/bash
for TESTCASE in {1..21}
do
  if [ -e testcases/input/test$TESTCASE.micro ]; then
    echo "=====TESTING $TESTCASE.micro========"　
    ./Micro testcases/input/test$TESTCASE.micro > out
    cat testcases/output/test$TESTCASE.out > out2
    diff out out2
  fi
  if [ -e out ]; then
    rm out
    rm out2
  fi
done
