#!/bin/bash

set -Eeuo pipefail

if [ -z $OSM_DATA_URL ]; then
  echo "Error: Env variable OSM_DATA_URL not set. Exiting."
  exit 1
fi

readonly DATA_DIR='data/'
readonly OSM_DATA_FILE='map-data.osm.pbf'
readonly OSRM_EXTRACT_PATH='./node_modules/@project-osrm/osrm/lib/binding/osrm-extract'
readonly OSRM_CONTRACT_PATH='./node_modules/@project-osrm/osrm/lib/binding/osrm-contract'

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT
NEW_DATA_DIR="${tmp_dir}/${DATA_DIR}"

echo "Fetching new map data..."
mkdir -p ${NEW_DATA_DIR}
curl -v -sSL -o ${NEW_DATA_DIR}/${OSM_DATA_FILE} ${OSM_DATA_URL}
echo "New map data downloaded!"

echo "Running OSRM binaries against the downloaded data..."
for f in osrm-profiles/*.lua
do
  profile=$(basename $f .lua)

  echo "Processing routing network for profile ${profile}..."
  cp osrm-profiles/${profile}.lua node_modules/@project-osrm/osrm/profiles/${profile}.lua

  mkdir -p ${NEW_DATA_DIR}/${profile}/
  ${OSRM_EXTRACT_PATH} ${NEW_DATA_DIR}/${OSM_DATA_FILE} -p node_modules/@project-osrm/osrm/profiles/${profile}.lua
  mv ${NEW_DATA_DIR}/map-data.osrm* ${NEW_DATA_DIR}/${profile}/ # Move data to profile-specific folder
  ${OSRM_CONTRACT_PATH} ${NEW_DATA_DIR}/${profile}/map-data.osrm
done

echo "Data preparation ready!"

echo "Replacing previous data..."
rm -rf "${DATA_DIR}"
mv "${NEW_DATA_DIR}" "${DATA_DIR}"

exit 0
