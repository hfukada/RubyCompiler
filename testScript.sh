#!/bin/bash
#for TESTCASE in {1..21}
#do
#  if [ -e testcases/input/test$TESTCASE.micro ]; then
#    echo "=====TESTING $TESTCASE.micro========"　
#    ./Micro testcases/input/test$TESTCASE.micro > out
#    cat testcases/output/test$TESTCASE.out > out2
#    diff out out2
#  fi
#  if [ -e out ]; then
#    rm out
#    rm out2
#  fi
#done
echo "==== expr ===="
./Micro testcases/test_expr.micro > out
./tinyR out | head -n 1
./tinyR testcases/test_expr.out | head -n 1
echo "==== step 4 ===="
./Micro testcases/step4_testcase3.micro > out
./tinyR out | head -n 1
./tinyR testcases/step4_testcase3.out | head -n 1
rm out

