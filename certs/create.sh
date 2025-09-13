#!/usr/bin/env bash
# Generate a self-signed certificate with OpenSSL
# Usage: ./create-cert.sh [canonical_name]

# Use provided CN or default to localhost
CN="${1:-localhost}"

# Generate the certificate
openssl req -x509 -newkey rsa:4096 \
  -keyout privkey.pem \
  -out fullchain.pem \
  -sha256 -days 36500 -nodes \
  -subj "/CN=${CN}"
