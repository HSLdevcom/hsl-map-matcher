import express from 'express';

import { matchGeometry } from './matcher';

const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.send('Welcome!');
});

app.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(`Map-matcher is running on port ${port}`);
});
