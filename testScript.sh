#!/bin/bash
for TESTCASE in {1..21}
do
  echo "=====TESTING $TESTCASE.micro========"　
  ./Micro testcases/input/test$TESTCASE.micro > out
  cat testcases/output/test$TESTCASE.out > out2
  diff out out2
done
