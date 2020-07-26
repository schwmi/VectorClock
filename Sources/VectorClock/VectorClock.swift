/// A Vector clock which ensures a total order by additionally adding a timestamp
public struct VectorClock<ActorID: Equatable & Hashable> {
    
    private var clocksByActors: [ActorID: Int]
    
    // MARK: Lifecycle
    
    public init() {
        self.init(clocksByActors: [:])
    }
    
    init(clocksByActors: [ActorID: Int]) {
        self.clocksByActors = clocksByActors
    }
    
    // MARK: - VectorClock
    
    func incrementing(_ actorID: ActorID) -> VectorClock {
        var incremented = self
        incremented.clocksByActors[actorID] = self.clocksByActors[actorID, default: 0] + 1
        return incremented
    }
    
    func merging(_ clock: VectorClock) -> VectorClock {
        let mergedClocks = self.clocksByActors.merging(clock.clocksByActors) { max($0, $1) }
        return VectorClock(clocksByActors: mergedClocks)
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
            return true
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
        return (lhsHasGreaterComponent && rhsHasGreaterCompnent) || onlyEqualComponents
    }
}

// MARK: CustomStringConvertible

extension VectorClock: CustomStringConvertible {

    public var description: String {
        let clocks = self.clocksByActors.map { "\($0.key)=\($0.value)" }.sorted(by: <).joined(separator: ", ")
        return "<\(clocks)>"
    }
}
