import { CronJob } from 'cron';

import { DATA_UPDATE_SCHEDULE } from './constants.js';
import updateDatasets from './data.js';

const dataUpdater = new CronJob(
  DATA_UPDATE_SCHEDULE,
  () => updateDatasets(),
  null,
  false,
  'Europe/Helsinki',
);

const initCronJobs = () => {
  dataUpdater.start();
};

export default initCronJobs;
