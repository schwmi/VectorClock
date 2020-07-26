
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

// MARK: CustomStringConvertible

extension VectorClock: CustomStringConvertible {

    public var description: String {
        let clocks = self.clocksByActors.map { "\($0.key)=\($0.value)" }.sorted(by: <).joined(separator: ", ")
        return "<\(clocks)>"
    }
}
