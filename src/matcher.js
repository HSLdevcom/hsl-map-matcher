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
    networks[profile] = new OSRM(`${dataDir}/${profile}/map-data.osrm`);
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
      {
        coordinates: geometry.coordinates,
        overview: 'full',
        geometries: 'geojson',
        tidy: true,
        gaps: 'ignore',
        radiuses: geometry.coordinates.map(() => 15.0), // Set accuracy to 15 meters
      },
      (err, response) => {
        if (err) {
          reject(err);
          return;
        }
        resolve({
          confidence:
            response.matchings.reduce((prev, curr) => prev + curr.confidence, 0) /
            response.matchings.length, // Avg of confidence values.
          geometry: {
            coordinates: response.matchings.reduce(
              (prev, curr) => prev.concat(curr.geometry.coordinates),
              [],
            ),
            type: 'LineString',
          },
        });
      },
    );
  });
};

export { initNetworks, clearProfiles, getProfiles, matchGeometry };
