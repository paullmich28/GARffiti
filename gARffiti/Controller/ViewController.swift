//
//  ViewController.swift
//  GARffiti
//
//  Created by Paulus Michael on 15/05/24.
//

import UIKit
import SceneKit
import ARKit
import AVFoundation

class ViewController: UIViewController, ARSCNViewDelegate, AVAudioPlayerDelegate {
    
    private var arBrain = ARBrain()
    private var soundModel = SoundEffectModel()
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var colorWheel: UIColorWell!
    @IBOutlet weak var radiusSlider: UISlider!
    @IBOutlet weak var labelTemp: UILabel!
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var shakeImage: UIImageView!
    
    private var timer: Timer?
    private var isDrawing: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        radiusSlider.minimumValue = 0.005
        radiusSlider.maximumValue = 0.1
        radiusSlider.value = radiusSlider.maximumValue / 2
        radiusSlider.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi / 2))
        shakeImage.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi / 4))
        
        labelTemp.isHidden = true
        
        sceneView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .vertical
        
        sceneView.session.run(configuration)
    }
    
    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        let url = Bundle.main.url(forResource: "kocok", withExtension: "mp3")!
        
        arBrain.sprayAmount = 500
        
        soundModel.audioAssign(url)?.play()
        
        overlayView.isHidden = arBrain.amountSprayDecision()
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        soundModel.audioStop()
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
    
    @IBAction func deleteOnPressed(_ sender: UIButton) {
        arBrain.deleteAll()
    }
    
    @IBAction func drawButtonHold(_ sender: UIButton) {
        if arBrain.amountSprayDecision() {
            let url = Bundle.main.url(forResource: "gambar", withExtension: "mp3")!
            
            let player = soundModel.audioAssign(url)
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
                self.updateNodePosition()
                
                if self.isDrawing {
                    player?.numberOfLoops = -1
                    player?.delegate = self
                    player?.play()
                }
                
                self.overlayView.isHidden = self.arBrain.amountSprayDecision()
            }
        }else{
            overlayView.isHidden = arBrain.amountSprayDecision()
        }
    }
    
    @IBAction func drawButtonExit(_ sender: UIButton) {
        timer?.invalidate()
        
        arBrain.afterPaint()
        soundModel.audioStop()
        
        self.isDrawing = false
        overlayView.isHidden = arBrain.amountSprayDecision()
        
        timer = nil
    }
    
    @IBAction func takePhoto(_ sender: UIButton) {
        let photoTaken = sceneView.snapshot()
        UIImageWriteToSavedPhotosAlbum(photoTaken, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        
        arBrain.addFlashEffect(sceneView)
    }
    
    @IBAction func undoButtonPressed(_ sender: UIButton) {
        arBrain.undo()
    }
    
    @objc func updateNodePosition(){
        if arBrain.amountSprayDecision() {
            let screenCenter = CGPoint(x: sceneView.bounds.midX, y: sceneView.bounds.midY)
            
//            let results = sceneView.hitTest(screenCenter, types: .existingPlaneUsingExtent)
            guard let raycastQuery = sceneView.raycastQuery(from: screenCenter, allowing: .estimatedPlane, alignment: .vertical) else {
                return
            }

            let results = sceneView.session.raycast(raycastQuery)
            
            if let hitResult = results.first {
                let sphereNode = SCNNode(geometry: SCNSphere(radius: CGFloat(radiusSlider.value)))
                
                arBrain.paint(sphereNode, colorWheel.selectedColor!, hitResult)
                arBrain.sprayAmount -= 1
                
                DispatchQueue.main.async {
                    self.sceneView.scene.rootNode.addChildNode(sphereNode)
                }
                
                self.isDrawing = true
            }
        }else{
            soundModel.audioStop()
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("Error Saving ARKit Scene \(error)")
        } else {
            print("ARKit Scene Successfully Saved")
        }
    }
}
