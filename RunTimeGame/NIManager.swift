import NearbyInteraction

class NIManager: NSObject {
    private var session: NISession?
    
    var onDistanceUpdated: ((Float) -> Void)?
    
    var localToken: NIDiscoveryToken? {
        session?.discoveryToken
    }
    
    override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        session = NISession()
        session?.delegate = self
    }
    
    func startSession(with peerToken: NIDiscoveryToken) {
        let config = NINearbyPeerConfiguration(peerToken: peerToken)
        session?.run(config)
    }
    
    func stopSession() {
        session?.invalidate()
        setupSession()
    }
}

extension NIManager: NISessionDelegate {
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        guard let object = nearbyObjects.first, let distance = object.distance else { return }
        DispatchQueue.main.async {
            self.onDistanceUpdated?(distance)
        }
    }
    
    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {}
    func sessionWasSuspended(_ session: NISession) {}
    func sessionSuspensionEnded(_ session: NISession) {}
    func session(_ session: NISession, didInvalidateWith error: Error) {}
}

