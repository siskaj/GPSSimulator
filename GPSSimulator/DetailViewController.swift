//
//  DetailViewController.swift
//  BikeGPX_1
//
//  Created by Jaromir on 22.11.14.
//  Copyright (c) 2014 Jaromir. All rights reserved.
//

import UIKit
import MapKit

class DetailViewController: UIViewController {
    
  @IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var distanceLabel: UILabel!
//  var arrivingStep: MKRouteStep!
//  var leavingStep: MKRouteStep!
	
	var counter: Int = 0
	var creatingSnapshot: Bool
//	var azimut: CLLocationDirection {
//		didSet {
//			if abs(azimut - oldValue) < 10 { return }
//			if let arrivingStep = localPath.arrivingStep, leavingStep = localPath.leavingStep {
//				createSnapshotWithPath(arrivingStep, leavingStep: leavingStep)
//			} else { createSnapshot() }
//			(parentViewController as? ViewController)?.container.hidden = false
//		}
//	}
//	
	var localPath: LocalPath {
		didSet {
			if localPath.arrivingStep == oldValue.arrivingStep && localPath.leavingStep == oldValue.leavingStep { return }
			if let arrivingStep = localPath.arrivingStep, leavingStep = localPath.leavingStep {
				println("Zmena LocalPath")
//				createSnapshotWithPath(arrivingStep, leavingStep: leavingStep)
			} else { createSnapshot() }
			(parentViewController as? ViewController)?.container.hidden = false
		}
	}
	
  //    init(arrivingStep: MKRouteStep, leavingStep: MKRouteStep?) {
  //        self.arrivingStep = arrivingStep
  //        self.leavingStep = leavingStep
  //        super.init()
  //    }
  
