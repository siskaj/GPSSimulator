//
//  ViewControllerDataModel.swift
//  GPSSimulator
//
//  Created by Jaromir Siska on 04.02.15.
//  Copyright (c) 2015 Baltoro. All rights reserved.
//

import Foundation
import MapKit
import BrightFutures

typealias FakeLocationsArray = [CLLocation]
typealias LocalPath = (arrivingStep: MKRouteStep?, leavingStep: MKRouteStep?)
typealias NavigationData = (distance: CLLocationDistance, instruction: String)
typealias JSRouteStep = (step: MKRouteStep, visited: Bool)
typealias JSRoute = (route: MKRoute, steps: [JSRouteStep])

func MKRoute2JSRoute(route: MKRoute) -> JSRoute {
	var a:JSRoute = (route, (route.steps as! [MKRouteStep]).map({ JSRouteStep($0, false) } ))
	a.steps[0].visited = true
	return a
}

class ViewControllerDataModel {
	
	var myRoute: JSRoute!
	
	var previousDistance: CLLocationDistance = 0
	var previousTurnPointCoord = CLLocationCoordinate2D(latitude:0, longitude: 0)
	
	func fakeLocationFromGPXFile(filePath: String) -> FakeLocationsArray? {
		
  let root = GPXParser.parseGPXAtPath(filePath)
  
  if let track = root.tracks.first as? GPXTrack {
		if let segment = track.tracksegments.first as? GPXTrackSegment {
			let trackpoints = segment.trackpoints as! [GPXTrackPoint]
			return trackpoints.map { trackpoint -> CLLocation in
				return CLLocation(latitude: Double(trackpoint.latitude), longitude: Double(trackpoint.longitude))
			}
		} else { return nil }  // pokud tracksegments nemaji ani prvni prvek
	} else { return nil }   // pokud tracks nemaji ani prvni prvek
	}
	
