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
cp docs/_headers site/_headers 2>/dev/null || echo "Note: _headers file not found"
cp docs/_redirects site/_redirects 2>/dev/null || echo "Note: _redirects file not found"

echo "Documentation build complete. Output in site/"
