import XCTest
@testable import VectorClock


final class VectorClockTests: XCTestCase {
    
    func testNewEmptyClock() {
        let clock = VectorClock<String>(actorID: "A", timestampProvider: self.mockTimestampProvider())
        XCTAssertEqual(clock.description, "<A=0 | t: A(0.00)>")
    }
    
    func testIncrement() {
        let clock = VectorClock<String>(actorID: "A", timestampProvider: self.mockTimestampProvider())
        
        // Increment actor A
        let incrementedA = clock.incrementing("A")
        XCTAssertEqual(incrementedA.description, "<A=1 | t: A(1.00)>")
        
        // Increment actor B
        let incrementedAB = incrementedA.incrementing("B")
        XCTAssertEqual(incrementedAB.description, "<A=1, B=1 | t: B(2.00)>")
        
        // Increment actor B again
        let incrementedABB = incrementedAB.incrementing("B")
        XCTAssertEqual(incrementedABB.description, "<A=1, B=2 | t: B(3.00)>")
        
        // Increment actor A again
        let incrementedABBA = incrementedABB.incrementing("A")
        XCTAssertEqual(incrementedABBA.description, "<A=2, B=2 | t: A(4.00)>")
    }
    
    func testMerge() {
        let clock = VectorClock<String>(actorID: "A", timestampProvider: self.mockTimestampProvider())
        
        // Increment actor A
        let incrementedA = clock.incrementing("A")
        XCTAssertEqual(incrementedA.description, "<A=1 | t: A(1.00)>")
        
        // Increment actor B
        let incrementedB = clock.incrementing("B")
        XCTAssertEqual(incrementedB.description, "<A=0, B=1 | t: B(2.00)>")
        
        // Merge A with B
        let mergedAB = incrementedB.merging(incrementedA)
        XCTAssertEqual(mergedAB.description, "<A=1, B=1 | t: B(2.00)>")
    }
    
    func testComparisonWithConstantTime() {
        // Test empty clock comparison
        let clock1 = VectorClock<String>(actorID: "A", timestampProvider: { return 0 })
        let clock2 = VectorClock<String>(actorID: "A", timestampProvider: { return 0 })
        XCTAssertEqual(clock1, clock2)
        
        // Increment actor A
        let clock1A = clock1.incrementing("A")
        XCTAssertTrue(clock1 < clock1A)
        XCTAssertTrue(clock1A == clock1A)
        
        // Increment actor B
        let clock2B = clock2.incrementing("B")
        XCTAssertEqual(clock1A.partialOrder(other: clock2B), .concurrent)
        XCTAssertTrue(clock1A < clock2B)
        XCTAssertFalse(clock1A > clock2B)
    }
    
    func testComparisonWithIncreasingTime() {
        var currentTime: TimeInterval = 0
        let provider: VectorClock.TimestampProvider = {
            currentTime = currentTime + 1
            return currentTime
        }
        // Test empty clock comparison
        let clock1 = VectorClock<String>(actorID: "A", timestampProvider: provider)
        let clock2 = VectorClock<String>(actorID: "A", timestampProvider: provider)
        XCTAssertEqual(clock1.partialOrder(other: clock2), .concurrent)
        XCTAssertTrue(clock1 < clock2)
        
        // Increment actor A
        let clock1A = clock1.incrementing("A")
        XCTAssertTrue(clock1 < clock1A)
        XCTAssertTrue(clock1A == clock1A)
        
        // Increment actor B
        let clock2B = clock2.incrementing("B")
        XCTAssertTrue(clock1A < clock2B)
    }

    static var allTests = [
        ("testIncrement", testIncrement),
        ("testComparisonWithConstantTime", testComparisonWithConstantTime),
        ("testComparisonWithIncreasingTime", testComparisonWithIncreasingTime),
        ("testMerge", testMerge),
        ("testNewEmptyClock", testNewEmptyClock)
    ]
}

// MARK: - Private

private extension VectorClockTests {

    func mockTimestampProvider(startingFrom clock: TimeInterval = 0) -> VectorClock<String>.TimestampProvider {
        var clock = clock
        return {
            defer { clock = clock + 1 }
            return clock
        }
    }
}