    required init(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//			self.azimut = 0
			self.creatingSnapshot = false
			super.init(coder: aDecoder)
    }
	
  
//  func configureView() {
//    // Update the user interface for the detail item.
//    createSnapshotWithPath()
//  }
	
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
//    self.configureView()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  private func drawPath(points: [CGPoint], intoImage image: UIImage) -> UIImage {
    UIGraphicsBeginImageContext(image.size)
    image.drawAtPoint(CGPointZero)
    
//    let ctx = UIGraphicsGetCurrentContext()
    UIColor.redColor().setStroke()
    var path = UIBezierPath()
    path.moveToPoint(points[0])
    for i in 1..<points.count {
			// je nutne provest kontrolu, zda-li ty body vsechny existuji. Apple tam ma cas od casu chybu
			if !points[i].x.isNaN && !points[i].y.isNaN {
//			assert(!points[i].x.isNaN, "Problem")
	      path.addLineToPoint(points[i])
			}
    }
    path.lineWidth = 3
    //    CGContextStrokePath(ctx)
    path.stroke()
    let retImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return retImage
  }
	
	private func drawCurrentPosition(position: CGPoint, intoImage image: UIImage) -> UIImage {
		UIGraphicsBeginImageContext(image.size)
		image.drawAtPoint(CGPointZero)
		let leftPoint = CGPointMake(position.x - 10, position.y + 10)
		let rightPoint = CGPointMake(position.x + 10, position.y + 10)

		UIColor.greenColor().setStroke()
		var path = UIBezierPath()
		path.moveToPoint(position)
		path.addLineToPoint(rightPoint)
		path.addLineToPoint(leftPoint)
		path.closePath()
		
		path.lineWidth = 3
		path.stroke()
		let retImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return retImage
	}
	
	private func createSnapshot() {
		let options = MKMapSnapshotOptions()
		options.scale = UIScreen.mainScreen().scale
		options.size = view.frame.size
		
		let snapshotter = MKMapSnapshotter(options: options)
		snapshotter.startWithCompletionHandler({ (snapshot: MKMapSnapshot!, error: NSError!) -> Void in
			if error == nil {
				self.imageView.image = snapshot.image
			}
		})
	}
  
	private func createSnapshotWithPath(arrivingStep: MKRouteStep, leavingStep: MKRouteStep) {
		if creatingSnapshot { return }
		else { creatingSnapshot = true }
		// Vezmeme posledni bod z arrivingStep.polyline a vytvorme kolem neho vhodne? velky region
		let pocetArrivingBodu = arrivingStep.polyline.pointCount
		let pocetLeavingBodu = leavingStep.polyline.pointCount
		let bodZmenySmeru = arrivingStep.polyline.points()[pocetArrivingBodu-1]

		let options = MKMapSnapshotOptions()
    options.scale = UIScreen.mainScreen().scale
    options.size = view.frame.size
//		options.region = MKCoordinateRegionMakeWithDistance(MKCoordinateForMapPoint(bodZmenySmeru), 200.0, 200.0)
		
		options.camera = MKMapCamera(lookingAtCenterCoordinate: (parentViewController as! ViewController).currentLocation!.coordinate, fromEyeCoordinate: (parentViewController as! ViewController).oldLocation!.coordinate, eyeAltitude: 50)
		
		
    let snapshotter = MKMapSnapshotter(options: options)
		println("Counter: \(++counter)")
    snapshotter.startWithCompletionHandler({ (snapshot: MKMapSnapshot!, error: NSError!) -> Void in
      if error == nil {
        var poleBodu = [CGPoint]()
        for i in 0..<pocetArrivingBodu {
					poleBodu.append(snapshot.pointForCoordinate(MKCoordinateForMapPoint(arrivingStep.polyline.points()[i])))
				}
        for j in 0..<pocetLeavingBodu {
					poleBodu.append(snapshot.pointForCoordinate(MKCoordinateForMapPoint(leavingStep.polyline.points()[j])))
        }
				
				let currentPosition = snapshot.pointForCoordinate((parentViewController as! ViewController).currentLocation!.coordinate)
        let imageWithPath = self.drawPath(poleBodu, intoImage: snapshot.image)
        self.imageView.image = self.drawCurrentPosition(currentPosition, intoImage: imageWithPath)
				println("Counter: \(--self.counter)")
				self.creatingSnapshot = false
      }
    })
  }
	
	func createSnapshotWithPath(imageView: UIImageView, route: MKRoute, currentLocation: CLLocation, previousLocation: CLLocation) {
//		var retImage:UIImage?
		if creatingSnapshot { return }
		else { creatingSnapshot = true }
		
		if let navigationData = (parentViewController as! ViewController).viewControllerDataModel.navigationDataCalculation(currentLocation, distanceFilter: 200) {
			distanceLabel.text = "\(navigationData.distance)"
			distanceLabel.hidden = false
			println("Instruction - \(navigationData.instruction)")
		} else { distanceLabel.hidden = true }
		
		
//		let localPath = aktualniRouteStep(route, currentLocation, 200)
//		if let arrivingStep = localPath.arrivingStep {
//			let pocet = arrivingStep.polyline.pointCount
//			let coord = MKCoordinateForMapPoint(arrivingStep.polyline.points()[pocet-1])
//			let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
//			let distance = currentLocation.distanceFromLocation(location)
//			distanceLabel.text = "\(distance)m"
//			distanceLabel.hidden = false
//			println("Instruction - \(arrivingStep.instructions)")
//		} else { distanceLabel.hidden = true }
		
		let options = MKMapSnapshotOptions()
		options.scale = UIScreen.mainScreen().scale
		options.size = view.frame.size
		options.camera = MKMapCamera(lookingAtCenterCoordinate: currentLocation.coordinate, fromEyeCoordinate: previousLocation.coordinate, eyeAltitude: 500)
		
		let snapshotter = MKMapSnapshotter(options: options)
		snapshotter.startWithCompletionHandler({ (snapshot: MKMapSnapshot!, error: NSError!) -> Void in
			if error == nil {
				var poleBodu = [CGPoint]()
				for i in 0..<route.polyline.pointCount {
					poleBodu.append(snapshot.pointForCoordinate(MKCoordinateForMapPoint(route.polyline.points()[i])))
					}
				let currentPosition = snapshot.pointForCoordinate((parentViewController as! ViewController).currentLocation!.coordinate)
				let imageWithPath = self.drawPath(poleBodu, intoImage: snapshot.image)
				self.imageView.image = self.drawCurrentPosition(currentPosition, intoImage: imageWithPath)
				self.creatingSnapshot = false
			}
		})
//		return retImage
	}
}

