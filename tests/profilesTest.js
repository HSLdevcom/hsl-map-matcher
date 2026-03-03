import fs from 'fs';
import { matchGeometry, initNetworks } from '../src/matcher.js';

const shapes = fs.readFileSync('tests/shapes.txt', 'utf8');

// Split lines and extract headers
const [headerLine, ...lines] = shapes.trim().split('\n');
const headers = headerLine.split(',');

// Group rows
const grouped = {};

for (const line of lines) {
  const values = line.split(',');
  const row = Object.fromEntries(headers.map((h, i) => [h, values[i]]));

  const id = row.shape_id;
  if (!grouped[id]) grouped[id] = [];

  grouped[id].push([parseFloat(row.shape_pt_lon), parseFloat(row.shape_pt_lat)]);
}

const createQuery = (shapeId) => ({
  coordinates: grouped[shapeId],
  type: 'LineString',
});

initNetworks();

const specialKey = '1064_20251216_1';
if (grouped[specialKey]) {
  const resBus = await matchGeometry('bus', createQuery(specialKey));
  const busFeature = {
    type: 'Feature',
    properties: {
      shapeId: specialKey,
      profile: 'bus',
      confidence: resBus.confidence,
    },
    geometry: resBus.geometry,
  };
  fs.writeFileSync('bus.json', JSON.stringify(busFeature, null, 2));
  console.log(`Saved bus profile feature for ${specialKey} to bus.json`);

  const resBusTemporal = await matchGeometry('bus-with-temporal-filter', createQuery(specialKey));
  const busTemporalFeature = {
    type: 'Feature',
    properties: {
      shapeId: specialKey,
      profile: 'bus-with-temporal-filter',
      confidence: resBusTemporal.confidence,
    },
    geometry: resBusTemporal.geometry,
  };
  fs.writeFileSync('bus-with-temporal-filter.json', JSON.stringify(busTemporalFeature, null, 2));
  console.log(
    `Saved bus-with-temporal-filter profile feature for ${specialKey} to bus-with-temporal-filter.json`,
  );
}

// const shapeIds = Object.keys(grouped);
//
// for (let i = 0; i < shapeIds.length; i++) {
//   const key = shapeIds[i];
//
//   try {
//     const resBus = await matchGeometry('bus', createQuery(key));
//     const resBusTemporal = await matchGeometry('bus-with-temporal-filter', createQuery(key));
//
//     if (JSON.stringify(resBus) !== JSON.stringify(resBusTemporal)) {
//       const geoJson = {
//         type: 'FeatureCollection',
//         features: [
//           {
//             type: 'Feature',
//             properties: {
//               shapeId: key,
//               profile: 'bus',
//               confidence: resBus.confidence,
//             },
//             geometry: resBus.geometry,
//           },
//           {
//             type: 'Feature',
//             properties: {
//               shapeId: key,
//               profile: 'bus-with-temporal-filter',
//               confidence: resBusTemporal.confidence,
//             },
//             geometry: resBusTemporal.geometry,
//           },
//         ],
//       };
//
//       const fileName = `${key.replace(/\s+/g, '_')}.json`;
//       fs.writeFileSync(fileName, JSON.stringify(geoJson, null, 2));
//       console.log(`Difference found for ${key}, saved to ${fileName}`);
//       console.log(
//         `  Confidence: ${resBus.confidence.toFixed(4)} -> ${resBusTemporal.confidence.toFixed(4)}`,
//       );
//       console.log(
//         `  Geometry points: ${resBus.geometry.coordinates.length} -> ${resBusTemporal.geometry.coordinates.length}`,
//       );
//     } else {
//       console.log(`${key}: Identical`);
//     }
//   } catch (e) {
//     console.error(`Error matching ${key}:`, e.message);
//   }
// }
