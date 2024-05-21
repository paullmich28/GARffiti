//
//  ViewController.swift
//  GARffiti
//
//  Created by Paulus Michael on 15/05/24.
//

import UIKit
import SceneKit
import ARKit
import MultipeerSession
import MultipeerConnectivity

class ViewController: UIViewController, ARSCNViewDelegate {
    
    var arBrain = ARBrain()
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var colorWheel: UIColorWell!
    @IBOutlet weak var radiusSlider: UISlider!
    
    var multipeerSession: MultipeerSession!
    var sessionIDObservation: NSKeyValueObservation?
    
    /* Override functions */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        radiusSlider.minimumValue = 0.005
        radiusSlider.maximumValue = 0.05
        radiusSlider.value = radiusSlider.maximumValue / 2
        
        setupMultipeerSession()
        
        //        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        sceneView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .vertical
        configuration.isCollaborationEnabled = true
        
        //        sceneView.session.delegate = self
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: sceneView)
            
            let results = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
            
            if let hitResult = results.first {
                let sphereNode = SCNNode(geometry: SCNSphere(radius: CGFloat(radiusSlider.value)))
                
                arBrain.paint(sphereNode, colorWheel.selectedColor!, hitResult)
                
                DispatchQueue.main.async {
                    self.sceneView.scene.rootNode.addChildNode(sphereNode)
                }
            }else{
                //                print("Clicked something else.")
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.first != nil {
            arBrain.afterPaint()
        }else{
            print("Error")
        }
    }
    
    func renderer(_ renderer: any SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if anchor is ARPlaneAnchor {
            let planeAnchor = anchor as! ARPlaneAnchor
            
            let addNode = arBrain.anchorPointDetected(planeAnchor)
            node.addChildNode(addNode)
        }else{
            return
        }
    }
    
    /* Button Functions */
    
    @IBAction func deleteOnPressed(_ sender: UIBarButtonItem) {
        arBrain.deleteAll()
    }
    
    @IBAction func takePhoto(_ sender: UIButton) {
        arBrain.addFlashEffect(sceneView)
        
        let photoTaken = sceneView.snapshot()
        UIImageWriteToSavedPhotosAlbum(photoTaken, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @IBAction func undoButtonPressed(_ sender: UIButton) {
        arBrain.undo()
    }
    
    /* Extension Function */
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("Error Saving ARKit Scene \(error)")
        } else {
            print("ARKit Scene Successfully Saved")
        }
    }
    
    /* Multipeer Session function */
    
    func setupMultipeerSession(){
        sessionIDObservation = observe(\.sceneView?.session.identifier, options: [.new]) { object, change in
            print("SessionID changed to: \(change.newValue)")
            
            guard let multipeerSession = self.multipeerSession else {return}
            
            self.sendARSessionIDTo(peers: multipeerSession.connectedPeers)
        }
        
        multipeerSession = MultipeerSession(serviceName: "garffiti", receivedDataHandler: self.receivedData, peerJoinedHandler: self.peerJoined, peerLeftHandler: self.peerLeft, peerDiscoveredHandler: self.peerDiscovered)
        
    }
    
    func placeObject(){
        // Step 1: Create the sphere geometry
        let sphereGeometry = SCNSphere(radius: 0.5)
        
        // Step 2: Create a material and set its diffuse content to red
        let sphereMaterial = SCNMaterial()
        sphereMaterial.diffuse.contents = UIColor.red
        
        // Apply the material to the sphere geometry
        sphereGeometry.materials = [sphereMaterial]
        
        // Step 3: Create a node with the sphere geometry
        let sphereNode = SCNNode(geometry: sphereGeometry)
        
        // Step 4: Add the node to the root node of the scene
        sceneView.scene.rootNode.addChildNode(sphereNode)
    }
    
    //    func setupMultiuserAR(){
    //        let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    //
    //        let session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
    //        session.delegate = self
    //
    //        let serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: MultipeerSession.serviceType)
    //        serviceAdvertiser.delegate = self
    //        serviceAdvertiser.startAdvertisingPeer()
    //
    //        let serviceBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: MultipeerSession.serviceType)
    //        serviceBrowser.delegate = self
    //        serviceBrowser.startBrowsingForPeers()
    //    }
    
}

