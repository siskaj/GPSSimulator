//
//  ViewController.swift
//  GPSSimulator
//
//  Created by Jaromir Siska on 02.02.15.
//  Copyright (c) 2015 Baltoro. All rights reserved.
//

import UIKit
import MapKit
import BrightFutures

class ViewController: UIViewController, MKMapViewDelegate {

  @IBOutlet weak var container: UIView!
  @IBOutlet weak var mapView: MKMapView!
  var locationManager: LocationSimulator!
  var fakeLocations: FakeLocationsArray = [CLLocation]()
  var route: MKRoute!
	var detailViewController: DetailViewController!
	
	var currentLocation: CLLocation?
  
  override func viewDidLoad() {
    func setupRoute(route: MKRoute) {
      self.route = route
    }
    
    // callback, ktery zavolam, pote co se najdou mista, cesta mezi nimi a vytvori FakeLocationArray
    func setupPole(fakeLocations: FakeLocationsArray) {
      locationManager = LocationSimulator(mapView: mapView, fakeLocations: fakeLocations)
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
		
		locationManager = LocationSimulator(mapView: mapView)
    super.viewDidLoad()
    
    let (route,pole): (Future<MKRoute>,Future<FakeLocationsArray>) = setupScenario()
    route.onSuccess(callback:setupRoute)
    pole.onSuccess(callback: setupPole)
    
//    locationManager = LocationSimulator(mapView: mapView, filePath: NSBundle.mainBundle().pathForResource("Afternoon Ride", ofType: "gpx")!)
    
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

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "showDetail" {
			detailViewController = segue.destinationViewController as! DetailViewController
		}
	}
}

//MARK: LocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {
  func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    checkLocationAuthorizationStatus()
  }
  
  func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
    let oldLocation = locations.first as? CLLocation
    currentLocation = locations.last as? CLLocation
    updateMap(oldLocation, newLocation: currentLocation)
		detailViewController.localPath = aktualniRouteStep(route, currentLocation!, 1000)
  }
  
  func updateMap(oldLocation: CLLocation?, newLocation: CLLocation?) {
    if let theNewLocation = newLocation {
      if oldLocation?.coordinate.latitude != theNewLocation.coordinate.latitude || oldLocation?.coordinate.longitude != theNewLocation.coordinate.longitude {
        let region = MKCoordinateRegionMakeWithDistance(theNewLocation.coordinate, 100, 100)
        mapView.setRegion(region, animated: true)
        var camera = mapView.camera
				detailViewController.azimut = locationManager.course(oldLocation!, point2: newLocation!)
				camera.heading = detailViewController.azimut
        mapView.setCamera(camera, animated: true)
      }
    }
  }
}

