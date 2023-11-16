#!/bin/bash
if [ -z $OSM_DATA_URL ]; then
  echo "Error: Env variable OSM_DATA_URL not set. Exiting."
  exit 1
fi

echo "Fetching map data..."
rm -rf data/ # Remove old data before udpate
mkdir -p data/
curl -sSL -o data/map-data.osm.pbf $OSM_DATA_URL

echo "Data is downloaded!"


for f in osrm-profiles/*.lua
do
  profile=$(basename $f .lua)

  echo "Processing routing network for profile ${profile}..."
  cp osrm-profiles/${profile}.lua node_modules/@project-osrm/osrm/profiles/${profile}.lua

  mkdir -p data/${profile}/
  node_modules/@project-osrm/osrm/lib/binding/osrm-extract data/map-data.osm.pbf -p node_modules/@project-osrm/osrm/profiles/${profile}.lua
  mv data/map-data.osrm* data/${profile}/ # Move data to profile-specific folder
  node_modules/@project-osrm/osrm/lib/binding/osrm-contract data/${profile}/map-data.osrm
done


echo "Data preparation ready!"
exit 0
