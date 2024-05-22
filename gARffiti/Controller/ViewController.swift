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
    
    var arBrain = ARBrain()
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var colorWheel: UIColorWell!
    @IBOutlet weak var radiusSlider: UISlider!
    
    var audioPlayer: AVAudioPlayer?
    var timer: Timer?
    var isDrawing: Bool = false
    
    var sprayAmount = 0
    
    /* Override functions */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        radiusSlider.minimumValue = 0.005
        radiusSlider.maximumValue = 0.05
        radiusSlider.value = radiusSlider.maximumValue / 2
        
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
    
    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        let url = Bundle.main.url(forResource: "kocok", withExtension: "mp3")!
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            guard let player = audioPlayer else { return }
            sprayAmount = 500
            player.play()
        } catch let error as NSError {
            print(error.description)
        }
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard let player = audioPlayer else { return }
        player.stop()
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
    
    @IBAction func drawButtonHold(_ sender: UIButton) {
        if sprayAmount > 0 {
            let url = Bundle.main.url(forResource: "gambar", withExtension: "mp3")!
            
            do {
                self.audioPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            } catch let error {
                print(error)
            }
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
                self.updateNodePosition()
                if self.isDrawing {
                    self.audioPlayer?.numberOfLoops = -1
                    self.audioPlayer?.delegate = self
                    self.audioPlayer?.play()
                }
                
                print(self.sprayAmount)
            }
        }
    }
    
    @IBAction func drawButtonExit(_ sender: UIButton) {
        timer?.invalidate()
        
        arBrain.afterPaint()
        guard let player = audioPlayer else { return }
        player.stop()
        self.isDrawing = false
        
        timer = nil
    }
    
    @objc func updateNodePosition(){
        if sprayAmount > 0{
            let screenCenter = CGPoint(x: sceneView.bounds.midX, y: sceneView.bounds.midY)
            
            // Perform hit testing using the center point
            let results = sceneView.hitTest(screenCenter, types: .existingPlaneUsingExtent)
            
            if let hitResult = results.first {
                let sphereNode = SCNNode(geometry: SCNSphere(radius: CGFloat(radiusSlider.value)))
                
                arBrain.paint(sphereNode, colorWheel.selectedColor!, hitResult)
                sprayAmount -= 1
                
                DispatchQueue.main.async {
                    self.sceneView.scene.rootNode.addChildNode(sphereNode)
                }
                
                self.isDrawing = true
            }
        }else{
            guard let player = audioPlayer else { return }
            player.stop()
        }
        
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
}
