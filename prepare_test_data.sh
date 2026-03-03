#!/bin/bash

TEST_DATA_DIR="data"

rm -rf "$TEST_DATA_DIR"
mkdir -p "$TEST_DATA_DIR"

echo "Fetching map data to $TEST_DATA_DIR..."
curl -sSL -o "$TEST_DATA_DIR/map-data.osm.pbf" "https://karttapalvelu.storage.hsldev.com/hsl.osm/hsl.osm.pbf"
echo "Data is downloaded!"

PROFILES=$@
if [ -z "$PROFILES" ]; then
  echo "No profiles specified. Usage: $0 <profile1> <profile2> ..."
  echo "Available profiles in osrm-profiles/:"
  ls osrm-profiles/ | sed 's/\.lua//'
  exit 1
fi

for profile in $PROFILES
do
  if [ ! -f "osrm-profiles/${profile}.lua" ]; then
    echo "Warning: Profile ${profile} not found in osrm-profiles/. Skipping."
    continue
  fi

  echo "--------------------------------------------------------"
  echo "Processing routing network for profile: ${profile}"
  echo "--------------------------------------------------------"

  cp "osrm-profiles/${profile}.lua" "node_modules/@project-osrm/osrm/profiles/${profile}.lua"

  rm -rf "$TEST_DATA_DIR/${profile}"
  mkdir -p "$TEST_DATA_DIR/${profile}"

  echo "Extracting..."
  ./node_modules/@project-osrm/osrm/lib/binding/osrm-extract "$TEST_DATA_DIR/map-data.osm.pbf" -p "node_modules/@project-osrm/osrm/profiles/${profile}.lua"
  
  mv "$TEST_DATA_DIR"/map-data.osrm* "$TEST_DATA_DIR/${profile}/"

  echo "Contracting..."
  ./node_modules/@project-osrm/osrm/lib/binding/osrm-contract "$TEST_DATA_DIR/${profile}/map-data.osrm"
done

echo "--------------------------------------------------------"
echo "Test data preparation ready in $TEST_DATA_DIR!"
echo "--------------------------------------------------------"
exit 0
