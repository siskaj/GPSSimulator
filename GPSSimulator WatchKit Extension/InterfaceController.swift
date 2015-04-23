//
//  InterfaceController.swift
//  GPSSimulator WatchKit Extension
//
//  Created by Jaromir Siska on 17.04.15.
//  Copyright (c) 2015 Baltoro. All rights reserved.
//

import WatchKit
import Foundation
import GPSSimulatorKit2
import GPX

class InterfaceController: WKInterfaceController {
	let wormHole: MMWormhole!
	var trackPoints: [GPXTrackPoint]?

	@IBOutlet weak var interfaceImage: WKInterfaceImage!
	
	override init() {
		wormHole = MMWormhole(applicationGroupIdentifier: "group.com.baltoro.GPSSSimulator", optionalDirectory: nil)
		
		let identifier = "group.com.baltoro.GPSSimulator"
		var sharedUserDefaults = NSUserDefaults(suiteName: identifier)
		if let sharedUserDefaults = sharedUserDefaults {
			trackPoints = sharedUserDefaults.objectForKey("trackPoints") as? [GPXTrackPoint]
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

	private func startListeningForMessages() {
		wormHole.listenForMessageWithIdentifier("Direction") { messageObject in
			if let directionVector = messageObject as? DirectionVector, trackPoints_ = self.trackPoints {
				self.drawCompleteRoute(trackPoints_, directionVector: directionVector, mod: .FullTrack)
			}
		}
	}
	
	func drawCompleteRoute(trackPoints: [GPXTrackPoint], directionVector: DirectionVector, mod: Mode) {
		let options = MKMapSnapshotOptions()
//		options.scale = UIScreen.mainScreen().scale
//		options.size = imageView.frame.size
		
		let camera = MKMapCamera(lookingAtCenterCoordinate: directionVector.newLoc.coordinate, fromEyeCoordinate: directionVector.oldLoc.coordinate, eyeAltitude: 200)
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
		snapshotter.startWithCompletionHandler({ (snapshot: MKMapSnapshot!, error: NSError!) -> Void in
			if error == nil {
				var poleBodu = trackPoints.map { snapshot.pointForCoordinate(CLLocationCoordinate2DMake(Double($0.latitude), Double($0.longitude))) }
				// Nutne zkontrolovat; nektere body to konvertuje na NaN
				poleBodu = poleBodu.filter { !($0.x.isNaN || $0.y.isNaN) }
				let currentPosition = directionVector.newLoc
				let image = drawPath(poleBodu, intoImage: snapshot.image, curLocation: snapshot.pointForCoordinate(currentPosition.coordinate))
				self.interfaceImage.setImage(image)
//				if let currentPosition = currentPosition {
//					let image = drawPath(poleBodu, intoImage: snapshot.image, curLocation: snapshot.pointForCoordinate(currentPosition.coordinate))
//					self.interfaceImage.setImage(image)
//				} else {
//					let image = drawPath(poleBodu, intoImage: snapshot.image, curLocation: nil)
//					self.interfaceImage.setImage(image)
//				}
			}
		})
	}

}
