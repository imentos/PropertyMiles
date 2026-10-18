# Recorded Driving Routes

New trips retain a sampled GPS trace alongside the existing distance and endpoints.
The Trips list and Trip Details use the same MapKit polyline view. The map fits the
recorded trace, including excursions when the start and end are the same location.
Endpoints within 50 metres use a combined start/end marker.

## Recording

- Reuses existing precise-location callbacks; no additional GPS requests or
  geocoding calls are added for the route.
- Records samples only during an active trip while vehicle activity is true and
  the stop timer is not active. Debug cycling follows the existing tracking mode.
- Discards invalid coordinates, accuracy worse than 100 metres, samples older than
  30 seconds, timestamps over 5 seconds in the future, and duplicate/out-of-order
  samples. Samples normally need at least 10 metres of movement to be retained.
- A stop signal, location gap over 60 seconds or consecutive retained-point jump
  of at least 200 metres starts a new map segment. The map does not draw a line
  across these boundaries.
- More than 4,096 points triggers downsampling that keeps the first and latest
  points and propagates segment breaks, bounding per-trip storage.
- This does not change motion start/stop decisions, the three-minute stop wait,
  distance accumulation or tax/reimbursement calculations.

## Compatibility and Privacy

`Trip.routePoints` is optional, so existing saved trips still decode normally.
Old trips have no trace to recover and show endpoints with a no-recorded-route
status. No estimated directions or invented route is substituted.

Route samples are stored locally as part of the saved trip. They are not included
in CSV exports. The app does not upload the trace to a routing service. Displayed
lines connect retained GPS samples, so they are not guaranteed to follow every
road curve or recover travel before tracking began or during missing GPS updates.

## Checks

```sh
swiftc -module-cache-path /private/tmp/landmile-swift-cache RealEstateMileageTracker/Models/Vehicle.swift RealEstateMileageTracker/Models/Trip.swift RealEstateMileageTracker/Models/TripRoute.swift scripts/test-trip-routes.swift -o /private/tmp/landmile-route-checks
/private/tmp/landmile-route-checks
```

The checks cover legacy decoding, JSON persistence, loop-map bounds, rejected GPS
samples, pause/time/jump boundaries, long-drive downsampling and unchanged mileage.
The optional `--fixture /private/tmp/landmile-route-fixture.plist` argument emits
synthetic simulator data for UI verification; never import it into a real user's app.

Before release, test an actual out-and-back drive with a brief stop, a longer stop,
and a drive with poor GPS reception. Verify the list and interactive detail map.
