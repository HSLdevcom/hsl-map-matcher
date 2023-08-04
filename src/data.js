import { spawn } from 'node:child_process';
import path from 'node:path';

import { clearProfiles, initNetworks } from './matcher.js';

const updateDatasets = () => {
  clearProfiles();
  const script = spawn(path.join(process.cwd(), 'prepare_data.sh'));

  script.stdout.on('data', (data) => {
    // eslint-disable-next-line no-console
    console.log(`prepare_data.sh: ${data}`);
  });

  script.stderr.on('data', (data) => {
    // eslint-disable-next-line no-console
    console.error(`prepare_data.sh: ${data}`);
  });

  script.on('close', (code) => {
    if (code === 0) {
      // eslint-disable-next-line no-console
      console.log(`prepare_data.sh executed successfully!`);

      // Data ready, update new network profiles
      initNetworks();
    } else {
      throw new Error(`prepare_data.sh raised error and exited with code ${code}`);
    }
  });
};

export default updateDatasets;
