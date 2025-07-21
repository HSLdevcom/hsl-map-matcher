/* eslint-disable no-console */
import { spawn } from 'node:child_process';
import path from 'node:path';

import { OSM_DATA_URL } from './constants.js';
import { clearProfiles, initNetworks } from './matcher.js';

// Variable to prevent multiple update process to be started at the same time
let processRunning = false;

const updateDatasets = () => {
  if (processRunning) {
    console.warn('Update process is already running. Skipping this update.');
    return;
  }
  processRunning = true;
  clearProfiles();
  const script = spawn(path.join(process.cwd(), 'prepare_data.sh'), { env: { OSM_DATA_URL } });

  script.stdout.on('data', (data) => {
    console.log(`prepare_data.sh: ${data}`);
  });

  script.stderr.on('data', (data) => {
    console.error(`prepare_data.sh: ${data}`);
  });

  script.on('close', (code) => {
    processRunning = false;
    if (code === 0) {
      console.log(`prepare_data.sh executed successfully!`);

      // Data ready, update new network profiles
      initNetworks();
    } else {
      console.error(
        `prepare_data.sh raised error and exited with code ${code}. See previous output for details.`,
      );
    }
  });
};

export default updateDatasets;
