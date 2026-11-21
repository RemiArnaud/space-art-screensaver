#!/bin/bash
# Build and install SpaceArt.saver into ~/Library/Screen Savers.
set -euo pipefail
cd "$(dirname "$0")"

./build.sh
mkdir -p ~/Library/Screen\ Savers
cp -R SpaceArt.saver ~/Library/Screen\ Savers/

echo "Installed to ~/Library/Screen Savers/SpaceArt.saver"
echo "Open System Settings > Screen Saver and pick SpaceArt."
