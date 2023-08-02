# hsl-map-matcher

This is a map matching service to fit routes to OSM map data. The service is based on [OSRM](https://project-osrm.org/).

Routes coming from Jore are not fitted correctly to the OSM, which is not nice looking on printed maps. During jore-import process (https://github.com/HSLdevcom/jore-graphql-import), this service will be called to fit the route to OSM data so that it follows the way precisely.

Map matcher will support 3 profiles:
- bus (fitting allowed to highways, including bus-specific roads)
- tram (fitting allowed to railways tagged as tram or light_rail)
- trambus (combination of bus and tram, used for X-lines)

