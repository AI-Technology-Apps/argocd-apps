#!/usr/bin/env bash
set -e

echo "🔍 Validating that all sealedsecret.yaml files are properly sealed..."

fail=0
for file in $(git diff --cached --name-only | grep 'sealedsecret\.yaml$'); do
  if ! grep -q 'kind: SealedSecret' "$file"; then
    echo "❌ $file is not properly sealed!"
    fail=1
  else
    echo "✅ $file is sealed"
  fi
done

if [[ $fail -ne 0 ]]; then
  echo "🛑 Commit aborted: unsealed secrets found."
  exit 1
fi

echo "✅ All secrets are properly sealed."