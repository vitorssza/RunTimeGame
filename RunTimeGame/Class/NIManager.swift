import NearbyInteraction
import SwiftUI

@Observable
class NIManager: NSObject, NISessionDelegate {
    var session: NISession?
    var distance: Float?
    
    var onTokenGenerated: ((Data) -> Void)?
    
    func start() {
        session = NISession()
        session?.delegate = self
        
        if let token = session?.discoveryToken,
           let data = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) {
            onTokenGenerated?(data)
        }
    }
    
    func provideRemoteToken(_ data: Data) {
        if let token = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: data) {
            let config = NINearbyPeerConfiguration(peerToken: token)
            session?.run(config)
        }
    }
    
    func stop() {
        session?.invalidate()
        session = nil
        distance = nil
    }
    
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        if let object = nearbyObjects.first, let dist = object.distance {
            DispatchQueue.main.async {
                self.distance = dist
            }
        }
    }
    
    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {}
    func sessionWasSuspended(_ session: NISession) {}
    func sessionSuspensionEnded(_ session: NISession) {}
    func session(_ session: NISession, didInvalidateWith error: Error) {}
}
