//
//  DetailViewController.swift
//  BikeGPX_1
//
//  Created by Jaromir on 22.11.14.
//  Copyright (c) 2014 Jaromir. All rights reserved.
//

import UIKit
import MapKit

func drawPath(points: [CGPoint], intoImage image: UIImage, curLocation location: CGPoint?) -> UIImage {
  UIGraphicsBeginImageContext(image.size)
  image.drawAtPoint(CGPointZero)
  
  //    let ctx = UIGraphicsGetCurrentContext()
  UIColor.redColor().setStroke()
  var path = UIBezierPath()
  path.moveToPoint(points[0])
  for i in 1..<points.count {
    path.addLineToPoint(points[i])
  }
  path.lineWidth = 3
  //    CGContextStrokePath(ctx)
  path.stroke()
  
  if let location = location {
    let pin = MKPinAnnotationView(annotation: nil, reuseIdentifier: nil)
    pin.image!.drawAtPoint(location)
  }
  
  let retImage = UIGraphicsGetImageFromCurrentImageContext()
  UIGraphicsEndImageContext()
  return retImage
}

enum Configuration {
  case GPX(String)
  case Directions(MKRoute)
}

enum Mode {
  case Scale(Double)
  case FullTrack
}

class DetailViewController: UIViewController {
    
