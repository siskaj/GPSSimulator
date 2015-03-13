// Playground - noun: a place where people can play

import UIKit
import MapKit
import XCPlayground

XCPSetExecutionShouldContinueIndefinitely(continueIndefinitely: true)

var str = "Hello, playground"

let location = CLLocationCoordinate2DMake(50.004013, 14.548071)

let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
let region = MKCoordinateRegion(center: location, span: span)

func CenterOfMapToLocation(location: CLLocationCoordinate2D) -> MKMapView {	var mapView = MKMapView(frame: CGRectMake(0.0, 0.0, 300.0, 300.0))
//	mapView.setRegion(region, animated: true)
	return mapView}

var map1:MKMapView = CenterOfMapToLocation(location)
//
//XCPShowView("mapa", map1)
//
//func imageFromMap(map: UIView) -> UIImage {
//	UIGraphicsBeginImageContext(map.frame.size)
//	map.layer.renderInContext(UIGraphicsGetCurrentContext())
//	var viewImage = UIGraphicsGetImageFromCurrentImageContext()
//	UIGraphicsEndImageContext()
//	return viewImage
//}
//
//var img = imageFromMap(map1)
//
//var imgView = UIImageView(image: img)
//
//XCPShowView("image", imgView)
//
//var view1 = UIView(frame: CGRectMake(0, 0, 200, 200))
//XCPShowView("view1", view1)
//view1.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
//
//var img2 = imageFromMap(view1)
//imgView.image = img2
