import 'dotenv/config';

// schedule default at noon. Better than midnight, because jore-import is running at night
export const DATA_UPDATE_SCHEDULE = process.env.DATA_UPDATE_SCHEDULE || '0 0 12 * * *';
export const OSM_DATA_URL =
  process.env.OSM_DATA_URL || 'https://karttapalvelu.storage.hsldev.com/hsl.osm/hsl.osm.pbf';
export const PORT = process.env.PORT || 3000;
