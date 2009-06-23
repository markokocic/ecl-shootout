#!/bin/sh

echo "$1"

rm -f "$1" "$1.o" "$1.fas"
ecl -norc -load compile.lisp -eval "(create-exec \"$1\")" -eval '(quit)'
echo
