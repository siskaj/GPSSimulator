//
//  LocationSimulator.swift
//  GPSSimulator
//
//  Created by Jaromir Siska on 02.02.15.
//  Copyright (c) 2015 Baltoro. All rights reserved.
//

import UIKit
import MapKit

let rad = 180/M_PI

func delay(delay:Double, closure:()->()) {
  dispatch_after(
    dispatch_time(
      DISPATCH_TIME_NOW,
      Int64(delay * Double(NSEC_PER_SEC))
    ),
    dispatch_get_main_queue(), closure)
}


class LocationSimulator: CLLocationManager {
    
  var previousLocation: CLLocation
  var currentLocation: CLLocation
  let mapView: MKMapView
  var bKeepRunning: Bool = true
  
  private var index: Int = 0
  private var updatingLocation: Bool?
  var fakeLocations: [CLLocation] = [CLLocation]()
  private var updateInterval: NSTimeInterval = 0.5
  
  init(mapView: MKMapView, filePath: String) {
    self.mapView = mapView
    let location = fakeLocations.first
    self.previousLocation = location!
    self.currentLocation = location!
    super.init()
    self.loadGPXFile(filePath)
  }
  
  init(mapView: MKMapView, fakeLocations: FakeLocationsArray) {
    self.mapView = mapView
    self.fakeLocations = fakeLocations
    let location = fakeLocations.first
    self.previousLocation = location!
    self.currentLocation = location!
    super.init()
  }
  
  func loadGPXFile(filePath: String) {
    let root = GPXParser.parseGPXAtPath(filePath)
    
    if let track = root.tracks.first as? GPXTrack {
      if let segment = track.tracksegments.first as? GPXTrackSegment {
        let trackpoints = segment.trackpoints as! [GPXTrackPoint]
        fakeLocations = trackpoints.map { trackpoint -> CLLocation in
          return CLLocation(latitude: Double(trackpoint.latitude), longitude: Double(trackpoint.longitude))
        }
      }
    }
  }
    
  func fakeNewLocation() {
    if currentLocation.distanceFromLocation(previousLocation) > distanceFilter {
      let loc = [previousLocation, currentLocation]
      delegate!.locationManager!(self as CLLocationManager, didUpdateLocations: loc)
      previousLocation = currentLocation
    }
    
//    (mapView.userLocation as MKAnnotation).setCoordinate(currentLocation.coordinate)
    if updatingLocation! {
      index++
      if index == fakeLocations.count {
        index = 0
        if !bKeepRunning {
          stopUpdatingLocation()
          updatingLocation! = false
        } else {
          currentLocation = fakeLocations[index]
        }
      } else {
        currentLocation = fakeLocations[index]
      }
      delay(updateInterval, closure: fakeNewLocation)
    }
  }

  override func startUpdatingLocation() {
    updatingLocation = true
    distanceFilter = 10.0
    currentLocation = fakeLocations.first!
    fakeNewLocation()
  }
    
  override func stopUpdatingHeading() {
    updatingLocation = false
  }
  
  func course(point1: CLLocation, point2: CLLocation) -> Double {
    var tcl: Double = 0
    let dlat = point2.coordinate.latitude - point1.coordinate.latitude
    let dlon = point2.coordinate.longitude - point1.coordinate.longitude
    let y = Double(sin(dlon)*cos(point2.coordinate.latitude))
    let x = Double(cos(point1.coordinate.latitude)*sin(point2.coordinate.latitude) - sin(point1.coordinate.latitude) * cos(point2.coordinate.latitude) * cos(dlon))
    if y > 0 {
      if x > 0 { tcl = rad * atan(y/x) }
      if x < 0 { tcl = 180 - rad * atan(-y/x) }
      if x == 0 { tcl = 90 }
    }
    if y < 0 {
      if x > 0 { tcl = -rad * atan(-y/x) }
      if x < 0 { tcl = rad * atan(y/x) - 180 }
      if x == 0 { tcl = 270 }
    }
    if y == 0 {
      if x > 0 { tcl = 0 }
      if x < 0 { tcl = 180 }
      if x == 0 { tcl = 0 }
    }
    return tcl
  }

  func course2(point1: CLLocation, point2:CLLocation) -> Double {
    var tcl: Double = 0
    let p1 = MKMapPointForCoordinate(point1.coordinate)
    let p2 = MKMapPointForCoordinate(point2.coordinate)
    let dx = p2.x - p1.x
    print("dx - \(dx)")
    let dy = p2.y - p1.y
    print("dy = \(dy), dx/dy = \(dx/dy), atan  = \(rad * atan(dx/dy))")
    if dx > 0 {
      if dy > 0 { tcl = rad * atan(dx/dy) }
      if dy < 0 { tcl = 180 - rad * atan(-dx/dy) }
      if dy == 0 { tcl = 90 }
    }
    if dx < 0 {
      if dy > 0 { tcl = -rad * atan(-dx/dy) }
      if dy < 0 { tcl = rad * atan(dx/dy) - 180 }
      if dy == 0 { tcl = 270 }
    }
    if dx == 0 {
      if dy >= 0 { tcl = 0 }
      if dy < 0 { tcl = 180 }
    }
    return tcl
  }

}
