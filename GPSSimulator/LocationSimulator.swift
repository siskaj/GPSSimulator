//
//  LocationSimulator.swift
//  GPSSimulator
//
//  Created by Jaromir Siska on 02.02.15.
//  Copyright (c) 2015 Baltoro. All rights reserved.
//

import UIKit
import MapKit

func delay(delay:Double, closure:()->()) {
  dispatch_after(
    dispatch_time(
      DISPATCH_TIME_NOW,
      Int64(delay * Double(NSEC_PER_SEC))
    ),
    dispatch_get_main_queue(), closure)
}


class LocationSimulator: CLLocationManager {
    
  var previousLocation: CLLocation!
  var currentLocation: CLLocation!
  let mapView: MKMapView
  var bKeepRunning: Bool = true
  
  private var index: Int = 0
  private var updatingLocation: Bool?
  var fakeLocations: [CLLocation] = [CLLocation]()
  private var updateInterval: NSTimeInterval = 2.0
  
  init(mapView: MKMapView, filePath: String) {
    self.mapView = mapView
    super.init()
    self.loadGPXFile(filePath)
    let location = fakeLocations.first
    self.previousLocation = location!
    self.currentLocation = location!
  }
  
  func loadGPXFile(filePath: String) {
    let root = GPXParser.parseGPXAtPath(filePath)
    
    if let track = root.tracks.first as? GPXTrack {
      if let segment = track.tracksegments.first as? GPXTrackSegment {
        let trackpoints = segment.trackpoints as [GPXTrackPoint]
        fakeLocations = trackpoints.map { trackpoint -> CLLocation in
          return CLLocation(latitude: Double(trackpoint.latitude), longitude: Double(trackpoint.longitude))
        }
      }
    }
  }
    
  func fakeNewLocation() {
    if currentLocation.distanceFromLocation(previousLocation) > distanceFilter {
      let loc = [previousLocation, currentLocation]
      delegate.locationManager!(self, didUpdateLocations: loc)
      previousLocation = currentLocation
    }
    
      mapView.userLocation.setCoordinate(currentLocation.coordinate)
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
      delay(updateInterval, fakeNewLocation)
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
}
