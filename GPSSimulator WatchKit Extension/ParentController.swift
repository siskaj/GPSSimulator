//
//  ParentController.swift
//  GPSSimulator
//
//  Created by Jaromir on 25.04.15.
//  Copyright (c) 2015 Baltoro. All rights reserved.
//

import WatchKit
import Foundation
import BrightFutures
import GPSSimulatorKit2


class ParentController: WKInterfaceController {
	var trackPoints: [CLLocation]?

	@IBOutlet weak var mapImage: WKInterfaceImage!
	
	override init() {
		
		let identifier = "group.com.baltoro.GPSSimulator"
		var sharedUserDefaults = NSUserDefaults(suiteName: identifier)
		if let sharedUserDefaults = sharedUserDefaults {
			if let data = sharedUserDefaults.objectForKey("trackPoints") as? NSData {
				trackPoints = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [CLLocation]
			}
		}
		
		super.init()
	}
	override func awakeWithContext(context: AnyObject?) {
			super.awakeWithContext(context)
			
			// Configure interface objects here.
	}

	override func willActivate() {
			// This method is called when watch view controller is about to be visible to user
			super.willActivate()
	}

	override func didDeactivate() {
			// This method is called when watch view controller is no longer visible
			super.didDeactivate()
	}

	func fetchSnapshot(options: MKMapSnapshotOptions) -> Future<MKMapSnapshot> {
		let promise = Promise<MKMapSnapshot>()
		let snapshotter = MKMapSnapshotter(options: options)
		snapshotter.startWithCompletionHandler { (snapshot: MKMapSnapshot!, error: NSError!) -> Void in
			if error == nil {
				promise.success(snapshot)
			} else {
				promise.failure(error)
			}
		}
		return promise.future
	}
	
	func drawRouteWithTrackPoints(trackPoints: [CLLocation], directionVector: DirectionVector?)(snapshot: MKMapSnapshot)  -> UIImage {
		var poleBodu = trackPoints.map { snapshot.pointForCoordinate($0.coordinate) }
		poleBodu = poleBodu.filter { !($0.x.isNaN || $0.y.isNaN) }
		if let directionVector = directionVector {
			let currentPosition = directionVector.newLoc
			return drawPath(poleBodu, intoImage: snapshot.image, curLocation: snapshot.pointForCoordinate(currentPosition.coordinate))
		} else {
			return drawPath(poleBodu, intoImage: snapshot.image, curLocation: nil)
		}
	}
	
//	func drawRouteWithTrackPoints2(trackPoints: [CLLocation], directionVector: DirectionVector) -> (MKMapSnapshot -> UIImage) {
//		func f1(snapshot: MKMapSnapshot) -> UIImage {
//			var poleBodu = trackPoints.map { snapshot.pointForCoordinate($0.coordinate) }
//			poleBodu = poleBodu.filter { !($0.x.isNaN || $0.y.isNaN) }
//			let currentPosition = directionVector.newLoc
//			let image = drawPath(poleBodu, intoImage: snapshot.image, curLocation: snapshot.pointForCoordinate(currentPosition.coordinate))
//			return image
//		}
//		return f1
//	}
	
	
}
