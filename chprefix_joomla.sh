#!/bin/bash

file='configuration.php'
varname='host'
host=$(grep -m 1 -Eos "[$]+$varname\s*=\s*[\'\"]+.*[\'\"]+" $file | "s/host//")
varname='user'
user=$(grep -m 1 -Eos "[$]+$varname\s*=\s*[\'\"]+.*[\'\"]+" $file | grep -Eos ".+[^\'\"](.*)[^\'\"]")
varname='password'
password=$(grep -m 1 -Eos "[$]+$varname\s*=\s*[\'\"]+.*[\'\"]+" $file | grep -Eos "[\'\"](.*)[\'\"]")
varname='db'
db=$(grep -m 1 -Eos "[$]+$varname\s*=\s*[\'\"]+.*[\'\"]+" $file | grep -Eos "[\'\"](.*)[\'\"]")
varname='dbprefix'
dbprefix=$(grep -m 1 -Eos "[$]+$varname\s*=\s*[\'\"]+.*[\'\"]+" $file | grep -Eos "[\'\"](.*)[\'\"]")

echo $host
echo $user
echo $password
echo $db
echo $dbprefix