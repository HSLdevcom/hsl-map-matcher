import express from 'express';
import { checkSchema, param, validationResult } from 'express-validator';

import { getProfiles, initNetworks, matchGeometry } from './matcher.js';

const app = express();
const port = 3000;

initNetworks();

app.use(express.json());

app.get('/', (req, res) => {
  res.send('Welcome!');
});

// Validation middlewares
const validateProfile = param('profile')
  .isIn(getProfiles())
  .withMessage(`Given profile not found. Available profiles are: ${getProfiles().join(',')}`);
const validateBody = checkSchema(
  {
    geometry: { isObject: { errorMessage: 'GeoJSON format requires "geometry" field as object' } },
    'geometry.coordinates': {
      isArray: {
        options: {
          min: 2,
        },
        errorMessage:
          'Coordinates should be an array and have at least 2 coordinate pairs (LineStrings only accepted)',
      },
    },
    'geometry.coordinates.*': {
      isArray: {
        options: {
          min: 2,
          max: 2,
        },
        errorMessage: 'Coordinates should be in [lon, lat] format',
      },
    },
    'geometry.coordinates.*.*': {
      isNumeric: { errorMessage: 'Coordinates can only contain numeric values' },
      customSanitizer: { options: (val) => Number(val) },
    },
  },
  ['body'],
);

app.post('/match/:profile', [validateProfile, validateBody], async (req, res, next) => {
  const errResult = validationResult(req);

  if (!errResult.isEmpty()) {
    res.status(400);
    res.send({ errors: errResult.array() });
    return next();
  }
  const { profile } = req.params;

  const data = req.body;

  try {
    const fittedGeometry = await matchGeometry(profile, data.geometry);
    return res.send(fittedGeometry);
  } catch (err) {
    if (err.message === 'NoSegment') {
      return res
        .status(400)
        .send(
          'Could not find a valid matching. Check the input coordinates that they fit the area.',
        );
    }
    return next(err);
  }
});

app.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(`Map-matcher is running on port ${port}`);
});
