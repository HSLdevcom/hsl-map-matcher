import fs from 'node:fs';
import path from 'node:path';

const OSRM_PATTERN = /^map-data\.osrm\..*$/;

// Helper function to return data directory location
const getDataDir = () => path.join(process.cwd(), 'data');

// Finds all directories under data-directory that contain osrm datasets
const getAvailableDatasets = () => {
  const dataDir = getDataDir();

  // create datadir if not exists
  if (!fs.existsSync(dataDir)) {
    fs.mkdirSync(dataDir);
  }

  // find osrm datasets
  const datasets = fs
    .readdirSync(dataDir, { withFileTypes: true })
    .filter((d) => d.isDirectory())
    .filter((d) => fs.readdirSync(path.join(dataDir, d.name)).some((f) => OSRM_PATTERN.test(f))) // Check that directory contains osrm files
    .map((d) => d.name);

  return datasets;
};

// Gets the timestamp when OSM data was created. Relies on file system timestamp, so it gives just a hint.
const getOSMUpdateTimestamp = () => {
  const dataDir = getDataDir();
  return fs.statSync(path.join(dataDir, 'map-data.osm.pbf')).mtime;
};

export { getDataDir, getAvailableDatasets, getOSMUpdateTimestamp };
