#!/bin/bash
# Build script for Netlify documentation deployment
# This script builds the mkdocs documentation without installing Rails dependencies

set -e

echo "Installing mkdocs and dependencies..."
pip install mkdocs-material

echo "Building documentation..."
mkdocs build

echo "Documentation build complete. Output in site/"
