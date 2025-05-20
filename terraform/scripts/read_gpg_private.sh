#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <path-to-gpg-private.asc>"
  exit 1
fi

if [ ! -f "$1" ]; then
  echo "File not found: $1"
  exit 1
fi

CONTENT=$(cat "$1" | base64 | tr -d '\n')
echo "{\"content\": \"$CONTENT\"}"