import Foundation

/// A Vector clock which ensures a total order by additionally adding a timestamp
public struct VectorClock<ActorID: Equatable & Hashable> {
    
    struct UnambigousTimestamp {
        var actorID: ActorID
        var timestamp: TimeInterval
    }
    
    public typealias TimestampProvider = () -> TimeInterval
    
    private var timestampProvider: TimestampProvider
    private var clocksByActors: [ActorID: Int]
    private var timestamp: TimeInterval
    
    // MARK: Lifecycle
    
    public init(timestampProvider: TimestampProvider? = nil) {
        self.init(clocksByActors: [:], timestampProvider: timestampProvider)
    }
    
    init(clocksByActors: [ActorID: Int], timestampProvider: TimestampProvider? = nil) {
        self.clocksByActors = clocksByActors
        let timestampProvider = timestampProvider ?? { Date().timeIntervalSince1970 }
        self.timestampProvider = timestampProvider
        self.timestamp = timestampProvider()
    }
    
    // MARK: - VectorClock
    
    func incrementing(_ actorID: ActorID) -> VectorClock {
        var incrementedClocks = self.clocksByActors
        incrementedClocks[actorID] = incrementedClocks[actorID, default: 0] + 1
        return VectorClock(clocksByActors: incrementedClocks, timestampProvider: self.timestampProvider)
    }
    
    func merging(_ clock: VectorClock) -> VectorClock {
        let mergedClocks = self.clocksByActors.merging(clock.clocksByActors) { max($0, $1) }
        return VectorClock(clocksByActors: mergedClocks, timestampProvider: self.timestampProvider)
    }
}

// MARK: - Comparable

extension VectorClock: Comparable {

    public static func < (lhs: VectorClock<ActorID>, rhs: VectorClock<ActorID>) -> Bool {
        var isEqual = true
        for (key, value) in lhs.clocksByActors {
            let rhsValue = rhs.clocksByActors[key, default: 0]
            if value <= rhsValue {
                if isEqual && value < rhsValue {
                    isEqual = false
                }
            } else {
                return false
            }
        }
        if isEqual == true && lhs.clocksByActors.count == rhs.clocksByActors.count {
            return false
        } else {
            if rhs < lhs {
                return lhs.timestamp < rhs.timestamp
            } else {
                return true
            }
        }
    }
    
    public static func == (lhs: VectorClock<ActorID>, rhs: VectorClock<ActorID>) -> Bool {
        guard lhs.clocksByActors.count > 0 || rhs.clocksByActors.count > 0 else { return true }
        
        var lhsHasGreaterComponent = false
        var rhsHasGreaterCompnent = false
        var onlyEqualComponents = true
        for (key, value) in lhs.clocksByActors {
            let otherValue = rhs.clocksByActors[key, default: 0]
            if value > otherValue {
                lhsHasGreaterComponent = true
                onlyEqualComponents = false
                break
            }
        }
        
        for (key, value) in rhs.clocksByActors {
            let otherValue = lhs.clocksByActors[key, default: 0]
            if value > otherValue {
                rhsHasGreaterCompnent = true
                onlyEqualComponents = false
                break
            }
        }
        if (lhsHasGreaterComponent && rhsHasGreaterCompnent) || onlyEqualComponents {
            return lhs.timestamp == rhs.timestamp
        } else {
            return false
        }
    }
}

// MARK: CustomStringConvertible

extension VectorClock: CustomStringConvertible {

    public var description: String {
        let clocks = self.clocksByActors.map { "\($0.key)=\($0.value)" }.sorted(by: <).joined(separator: ", ")
        return "<\(clocks)>"
    }
}
