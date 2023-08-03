import fs from 'node:fs';

import OSRM from '@project-osrm/osrm';

const DATA_DIRECTORY = './data/';

// Get all available routing dataset names
const profiles = fs
  .readdirSync(DATA_DIRECTORY, { withFileTypes: true })
  .filter((f) => f.isDirectory())
  .map((dir) => dir.name);

const networks = {};

// Helper function to get available profiles
const getProfiles = () => Object.keys(networks);

const initNetworks = () => {
  profiles.forEach((profile) => {
    networks[profile] = new OSRM(`${DATA_DIRECTORY}${profile}/hsl.osrm`);
  });
};

const matchGeometry = (profile, geometry) => {
  if (!getProfiles().includes(profile)) {
    throw Error(`Invalid profile: ${profile}`);
  }

  const osrm = networks[profile];

  osrm.match(
    { coordinates: geometry, overview: 'full', geometries: 'geojson' },
    (err, response) => {
      if (err) {
        throw err;
      }
      return response.matchings[0].geometry;
    },
  );
};

export { initNetworks, getProfiles, matchGeometry };
