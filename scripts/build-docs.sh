#!/bin/bash
# Build script for Netlify documentation deployment
# This script builds the mkdocs documentation without installing Rails dependencies

set -e

echo "Installing mkdocs and dependencies..."
pip install mkdocs-material

echo "Building documentation..."
mkdocs build

# Copy Netlify configuration files to site directory
echo "Setting up Netlify configuration..."
if [ -f docs/_headers ]; then
  cp docs/_headers site/_headers && echo "✓ Copied _headers to site/"
else
  echo "✗ Error: docs/_headers not found"
  exit 1
fi

if [ -f docs/_redirects ]; then
  cp docs/_redirects site/_redirects && echo "✓ Copied _redirects to site/"
else
  echo "✗ Error: docs/_redirects not found"
  exit 1
fi

echo "Documentation build complete. Output in site/"
