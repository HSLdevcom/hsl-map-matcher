#!/bin/bash
echo "Fetching map data..."
mkdir -p data/
wget -q -O data/hsl.osm.pbf https://karttapalvelu.storage.hsldev.com/hsl.osm/hsl.osm.pbf

echo "Data is downloaded!"


for f in osrm-profiles/*.lua
do
  profile=$(basename $f .lua)

  echo "Processing routing network for profile ${profile}..."
  cp osrm-profiles/${profile}.lua node_modules/@project-osrm/osrm/profiles/${profile}.lua

  mkdir -p data/${profile}/
  node_modules/@project-osrm/osrm/lib/binding/osrm-extract data/hsl.osm.pbf -p node_modules/@project-osrm/osrm/profiles/${profile}.lua
  mv data/hsl.osrm* data/${profile}/ # Move data to profile-specific folder
  node_modules/@project-osrm/osrm/lib/binding/osrm-contract data/${profile}/hsl.osrm
done


echo "Data preparation ready!"
