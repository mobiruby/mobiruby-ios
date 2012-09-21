#!/bin/sh

git pull origin master
git submodule foreach 'git pull origin master'
git submodule update
