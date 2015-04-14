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
  
  var aktualniRouteStep: ((CLLocation) -> (MKRouteStep?, MKRouteStep?))!
  
  override func viewDidLoad() {
    func setupRoute(route: MKRoute) {
      self.route = route
      aktualniRouteStep = aktualniRouteStepGenerator(route, 30)
      detailViewController.route = route
      detailViewController.configureView()
    }
    
    // callback, ktery zavolam, pote co se najdou mista, cesta mezi nimi a vytvori FakeLocationArray
    func setupPole(fakeLocations: FakeLocationsArray) {
      locationManager = LocationSimulator(mapView: mapView, fakeLocations: fakeLocations)
      checkLocationAuthorizationStatus()

      mapView.showsUserLocation = true
      
      mapView.centerCoordinate = locationManager.fakeLocations.first!.coordinate
      mapView.delegate = self
      var region = MKCoordinateRegionMakeWithDistance(mapView.centerCoordinate, 1000, 1000)
      mapView.setRegion(region, animated: true)
      
      locationManager.delegate = self
      locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
      
      //FIXME: patri to sem? Mam pocit, ze bych to volal dvakrat
//      locationManager.startUpdatingLocation()
      
      delay(10, locationManager.startUpdatingLocation)

    }
    
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
//    checkLocationAuthorizationStatus()
  }


  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "container" {
      println("Volam segue pro container")
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
    let newLocation = locations.last as? CLLocation
    let actualSteps = aktualniRouteStep( newLocation!)
    if let arrivingStep = actualSteps.0 {
      
    }
    updateMap(oldLocation, newLocation: newLocation)
  }
  
  func updateMap(oldLocation: CLLocation?, newLocation: CLLocation?) {
    if let theNewLocation = newLocation {
      if oldLocation?.coordinate.latitude != theNewLocation.coordinate.latitude || oldLocation?.coordinate.longitude != theNewLocation.coordinate.longitude {
        let region = MKCoordinateRegionMakeWithDistance(theNewLocation.coordinate, 100, 100)
        mapView.setRegion(region, animated: true)
        var camera = mapView.camera
        camera.heading = locationManager.course(oldLocation!, point2: newLocation!)
        mapView.setCamera(camera, animated: true)
      }
    }
  }
}

