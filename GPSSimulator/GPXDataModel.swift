//
//  GPXDataModel.swift
//  GPSSimulator
//
//  Created by Jaromir Siska on 14.04.15.
//  Copyright (c) 2015 Baltoro. All rights reserved.
//

import Foundation
import MapKit

func MKMapPointForWayPoint(point: GPXWaypoint) -> MKMapPoint {
  return MKMapPointForCoordinate(CLLocationCoordinate2DMake(Double(point.latitude), Double(point.longitude)))
}

class GPXDataModel {
  var trackPoints = [GPXTrackPoint]()
  var wayPoints = [GPXWaypoint]()
  var trackPointsAsMapPoints = [MKMapPoint]()
  var wayPointsAsMapPoints = [MKMapPoint]()
  
  init(filePath: String) {
    let (t,w) = self.loadGPXFile(filePath)
    self.trackPoints = t
    self.wayPoints = w
    self.trackPointsAsMapPoints = self.trackPoints.map(MKMapPointForWayPoint)
    self.wayPointsAsMapPoints = self.wayPoints.map(MKMapPointForWayPoint)
  }
  
  func loadGPXFile(filePath: String) -> ([GPXTrackPoint], [GPXWaypoint]) {
    let root = GPXParser.parseGPXAtPath(filePath)
    
    let track = root.tracks.first as! GPXTrack
    let segment = track.tracksegments.first as! GPXTrackSegment
    let trackpoints = segment.trackpoints as! [GPXTrackPoint]
    
    var waypoints = [GPXWaypoint]()
    let routes = root.routes
    if routes.count > 0 {
      let route = routes.first as! GPXRoute
      waypoints = route.routepoints as! [GPXWaypoint]
    }
    
    // Pridejme zacatek a konec cesty jako waypoints
    waypoints.insert(trackpoints.first!, atIndex: 0)
    waypoints.append(trackpoints.last!)
    
    return (trackpoints, waypoints)
  }
  
  
}