	func setupScenario() -> (Future<MKRoute>,Future<FakeLocationsArray>) {
		
  func obtainMapItemFromString(nazev: String) -> Future<MKMapItem> {
		let promise = Promise<MKMapItem>()
		let geocoder = CLGeocoder()
		
		geocoder.geocodeAddressString(nazev) { (placemarks: [AnyObject]!, error: NSError!) in
			var outError: NSError?
			if placemarks != nil && placemarks.count > 0 {
				let mark = placemarks[0] as! CLPlacemark
				let MKMark = MKPlacemark(coordinate: mark.location.coordinate, addressDictionary: nil)
				promise.success(MKMapItem(placemark: MKMark))
			} else {
				if error != nil {
					promise.failure(error)
				} else {
					outError = NSError(domain: "com.baltoro.BrightFuturesTest1", code: 404, userInfo:[NSLocalizedDescriptionKey : "No routes found!"])
					promise.failure(outError!)
				}
				
			}
		}
		return promise.future
  }
		
  func obtainRouteFrom(from: MKMapItem, to: MKMapItem) -> Future<MKRoute> {
		let promise = Promise<MKRoute>()
		
		let request = MKDirectionsRequest()
		request.setSource(from)
		request.setDestination(to)
		request.transportType = .Automobile
		
		let directions = MKDirections(request: request)
		directions.calculateDirectionsWithCompletionHandler { (response: MKDirectionsResponse!, error: NSError!) in
			var outError: NSError?
			if response != nil && response.routes.count > 0 {
				promise.success(response.routes[0] as! MKRoute)
			} else {
				if error != nil {
					promise.failure(error)
				} else {
					outError = NSError(domain: "com.baltoro.BrightFuturesTest1", code: 404, userInfo:[NSLocalizedDescriptionKey : "No routes found!"])
					promise.failure(outError!)
				}
			}
		}
		return promise.future
  }

  func fakeLocationFromRoute(route: MKRoute) -> FakeLocationsArray {
		var poleBodu = [CLLocation]()
		let pocetBodu = route.polyline.pointCount
		for i in 0..<pocetBodu {
			let coordinate = MKCoordinateForMapPoint(route.polyline.points()[i])
			poleBodu.append(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
		}
		
		return poleBodu
  }
  
		
  var srcItem: Future<MKMapItem> = obtainMapItemFromString("Pruhonice")
  var destItem: Future<MKMapItem> = obtainMapItemFromString("Jílove u Prahy")
  let itemSequence = [srcItem, destItem]
  
  let fut1: Future<[MKMapItem]> = FutureUtils.sequence(itemSequence)
  let fut2: Future<MKRoute> = fut1.flatMap { krajniBody -> Future<MKRoute> in
		return obtainRouteFrom(krajniBody[0], krajniBody[1])
  }
  let fut3: Future<FakeLocationsArray> = fut2.map { route -> FakeLocationsArray in
		return fakeLocationFromRoute(route)
  }
  
  return (fut2,fut3)
	}  // konec metody setupScenario

//	func navigationDataCalculation(route: MKRoute, currentLocation: CLLocation, distanceFilter: CLLocationDistance) -> NavigationData? {
//		let steps:[MKRouteStep] = route.steps as! [MKRouteStep]
//		for step in steps {
//			var pocet = step.polyline.pointCount
//			var coord = MKCoordinateForMapPoint(step.polyline.points()[pocet-1])
//			var location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
//			var distance = location.distanceFromLocation(currentLocation)
//			if distance < distanceFilter {
//				if coord.latitude != previousTurnPointCoord.latitude || coord.longitude != previousTurnPointCoord.longitude {
//					previousTurnPointCoord = coord
//					previousDistance = distance
//					return (distance, step.instructions)
//				} else if distance < previousDistance {
//					previousDistance = distance
//					return (distance, step.instructions)
//				}
//			}
//		}
//		return nil
//	}
	
	 func navigationDataCalculation(currentLocation: CLLocation, distanceFilter: CLLocationDistance) -> NavigationData? {
		var steps:[JSRouteStep] = myRoute.steps.filter {!$0.visited}
		for j in 0..<steps.count {
			var step = steps[j]
			var pocet = step.step.polyline.pointCount
			var coord = MKCoordinateForMapPoint(step.step.polyline.points()[pocet-1])
			var location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
			var distance = location.distanceFromLocation(currentLocation)
			if distance < distanceFilter {
				if coord.latitude != previousTurnPointCoord.latitude || coord.longitude != previousTurnPointCoord.longitude {
					previousTurnPointCoord = coord
					previousDistance = distance
					return (distance, step.step.instructions)
				} else if distance < previousDistance {
					previousDistance = distance
					return (distance, step.step.instructions)
				} else {
					var i = 0
					while i < myRoute.steps.count-1 && myRoute.steps[i].visited == true {
						i++
					}
					if i < myRoute.steps.count-1 { myRoute.steps[i].visited = true }
				}
			}
		}
		return nil
	}

}

func WayPointsFromMKRoute(route: MKRoute) -> [GPXWaypoint] {
  var pole = [GPXWaypoint]()
  let steps:[MKRouteStep] = route.steps as! [MKRouteStep]
  for step in steps {
    var pocet = step.polyline.pointCount
    var coord = MKCoordinateForMapPoint(step.polyline.points()[pocet-1])
    pole.append(GPXWaypoint(latitude: CGFloat(coord.latitude), longitude: CGFloat(coord.longitude)))
  }
  return pole
}

//FIXME: nechci radsi pouzivat MKRouteSteps?
func aktualniWaypoit(waypoints: [GPXWaypoint], location: CLLocation, distance: Double) -> GPXWaypoint? {
  return nil
}

func aktualniRouteStep(route: MKRoute, currentLocation: CLLocation, distanceFilter: Double) -> LocalPath {
  let steps:[MKRouteStep] = route.steps as! [MKRouteStep]
  for i in 0..<steps.count-1 {
    var pocet = steps[i].polyline.pointCount
    var coord = MKCoordinateForMapPoint(steps[i].polyline.points()[pocet-1])
    var location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
    if location.distanceFromLocation(currentLocation) < distanceFilter {
      return (steps[i], steps[i+1])
    }
  }
  return (nil, nil)
}



