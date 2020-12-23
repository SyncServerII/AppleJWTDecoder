#!/bin/csh

# Run this from the root of the project-- i.e., where the Package.swift file is.

cp Resources/example.url /tmp
cp Resources/Cat.jpg /tmp
swift test
