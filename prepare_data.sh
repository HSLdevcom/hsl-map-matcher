#!/bin/bash
if [ -z $OSM_DATA_URL ]; then
  echo "Error: Env variable OSM_DATA_URL not set. Exiting."
  exit 1
fi

DATA_DIR='data/'
BACKUP_DATA_DIR='old_data/'
OSM_DATA_FILE='map-data.osm.pbf'

# Check if there's any existing map data. If there is, back it up
if [ -f "$DATA_DIR/$OSM_DATA_FILE" ]; then
  echo "Previous data exists, backing it up."
  mkdir -p $BACKUP_DATA_DIR
  cp $DATA_DIR/$OSM_DATA_FILE $BACKUP_DATA_DIR
  echo "Backup of $DATA_DIR created in $BACKUP_DATA_DIR."
fi

echo "Fetching new map data..."
rm -rf $DATA_DIR # Remove previous data before update from main directory
mkdir -p $DATA_DIR
if !(curl -v -sSL -o $DATA_DIR/$OSM_DATA_FILE $OSM_DATA_URL); then
  echo "Error fetching map data from $OSM_DATA_URL. See above output for details. Using previous map data."
  if [ -f "$BACKUP_DATA_DIR/$OSM_DATA_FILE" ]; then
    echo "Restoring data from backup..."
    cp -r $BACKUP_DATA_DIR/$OSM_DATA_FILE $DATA_DIR
    echo "Backup restored successfully !"
  else
    echo "No backup found. Exiting."
    exit 1
  fi
fi

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

