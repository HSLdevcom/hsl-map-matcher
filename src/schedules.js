import { CronJob } from 'cron';

import updateDatasets from './data.js';

const dataUpdater = new CronJob(
  '0 0 12 * * *', // default at noon. Better than midnight, because jore-import is running at night
  () => updateDatasets(),
  null,
  false,
  'Europe/Helsinki',
);

const initCronJobs = () => {
  dataUpdater.start();
};

export default initCronJobs;
