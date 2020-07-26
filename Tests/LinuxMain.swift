import XCTest

import VectorClockTests

var tests = [XCTestCaseEntry]()
tests += VectorClockTests.allTests()
XCTMain(tests)
