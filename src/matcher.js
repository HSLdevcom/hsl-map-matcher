import OSRM from '@project-osrm/osrm';

import { getDataDir, getAvailableDatasets } from './util.js';

// Store for osrm network datasets
const networks = {};

// Helper function to get available profiles
const getProfiles = () => Object.keys(networks);

// Helper function to clear profiles
const clearProfiles = () => Object.getOwnPropertyNames(networks).forEach((k) => delete networks[k]);

const initNetworks = () => {
  // Clear current profiles
  clearProfiles();

  // Get all available routing dataset names
  const dataDir = getDataDir();
  const profiles = getAvailableDatasets();

  profiles.forEach((profile) => {
    networks[profile] = new OSRM(`${dataDir}/${profile}/hsl.osrm`);
  });
};

// Matcher function. Takes geojson as input and returns geojson with map matching confidence level-
const matchGeometry = async (profile, geometry) => {
  if (!getProfiles().includes(profile)) {
    throw Error(`Invalid profile: ${profile}`);
  }

  const osrm = networks[profile];

  return new Promise((resolve, reject) => {
    osrm.match(
      { coordinates: geometry.coordinates, overview: 'full', geometries: 'geojson' },
      (err, response) => {
        if (err) {
          reject(err);
          return;
        }
        resolve({
          confidence: response.matchings[0].confidence,
          geometry: response.matchings[0].geometry,
        });
      },
    );
  });
};

export { initNetworks, clearProfiles, getProfiles, matchGeometry };
