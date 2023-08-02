#!/bin/bash
echo "Fetching map data..."
mkdir -p data/
wget -q -O data/hsl.osm.pbf https://karttapalvelu.storage.hsldev.com/hsl.osm/hsl.osm.pbf

echo "Data is downloaded!"

node_modules/@project-osrm/osrm/lib/binding/osrm-extract data/hsl.osm.pbf -p node_modules/@project-osrm/osrm/profiles/car.lua
node_modules/@project-osrm/osrm/lib/binding/osrm-contract data/hsl.osrm