/* Multipeer Stuffs */

extension ViewController {
    private func sendARSessionIDTo(peers: [PeerID]){
        guard let multipeerSession = multipeerSession else {return}
        let idString = sceneView.session.identifier.uuidString
        let command = "SessionID:" + idString
        if let commandData = command.data(using: .utf8){
            multipeerSession.sendToPeers(commandData, reliably: true, peers: peers)
        }
    }
    
    func receivedData(_ data: Data, from peer: PeerID){
        guard let multipeerSession = multipeerSession else {return}
        
        if let collaborationData = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARSession.CollaborationData.self, from: data){
            sceneView.session.update(with: collaborationData)
            return
        }
        
        let sessionIDCommandString = "SessionID:"
        if let commandString = String(data: data, encoding: .utf8), commandString.starts(with: sessionIDCommandString) {
            let newSessionID = String(commandString[commandString.index(commandString.startIndex, offsetBy: sessionIDCommandString.count)...])
            
            if let oldSessionID = multipeerSession.peerSessionIDs[peer]{
                removeAllAnchorsOriginatingFromARSessionWithID(oldSessionID)
            }
            
            multipeerSession.peerSessionIDs[peer] = newSessionID
        }
    }
    
    func peerDiscovered(_ peer: PeerID) -> Bool {
        guard let multipeerSession = multipeerSession else {return false}
        
        if multipeerSession.connectedPeers.count > 4 {
            print("A fifth player wants to join. \nThe game is currently limited to four players")
            return false
        }else{
            return true
        }
    }
    
    func peerJoined(_ peer: PeerID){
        print("""
            A player wants to join the game. Hold the devices next to each  other.
            """)
        
        sendARSessionIDTo(peers: [peer])
    }
    
    func peerLeft(_ peer: PeerID){
        guard let multipeerSession = multipeerSession else {return}
        
        print("A player has left the game.")
        
        if let sessionID = multipeerSession.peerSessionIDs[peer]{
            removeAllAnchorsOriginatingFromARSessionWithID(sessionID)
            multipeerSession.peerSessionIDs.removeValue(forKey: peer)
        }
    }
    
    func removeAllAnchorsOriginatingFromARSessionWithID(_ identifier: String){
        guard let frame = sceneView.session.currentFrame else { return }
        for anchor in frame.anchors{
            guard let anchorSessionID = anchor.sessionIdentifier else { continue }
            if anchorSessionID.uuidString == identifier{
                sceneView.session.remove(anchor: anchor)
            }
        }
    }
    
    func session(_ session: ARSession, didOutputCollaborationData data: ARSession.CollaborationData) {
        guard let multipeerSession = multipeerSession else { return }
        if !multipeerSession.connectedPeers.isEmpty {
            guard let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: data, requiringSecureCoding: true)
            else { fatalError("Unexpectedly failed to encode collaboration data.") }
            // Use reliable mode if the data is critical, and unreliable mode if the data is optional.
            let dataIsCritical = data.priority == .critical
            multipeerSession.sendToAllPeers(encodedData, reliably: dataIsCritical)
        } else {
            print("Deferred sending collaboration to later because there are no peers.")
        }
    }
}

extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let anchorName = anchor.name {
                placeObject()
            }
            
            if let participantAnchor = anchor as? ARParticipantAnchor {
                print("Successfully connected with another user")
                
                // Create the sphere geometry
                let sphereGeometry = SCNSphere(radius: 0.03)
                
                // Create a material and set its diffuse content to red
                let sphereMaterial = SCNMaterial()
                sphereMaterial.diffuse.contents = UIColor.red
                
                // Apply the material to the sphere geometry
                sphereGeometry.materials = [sphereMaterial]
                
                // Create a node with the sphere geometry
                let sphereNode = SCNNode(geometry: sphereGeometry)
                
                // Set the node's position to match the participant anchor's transform
                let transform = participantAnchor.transform
                sphereNode.transform = SCNMatrix4(transform)
                
                // Add the node to the root node of the scene
                sceneView.scene.rootNode.addChildNode(sphereNode)
            }
        }
    }
}
