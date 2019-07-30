#!/bin/sh

d=$(dirname "$0")
LUA_PATH="$d/?.lua" "$d"/graph.lua "$@"
