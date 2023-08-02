#!/bin/bash
echo "Fetching map data..."
mkdir -p data/
wget -q -O data/hsl.osm.pbf https://karttapalvelu.storage.hsldev.com/hsl.osm/hsl.osm.pbf

echo "Data is downloaded!"

echo "Copying custom profiles to osrm"
cp -r profiles/trambus.lua node_modules/@project-osrm/osrm/profiles/trambus.lua

echo "Processing networks for profiles..."
mkdir -p data/trambus/
node_modules/@project-osrm/osrm/lib/binding/osrm-extract data/hsl.osm.pbf -p node_modules/@project-osrm/osrm/profiles/trambus.lua
mv data/hsl.osrm* data/trambus/ # Move data to profile-specific folder
node_modules/@project-osrm/osrm/lib/binding/osrm-contract data/trambus/hsl.osrm

echo "Data preparation ready!"