  @IBOutlet weak var imageView: UIImageView!
  var arrivingStep: MKRouteStep!
  var leavingStep: MKRouteStep!
  var route: MKRoute?
  var gpxDataModel: GPXDataModel!
  
//    init(arrivingStep: MKRouteStep, leavingStep: MKRouteStep?) {
//        self.arrivingStep = arrivingStep
//        self.leavingStep = leavingStep
//        super.init()
//    }
//
//    required init(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
  
  
  func configureView(configuration: Configuration) {
    // Update the user interface for the detail item.
    switch configuration {
    case .GPX(let path):
      gpxDataModel = GPXDataModel(filePath: path)
      drawCompleteRoute(gpxDataModel.trackPoints,currentPosition: nil,camera: nil, mod: .FullTrack)
    case .Directions(let route):
      createSnapshotForRouteStep(route, prichod: nil, odchod: nil, currentPosition: nil)
    default:
      break
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
//    self.configureView()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  
  private func createSnapshotWithPath() {
    let options = MKMapSnapshotOptions()
    options.scale = UIScreen.mainScreen().scale
    options.size = view.frame.size
    
    // Vezmeme posledni bod z arrivingStep.polyline a vytvorme kolem neho vhodne? velky region
    let pocetArrivingBodu = arrivingStep.polyline.pointCount
    let pocetLeavingBodu = leavingStep.polyline.pointCount
    let bodZmenySmeru = arrivingStep.polyline.points()[pocetArrivingBodu-1]
        options.region = MKCoordinateRegionMakeWithDistance(MKCoordinateForMapPoint(bodZmenySmeru), 200.0, 200.0)
    
    let snapshotter = MKMapSnapshotter(options: options)
    snapshotter.startWithCompletionHandler({ (snapshot: MKMapSnapshot?, error: NSError?) -> Void in
      if error == nil {
        if let snapshot = snapshot {
          var poleBodu = [CGPoint]()
          for i in 0..<pocetArrivingBodu {
            poleBodu.append(snapshot.pointForCoordinate(MKCoordinateForMapPoint(self.arrivingStep.polyline.points()[i])))
          }
          for j in 0..<pocetLeavingBodu {
            poleBodu.append(snapshot.pointForCoordinate(MKCoordinateForMapPoint(self.leavingStep.polyline.points()[j])))
          }
          
          //FIXME: tady curLocation ma asi neco rozumneho byt
          self.imageView.image = drawPath(poleBodu, intoImage: snapshot.image, curLocation: CGPointZero)
        }
      }
    })
  }
  
  // Pokud step == nil, vytvori Snapshot pro celou route.
  // Pokud step != nil vytvori Snapshot pro step v takovem meritku, aby byla videte currentLocation a konec pro step (end of step)
  private func createSnapshotForRouteStep(route: MKRoute, prichod: MKRouteStep?, odchod: MKRouteStep?, currentPosition: CLLocation?) {
    let options = MKMapSnapshotOptions()
    options.scale = UIScreen.mainScreen().scale
    options.size = view.frame.size
    if (prichod == nil && odchod == nil)  {  // zobrazi se cela route; tahle situace muze nastat na zacatku, kdyz jeste jsem mimo route anebo pote co jsem prosel cilem
      let pocet = route.polyline.pointCount
      var poleBodu = [MKMapPoint]()
      for i in 0..<pocet {
        poleBodu.append(route.polyline.points()[i])
      }
      options.region = CoordinateRegionBoundingMapPoints(poleBodu)
      let snapshotter = MKMapSnapshotter(options: options)
      snapshotter.startWithCompletionHandler({ (snapshot: MKMapSnapshot?, error: NSError?) -> Void in
        //TODO:
      })

    } else if (prichod != nil && odchod == nil) { // blizim se k cili; prakticky stejny, jako posledni pripad; sjednotit
      
    } else if (prichod == nil && odchod != nil) { // blizim se na start; zobrazi se vychozi bod cesty,
      // curLocation a vychozi usek trajektorie; (Vychozi bod cesty a curLocation by mely urcit meritko, vychozi usek trajektorie bude cast cele trajektorie, ktera se vejde do zobrazeneho regionu
      
    } else if (prichod != nil && odchod != nil) { // zobrazi se bodObratu a curLocation a cast route v
      // odpovidajicim meritku
      let pocetBoduPrichod = prichod!.polyline.pointCount
      let bodObratu = prichod!.polyline.points()[pocetBoduPrichod - 1]
      let bodObratuCoordinate = MKCoordinateForMapPoint(bodObratu)
      let bodObratuLocation = CLLocation(latitude: bodObratuCoordinate.latitude, longitude: bodObratuCoordinate.longitude)
      let distance = bodObratuLocation.distanceFromLocation(currentPosition!)
      options.region = MKCoordinateRegionMakeWithDistance(bodObratuCoordinate, 2.0 * distance, 2.0 * distance)
      let snapshotter = MKMapSnapshotter(options: options)
      
    }
  }
  
  func drawCompleteRoute(trackPoints: [GPXTrackPoint], currentPosition: CLLocation?, camera: MKMapCamera?, mod: Mode) {
    let options = MKMapSnapshotOptions()
    options.scale = UIScreen.mainScreen().scale
    options.size = imageView.frame.size
    
    switch mod {
    case .FullTrack:
      //    let curPositionAsMapPoint = MKMapPointForCoordinate(currentPosition.coordinate)
      var allPoints = trackPoints.map(MKMapPointForWayPoint)
      //    allPoints.append(curPositionAsMapPoint)
      options.mapRect = MapRectBoundingMapPoints(allPoints)
    case .Scale(let scale):
//      options.region = MKCoordinateRegionMakeWithDistance(currentPosition!.coordinate, scale, scale)
      if let camera_ = camera {
        options.camera = camera_
      }
    }
    
    let snapshotter = MKMapSnapshotter(options: options)
    snapshotter.startWithCompletionHandler({ (snapshot: MKMapSnapshot?, error: NSError?) -> Void in
      if error == nil {
        if let snapshot = snapshot {
          var poleBodu = trackPoints.map { snapshot.pointForCoordinate(CLLocationCoordinate2DMake(Double($0.latitude), Double($0.longitude))) }
          // Nutne zkontrolovat; nektere body to konvertuje na NaN
          poleBodu = poleBodu.filter { !($0.x.isNaN || $0.y.isNaN) }
          if let currentPosition = currentPosition {
            self.imageView.image = drawPath(poleBodu, intoImage: snapshot.image, curLocation: snapshot.pointForCoordinate(currentPosition.coordinate))
          } else {
            self.imageView.image = drawPath(poleBodu, intoImage: snapshot.image, curLocation: nil)
          }
        }
      }
    })
  }

}

