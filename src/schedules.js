import { CronJob } from 'cron';

import { DATA_UPDATE_SCHEDULE } from './constants.js';
import updateDatasets from './data.js';

// cronjob for automatic data updates
const dataUpdater = new CronJob(
  DATA_UPDATE_SCHEDULE,
  () => updateDatasets(),
  null,
  false,
  'Europe/Helsinki',
);

// start the job
const initCronJobs = () => {
  dataUpdater.start();
};

export default initCronJobs;
