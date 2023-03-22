#!/bin/bash

PROTEX_DIR=$HOME/src/protex/code
cp -u $PROTEX_DIR/CHANGELOG.md ./protex_changelog.md
md2html ./protex_changelog.md > ./public/templates/protex_changelog.html
