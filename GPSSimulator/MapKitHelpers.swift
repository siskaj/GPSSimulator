/*
* Copyright (c) 2014 Razeware LLC
*/

import MapKit
import GPX

public enum Mode {
	case Scale(Double)
	case FullTrack
}

public func CoordinateRegionBoundingMapPoints(points: [MKMapPoint]) -> MKCoordinateRegion {
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


public func MapRectBoundingMapPoints(points: [MKMapPoint]) -> MKMapRect {
  let rect = points.reduce(MKMapRectNull) { (mapRect: MKMapRect, point: MKMapPoint) in
    let pointRect = MKMapRect(origin: point, size: MKMapSize(width: 0, height: 0))
    return MKMapRectUnion(mapRect, pointRect)
  }
  
  // Pomoci negativne nastaveneho Insetu zvetsim MapRect tak, aby vytvorena path se nedotykala okraju MapRect
  return MKMapRectInset(rect, -rect.size.width/10, -rect.size.height/10)
}

public func MKMapPointForWayPoint(point: GPXWaypoint) -> MKMapPoint {
	return MKMapPointForCoordinate(CLLocationCoordinate2DMake(Double(point.latitude), Double(point.longitude)))
}

public func drawPath(points: [CGPoint], intoImage image: UIImage, curLocation location: CGPoint?) -> UIImage {
	UIGraphicsBeginImageContext(image.size)
	image.drawAtPoint(CGPointZero)
	
	//    let ctx = UIGraphicsGetCurrentContext()
	UIColor.redColor().setStroke()
	var path = UIBezierPath()
	path.moveToPoint(points[0])
	for i in 1..<points.count {
		path.addLineToPoint(points[i])
	}
	path.lineWidth = 3
	//    CGContextStrokePath(ctx)
	path.stroke()
	
	if let location = location {
		let pin = MKPinAnnotationView(annotation: nil, reuseIdentifier: nil)
		pin.image.drawAtPoint(location)
	}
	
	let retImage = UIGraphicsGetImageFromCurrentImageContext()
	UIGraphicsEndImageContext()
	return retImage
}
