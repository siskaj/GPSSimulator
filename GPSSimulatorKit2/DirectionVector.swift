//
//  DirectionVector.swift
//  GPSSimulator
//
//  Created by Jaromir on 23.04.15.
//  Copyright (c) 2015 Baltoro. All rights reserved.
//


import MapKit

public class DirectionVector: NSObject, NSCoding {
	public let oldLoc: CLLocation
	public let newLoc: CLLocation
	
	public init(old: CLLocation, new: CLLocation) {
		self.oldLoc = old
		self.newLoc = new
	}
	
	required public init(coder aDecoder: NSCoder) {
		oldLoc = aDecoder.decodeObjectForKey("oldLocation") as! CLLocation
		newLoc = aDecoder.decodeObjectForKey("newLocation") as! CLLocation
	}
	
	public func encodeWithCoder(aCoder: NSCoder) {
		aCoder.encodeObject(oldLoc, forKey: "oldLocation")
		aCoder.encodeObject(newLoc, forKey: "newLocation")
	}
}
