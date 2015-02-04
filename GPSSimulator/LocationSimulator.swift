//
//  LocationSimulator.swift
//  GPSSimulator
//
//  Created by Jaromir Siska on 02.02.15.
//  Copyright (c) 2015 Baltoro. All rights reserved.
//

import UIKit
import MapKit

func dispatch_after_delay(delay: NSTimeInterval, queue: dispatch_queue_t, block: dispatch_block_t) {
  let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
  dispatch_after(time, queue, block)
}

class LocationSimulator: CLLocationManager {
  
  class var shared: LocationSimulator {
    
    struct Static {
      static let instance : LocationSimulator = LocationSimulator()
    }
    
    return Static.instance
  }
  
  var previousLocation: CLLocation?
  var currentLocation: CLLocation?
  var aMapView: MKMapView?
  var bKeepRunning: Bool?
  
  private var index: Int = 0
  private var updatingLocation: Bool?
  private var fakeLocations: [CLLocation]!
  private var updateInterval: NSTimeInterval = 0.3
  
  private var conQueue: dispatch_queue_t!
  
  
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
    previousLocation = previousLocation ?? currentLocation
    if currentLocation?.distanceFromLocation(previousLocation) > distanceFilter {
      let loc = [previousLocation!, currentLocation!]
      delegate.locationManager!(self, didUpdateLocations: loc)
      previousLocation! = currentLocation!
    }
    
    if let theMapView = aMapView {
      theMapView.userLocation.setCoordinate(currentLocation!.coordinate)
    }
    if updatingLocation! {
      index++
      if index == fakeLocations.count {
        index = 0
        if !bKeepRunning! {
          stopUpdatingLocation()
          updatingLocation! = false
        } else {
          currentLocation = fakeLocations[index]
        }
      } else {
        currentLocation = fakeLocations[index]
      }
      dispatch_after_delay(updateInterval, conQueue, fakeNewLocation)
    }
  }

  override func startUpdatingLocation() {
    conQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
    updatingLocation = true
    distanceFilter = 30.0
    currentLocation = fakeLocations.first
    fakeNewLocation()
  }
    
  override func stopUpdatingHeading() {
    updatingLocation = false
  }
}
