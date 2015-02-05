//
//  ViewControllerDataModel.swift
//  GPSSimulator
//
//  Created by Jaromir Siska on 04.02.15.
//  Copyright (c) 2015 Baltoro. All rights reserved.
//

import Foundation
import MapKit

func fakeLocationFromRoute(route: MKRoute) -> [CLLocation] {
  var poleBodu = [CLLocation]()
  let pocetBodu = route.polyline.pointCount
  for i in 0..<pocetBodu {
    let coordinate = MKCoordinateForMapPoint(route.polyline.points()[i])
    poleBodu.append(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
  }
  
  return poleBodu
}
