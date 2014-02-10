#!/bin/bash

upper() { echo ${@^^}; }

echo $1
upper $1 | echo
