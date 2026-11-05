import MultipeerConnectivity
import SwiftUI

@Observable
class ConnectionManager: NSObject, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    var peerID: MCPeerID!
    var connectedPeer: MCPeerID?
    var advertiser: MCNearbyServiceAdvertiser!
    var browser: MCNearbyServiceBrowser!
    var session: MCSession!
    
    var onDataReceived: ((Data) -> Void)?
    var onConnected: (() -> Void)?
    var onDisconnected: (() -> Void)?
    
    override init() {
        super.init()
        peerID = MCPeerID(displayName: UIDevice.current.name)
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "nirungame")
        advertiser.delegate = self
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: "nirungame")
        browser.delegate = self
    }
    
    func startSearch() {
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }
    
    func stopSearch() {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
    }
    
    func disconnect() {
        stopSearch()
        session.disconnect()
        connectedPeer = nil
    }
    
    func send(data: Data) {
        guard let peer = connectedPeer else { return }
        try? session.send(data, toPeers: [peer], with: .reliable)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            if state == .connected {
                self.connectedPeer = peerID
                self.stopSearch()
                self.onConnected?()
            } else if state == .notConnected {
                self.connectedPeer = nil
                self.onDisconnected?()
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.onDataReceived?(data)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
