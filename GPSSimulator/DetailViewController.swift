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
//  var arrivingStep: MKRouteStep!
//  var leavingStep: MKRouteStep!
	
	var azimut: CLLocationDirection {
		didSet {
			if abs(azimut - oldValue) < 10 { return }
			if let arrivingStep = localPath.arrivingStep, leavingStep = localPath.leavingStep {
				createSnapshotWithPath(arrivingStep, leavingStep: leavingStep)
			} else { createSnapshot() }
			(parentViewController as? ViewController)?.container.hidden = false
		}
	}
	
	var localPath: LocalPath {
		didSet {
			if localPath.arrivingStep == oldValue.arrivingStep && localPath.leavingStep == oldValue.leavingStep { return }
			if let arrivingStep = localPath.arrivingStep, leavingStep = localPath.leavingStep {
				createSnapshotWithPath(arrivingStep, leavingStep: leavingStep)
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
			self.azimut = 0
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
      path.addLineToPoint(points[i])
    }
    path.lineWidth = 3
    //    CGContextStrokePath(ctx)
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
		// Vezmeme posledni bod z arrivingStep.polyline a vytvorme kolem neho vhodne? velky region
		let pocetArrivingBodu = arrivingStep.polyline.pointCount
		let pocetLeavingBodu = leavingStep.polyline.pointCount
		let bodZmenySmeru = arrivingStep.polyline.points()[pocetArrivingBodu-1]

		let options = MKMapSnapshotOptions()
    options.scale = UIScreen.mainScreen().scale
    options.size = view.frame.size
//		options.region = MKCoordinateRegionMakeWithDistance(MKCoordinateForMapPoint(bodZmenySmeru), 200.0, 200.0)
		
		options.camera = MKMapCamera(lookingAtCenterCoordinate: MKCoordinateForMapPoint(bodZmenySmeru), fromEyeCoordinate: (parentViewController as! ViewController).currentLocation!.coordinate, eyeAltitude: 50)
		
		
    let snapshotter = MKMapSnapshotter(options: options)
    snapshotter.startWithCompletionHandler({ (snapshot: MKMapSnapshot!, error: NSError!) -> Void in
      if error == nil {
        var poleBodu = [CGPoint]()
        for i in 0..<pocetArrivingBodu {
          poleBodu.append(snapshot.pointForCoordinate(MKCoordinateForMapPoint(arrivingStep.polyline.points()[i])))
        }
        for j in 0..<pocetLeavingBodu {
          poleBodu.append(snapshot.pointForCoordinate(MKCoordinateForMapPoint(leavingStep.polyline.points()[j])))
        }
        
        
        self.imageView.image = self.drawPath(poleBodu, intoImage: snapshot.image)
        
      }
    })
  }
}

