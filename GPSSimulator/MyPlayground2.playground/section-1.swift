// Playground - noun: a place where people can play

import UIKit
import GPX
import MapKit


var str = "Hello, playground"

let filePath = NSBundle.mainBundle().pathForResource("Afternoon Ride", ofType: "gpx")
//let filePath = NSBundle.mainBundle().pathForResource("1_Ammergauer", ofType: "gpx")


let root = GPXParser.parseGPXAtPath(filePath)

let myTrack = root.tracks[0] as! GPXTrack

let name = myTrack.name
let segment = myTrack.tracksegments[0] as! GPXTrackSegment

var trackpoints: [GPXWaypoint] = segment.trackpoints as! [GPXWaypoint]

let rad = 180/M_PI

func course(point1: GPXWaypoint, point2:GPXWaypoint) -> Double {
  var tcl: Double = 0
  let dlat = point2.latitude - point1.latitude
  let dlon = point2.longitude - point1.longitude
  let y = Double(sin(dlon)*cos(point2.latitude))
  let x = Double(cos(point1.latitude)*sin(point2.latitude) - sin(point1.latitude) * cos(point2.latitude) * cos(dlon))
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


func course2(point1: GPXWaypoint, point2:GPXWaypoint) -> Double {
  var tcl: Double = 0
  let p1 = MKMapPointForCoordinate(CLLocationCoordinate2DMake(Double(point1.latitude), Double(point1.longitude)))
  let p2 = MKMapPointForCoordinate(CLLocationCoordinate2DMake(Double(point2.latitude), Double(point2.longitude)))
  let dx = p2.x - p1.x
  println("dx - \(dx)")
  let dy = p2.y - p1.y
  println("dy = \(dy), dx/dy = \(dx/dy), atan  = \(rad * atan(dx/dy))")
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

var azimut: [Double] = [Double]()
for i in 0...200
 {  azimut.append(course2(trackpoints[1*i], trackpoints[1*(i+1)]))
//  println("Body 1:\(trackpoints[20*i].longitude), \(trackpoints[20*i].latitude)")
}
println("\(azimut)