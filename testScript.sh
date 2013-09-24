#!/bin/bash
for TESTCASE in {1..20}
do
  echo "=====TESTING $TESTCASE.micro========"　
  ./Micro testcases/input/test$TESTCASE.micro
  cat testcases/output/test$TESTCASE.out
done
