import fs from 'node:fs';
import path from 'node:path';

const OSRM_PATTERN = /^hsl\.osrm\..*$/;

// Helper function to return data directory location
const getDataDir = () => path.join(process.cwd(), 'data');

// Finds all directories under data-directory that contain osrm datasets
const getAvailableDatasets = () => {
  const dataDir = getDataDir();

  const datasets = fs
    .readdirSync(dataDir, { withFileTypes: true })
    .filter((d) => d.isDirectory())
    .filter((d) => fs.readdirSync(path.join(dataDir, d.name)).some((f) => OSRM_PATTERN.test(f))) // Check that directory contains osrm files
    .map((d) => d.name);

  return datasets;
};

export { getDataDir, getAvailableDatasets };
