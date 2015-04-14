/*
* Copyright (c) 2014 Razeware LLC
*/

import MapKit

func CoordinateRegionBoundingMapPoints(points: [MKMapPoint]) -> MKCoordinateRegion {
  if (points.count == 0) {
    return MKCoordinateRegionForMapRect(MKMapRectWorld)
  }

  let mapSizeZero = MKMapSizeMake(0.0, 0.0)

  var boundingMapRect = MKMapRect(origin: points[0], size: mapSizeZero)

  for point in points {
    if (!MKMapRectContainsPoint(boundingMapRect, point)) {
      boundingMapRect = MKMapRectUnion(boundingMapRect, MKMapRect(origin: point, size: mapSizeZero))
    }
  }

  var region = MKCoordinateRegionForMapRect(boundingMapRect)
  region.span.latitudeDelta = max(region.span.latitudeDelta, 0.001)
  region.span.longitudeDelta = max(region.span.longitudeDelta, 0.001)

  return region
}

