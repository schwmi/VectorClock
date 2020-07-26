import XCTest
@testable import VectorClock


final class VectorClockTests: XCTestCase {
    
    func testNewEmptyClock() {
        let clock = VectorClock<String>()
        XCTAssertEqual(clock.description, "<>")
    }
    
    func testIncrement() {
        let clock = VectorClock<String>()
        
        // Increment actor A
        let incrementedA = clock.incrementing("A")
        XCTAssertEqual(incrementedA.description, "<A=1>")
        
        // Increment actor B
        let incrementedAB = incrementedA.incrementing("B")
        XCTAssertEqual(incrementedAB.description, "<A=1, B=1>")
        
        // Increment actor B again
        let incrementedABB = incrementedAB.incrementing("B")
        XCTAssertEqual(incrementedABB.description, "<A=1, B=2>")
        
        // Increment actor A again
        let incrementedABBA = incrementedABB.incrementing("A")
        XCTAssertEqual(incrementedABBA.description, "<A=2, B=2>")
    }
    
    func testMerge() {
        let clock = VectorClock<String>()
        
        // Increment actor A
        let incrementedA = clock.incrementing("A")
        XCTAssertEqual(incrementedA.description, "<A=1>")
        
        // Increment actor B
        let incrementedB = clock.incrementing("B")
        XCTAssertEqual(incrementedB.description, "<B=1>")
        
        // Merge A with B
        let mergedAB = incrementedB.merging(incrementedA)
        XCTAssertEqual(mergedAB.description, "<A=1, B=1>")
    }
    
    func testComparison() {
        // Test empty clock comparison
        let clock1 = VectorClock<String>()
        let clock2 = VectorClock<String>()
      //  XCTAssertEqual(clock1, clock2)
        
        // Increment actor A
        let clock1A = clock1.incrementing("A")
       // XCTAssertTrue(clock1 < clock1A)
       // XCTAssertTrue(clock1A == clock1A)
        
        // Increment actor B
        let clock2B = clock2.incrementing("B")
        XCTAssertTrue(clock1A == clock2B)
    
    }

    static var allTests = [
        ("testIncrement", testIncrement),
        ("testMerge", testMerge),
        ("testNewEmptyClock", testNewEmptyClock)
    ]
}
