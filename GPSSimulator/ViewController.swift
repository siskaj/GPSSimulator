//
//  ViewController.swift
//  GPSSimulator
//
//  Created by Jaromir Siska on 02.02.15.
//  Copyright (c) 2015 Baltoro. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate {

  @IBOutlet weak var mapView: MKMapView!
  var locationManager: LocationSimulator!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    locationManager = LocationSimulator(mapView: mapView, filePath: NSBundle.mainBundle().pathForResource("Afternoon Ride", ofType: "gpx")!)
    
    mapView.showsUserLocation = true
    
    mapView.centerCoordinate = locationManager.fakeLocations.first!.coordinate
    mapView.delegate = self
    var region = MKCoordinateRegionMakeWithDistance(mapView.centerCoordinate, 1000, 1000)
    mapView.setRegion(region, animated: true)
    
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    
    locationManager.startUpdatingLocation()
    
    delay(60, locationManager.startUpdatingLocation)
  }
  
  private func checkLocationAuthorizationStatus() {
    if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
      self.mapView.showsUserLocation = true
    } else {
      self.locationManager.requestWhenInUseAuthorization()
    }
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    checkLocationAuthorizationStatus()
  }


  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

//MARK: LocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {
  func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    checkLocationAuthorizationStatus()
  }
  
  func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
    let oldLocation = locations.first as? CLLocation
    let newLocation = locations.last as? CLLocation
    updateMap(oldLocation, newLocation: newLocation)
  }
  
  func updateMap(oldLocation: CLLocation?, newLocation: CLLocation?) {
    if let theNewLocation = newLocation {
      if oldLocation?.coordinate.latitude != theNewLocation.coordinate.latitude || oldLocation?.coordinate.longitude != theNewLocation.coordinate.longitude {
        let region = MKCoordinateRegionMakeWithDistance(theNewLocation.coordinate, 100, 100)
        mapView.setRegion(region, animated: true)
      }
    }
  }
}

