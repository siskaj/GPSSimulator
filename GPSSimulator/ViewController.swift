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
import GPSSimulatorKit2

//class DirectionVector: NSObject, NSCoding {
//	let oldLoc: CLLocation
//	let newLoc: CLLocation
//	
//	init(old: CLLocation, new: CLLocation) {
//		self.oldLoc = old
//		self.newLoc = new
//	}
//	
//	required init(coder aDecoder: NSCoder) {
//		oldLoc = aDecoder.decodeObjectForKey("oldLocation") as! CLLocation
//		newLoc = aDecoder.decodeObjectForKey("newLocation") as! CLLocation
//	}
//	
//	func encodeWithCoder(aCoder: NSCoder) {
//		aCoder.encodeObject(oldLoc, forKey: "oldLocation")
//		aCoder.encodeObject(newLoc, forKey: "newLocation")
//	}
//}

class ViewController: UIViewController, MKMapViewDelegate {
  
  @IBOutlet weak var container: UIView!
  @IBOutlet weak var mapView: MKMapView!
  var locationManager: LocationSimulator!
  var fakeLocations: FakeLocationsArray = [CLLocation]()
  var route: MKRoute!
  var detailViewController: DetailViewController!
	var gpxDataModel: GPXDataModel!
	
	var myDefaults: NSUserDefaults!
	var wormHole: MMWormhole!
  
  var aktualniRouteStep: ((CLLocation) -> (MKRouteStep?, MKRouteStep?))!
  
  override func viewDidLoad() {
    func setupRoute(route: MKRoute) {
      self.route = route
      aktualniRouteStep = aktualniRouteStepGenerator(route, 30)
      detailViewController.route = route
      var configuration = Configuration.Directions(route)
      detailViewController.configureView(configuration)
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
      
      delay(1, locationManager.startUpdatingLocation)

    }
    
    super.viewDidLoad()
		myDefaults = NSUserDefaults(suiteName: "group.com.baltoro.GPSSimulator")
		wormHole = MMWormhole(applicationGroupIdentifier: "group.com.baltoro.GPSSimulator", optionalDirectory: nil)
		
		
    
    if fromGPXFile {
      let path = NSBundle.mainBundle().pathForResource("AfternoonRide", ofType: "gpx")
      locationManager = LocationSimulator(mapView: mapView, filePath: path!)
      checkLocationAuthorizationStatus()
      
      mapView.showsUserLocation = true
      
      mapView.centerCoordinate = locationManager.fakeLocations.first!.coordinate
      mapView.delegate = self
      var region = MKCoordinateRegionMakeWithDistance(mapView.centerCoordinate, 1000, 1000)
      mapView.setRegion(region, animated: true)
      
      detailViewController.configureView(Configuration.GPX(path!))
			
			gpxDataModel = GPXDataModel(filePath: path!)
			
			// Pomoci sharedUserDefaults posli predej GPX data WatchKit aplikaci
			let identifier = "group.com.baltoro.GPSSimulator"
			var sharedUserDefaults = NSUserDefaults(suiteName: identifier)
			if let sharedUserDefaults = sharedUserDefaults {
				sharedUserDefaults.setObject(gpxDataModel.trackPoints, forKey: "trackPoints")
			}
      
      locationManager.delegate = self
      locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
      
      
      delay(10, locationManager.startUpdatingLocation)

    } else {
      let (route,pole): (Future<MKRoute>,Future<FakeLocationsArray>) = setupScenario()
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
    if let oldLocation = locations.first as? CLLocation,
			let newLocation = locations.last as? CLLocation {
//    println("\(newLocation.course),  \(newLocation.speed)")
//    let actualSteps = aktualniRouteStep( newLocation!)
//    if let arrivingStep = actualSteps.0 {
//      
//    }
		
				let directionVector = DirectionVector(old: oldLocation, new: newLocation)
			wormHole.passMessageObject(directionVector, identifier: "Direction")
//			wormHole.passMessageObject(oldLocation, identifier: "OldLocation")
//			wormHole.passMessageObject(newLocation, identifier: "NewLocation")
			updateMap(oldLocation, newLocation: newLocation)
			updateMapDetail(oldLocation, newLocation: newLocation, filter: 50)
		}
  }
  
  func updateMap(oldLocation: CLLocation?, newLocation: CLLocation?) {
    if let theNewLocation = newLocation, theOldLocation = oldLocation {
//      println("\(theNewLocation.course),  \(theNewLocation.speed)")
      if oldLocation?.coordinate.latitude != theNewLocation.coordinate.latitude || oldLocation?.coordinate.longitude != theNewLocation.coordinate.longitude {
        let region = MKCoordinateRegionMakeWithDistance(theNewLocation.coordinate, 100, 100)
        mapView.setRegion(region, animated: true)
        var camera = MKMapCamera(lookingAtCenterCoordinate: theNewLocation.coordinate, fromEyeCoordinate: theOldLocation.coordinate, eyeAltitude: 800.0)
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
      var camera = MKMapCamera(lookingAtCenterCoordinate: newLocation.coordinate, fromEyeCoordinate: oldLocation.coordinate, eyeAltitude: 200.0)
//      mapView.setCamera(camera, animated: true)
      detailViewController.drawCompleteRoute(detailViewController.gpxDataModel.trackPoints, currentPosition: newLocation, camera: camera, mod: .Scale(200))
    }
  }
}

