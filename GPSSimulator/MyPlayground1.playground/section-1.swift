// Playground - noun: a place where people can play

import UIKit
import XCPlayground

XCPSetExecutionShouldContinueIndefinitely(continueIndefinitely: true)

var str = "Hello, playground"

let testArray = [1,2,3,4,5]

let res = testArray.map {println($0)}

func dispatch_after_delay(delay: NSTimeInterval, queue: dispatch_queue_t, block: dispatch_block_t) {
  let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
  dispatch_after(time, queue, block)
}

println(4)
var a = 5
dispatch_after_delay(1, dispatch_get_main_queue()) { a = 8; println("a - \(a)") }

println("a - \(a)")

testArray.map { var1 in
  dispatch_after_delay(3, dispatch_get_main_queue()) { println(3) }
}