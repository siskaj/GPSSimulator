//
//  ZoomedInController.swift
//  GPSSimulator
//
//  Created by Jaromir on 25.04.15.
//  Copyright (c) 2015 Baltoro. All rights reserved.
//

import WatchKit
import Foundation
import GPSSimulatorKit2
import BrightFutures


class ZoomedInController: ParentController {
	let wormHole: MMWormhole!

	override init() {
		wormHole = MMWormhole(applicationGroupIdentifier: "group.com.baltoro.GPSSimulator", optionalDirectory: nil)
		super.init()
	}

	override func awakeWithContext(context: AnyObject?) {
			super.awakeWithContext(context)
			
			// Configure interface objects here.
	}

	override func willActivate() {
		// This method is called when watch view controller is about to be visible to user
		super.willActivate()
		startListeningForMessages()
	}

	override func didDeactivate() {
		// This method is called when watch view controller is no longer visible
		stopListeningForMessages()
		super.didDeactivate()
	}

	
	private func startListeningForMessages() {
		wormHole.listenForMessageWithIdentifier("Direction") { messageObject in
			if let directionVector = messageObject as? DirectionVector, trackPoints_ = self.trackPoints {
				let options = MKMapSnapshotOptions()
				if let camera = MKMapCamera(lookingAtCenterCoordinate: directionVector.newLoc.coordinate, fromEyeCoordinate: directionVector.oldLoc.coordinate, eyeAltitude: 200) {
					options.camera = camera
					
					let futImage: Future<UIImage> = self.fetchSnapshot(options).map(self.drawRouteWithTrackPoints(trackPoints_, directionVector: directionVector))
					futImage.onSuccess { image in self.mapImage.setImage(image) }
				}
			}
		}
	}
	
	private func stopListeningForMessages() {
		wormHole.stopListeningForMessageWithIdentifier("Direction")
	}
	

}
