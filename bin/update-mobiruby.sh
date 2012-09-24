#!/bin/sh

git pull origin master
git submodule foreach 'git checkout master; git pull origin master'
