#!/bin/bash
GPG_KEY_ID="<YOUR-GPG-KEY-ID>"
OUTPUT_FILE="terraform/gpg-private.asc"

mkdir -p terraform
gpg --export-secret-keys --armor "$GPG_KEY_ID" > "$OUTPUT_FILE"