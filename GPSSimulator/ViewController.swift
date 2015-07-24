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
      aktualniRouteStep = aktualniRouteStepGenerator(route, filter: 30)
      detailViewController.route = route
      let configuration = Configuration.Directions(route)
      detailViewController.configureView(configuration)
    }
    
    // callback, ktery zavolam, pote co se najdou mista, cesta mezi nimi a vytvori FakeLocationArray
    func setupPole(fakeLocations: FakeLocationsArray) {
      locationManager = LocationSimulator(mapView: mapView, fakeLocations: fakeLocations)
      checkLocationAuthorizationStatus()

      mapView.showsUserLocation = true
      
      mapView.centerCoordinate = locationManager.fakeLocations.first!.coordinate
      mapView.delegate = self
      let region = MKCoordinateRegionMakeWithDistance(mapView.centerCoordinate, 1000, 1000)
      mapView.setRegion(region, animated: true)
      
      locationManager.delegate = self
      locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
      
      //FIXME: patri to sem? Mam pocit, ze bych to volal dvakrat
//      locationManager.startUpdatingLocation()
      
      delay(1, closure: locationManager.startUpdatingLocation)

    }
    
    super.viewDidLoad()
    
    if fromGPXFile {
      let path = NSBundle.mainBundle().pathForResource("AfternoonRide", ofType: "gpx")
      locationManager = LocationSimulator(mapView: mapView, filePath: path!)
      checkLocationAuthorizationStatus()
      
      mapView.showsUserLocation = true
      
      mapView.centerCoordinate = locationManager.fakeLocations.first!.coordinate
      mapView.delegate = self
      let region = MKCoordinateRegionMakeWithDistance(mapView.centerCoordinate, 1000, 1000)
      mapView.setRegion(region, animated: true)
      
      detailViewController.configureView(Configuration.GPX(path!))
      
      locationManager.delegate = self
      locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
      
      
      delay(10, closure: locationManager.startUpdatingLocation)

    } else {
      let (route,pole): (Future<MKRoute, NSError>,Future<FakeLocationsArray, NSError>) = setupScenario()
      route.onSuccess(callback:setupRoute)
      pole.onSuccess(callback: setupPole)
    }
    
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
      print("Volam segue pro container")
      detailViewController = segue.destinationViewController as! DetailViewController
    }
  }

}

//MARK: LocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {
  func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    checkLocationAuthorizationStatus()
  }
  
  func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    let oldLocation = locations.first
    let newLocation = locations.last
//    println("\(newLocation.course),  \(newLocation.speed)")
//    let actualSteps = aktualniRouteStep( newLocation!)
//    if let arrivingStep = actualSteps.0 {
//      
//    }
    updateMap(oldLocation, newLocation: newLocation)
    updateMapDetail(oldLocation, newLocation: newLocation, filter: 50)
  }
  
  func updateMap(oldLocation: CLLocation?, newLocation: CLLocation?) {
    if let theNewLocation = newLocation, theOldLocation = oldLocation {
//      println("\(theNewLocation.course),  \(theNewLocation.speed)")
      if oldLocation?.coordinate.latitude != theNewLocation.coordinate.latitude || oldLocation?.coordinate.longitude != theNewLocation.coordinate.longitude {
        let region = MKCoordinateRegionMakeWithDistance(theNewLocation.coordinate, 100, 100)
        mapView.setRegion(region, animated: true)
        let camera = MKMapCamera(lookingAtCenterCoordinate: theNewLocation.coordinate, fromEyeCoordinate: theOldLocation.coordinate, eyeAltitude: 800.0)
        mapView.setCamera(camera, animated: true)
//        var camera = mapView.camera
//        camera.heading = locationManager.course(oldLocation!, point2: newLocation!)
//        mapView.setCamera(camera, animated: true)
      }
    }
  }
  
  func updateMapDetail(oldLocation: CLLocation?, newLocation: CLLocation?, filter: Double) {
//    if newLocation?.distanceFromLocation(oldLocation) < filter {
//      return
//    }
    if let newLocation = newLocation, oldLocation = oldLocation  {
      let camera = MKMapCamera(lookingAtCenterCoordinate: newLocation.coordinate, fromEyeCoordinate: oldLocation.coordinate, eyeAltitude: 200.0)
//      mapView.setCamera(camera, animated: true)
      detailViewController.drawCompleteRoute(detailViewController.gpxDataModel.trackPoints, currentPosition: newLocation, camera: camera, mod: .Scale(200))
    }
  }
}

