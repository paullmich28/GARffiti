//
//  ViewController.swift
//  GARffiti
//
//  Created by Paulus Michael on 15/05/24.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    var arBrain = ARBrain()
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var colorWheel: UIColorWell!
    @IBOutlet weak var radiusSlider: UISlider!
    
    /* Override functions */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        radiusSlider.minimumValue = 0.005
        radiusSlider.maximumValue = 0.05
        radiusSlider.value = radiusSlider.maximumValue / 2
        
//        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        sceneView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .vertical

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
                sceneView.scene.rootNode.addChildNode(sphereNode)
            }else{
                //                print("Clicked something else.")
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            arBrain.afterPaint()
        }else{
            print("Error")
        }
    }
    
    func renderer(_ renderer: any SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if anchor is ARPlaneAnchor {
            let planeAnchor = anchor as! ARPlaneAnchor
            
            var addNode = arBrain.anchorPointDetected(planeAnchor)
            node.addChildNode(addNode)
        }else{
            return
        }
    }
    
    /* Button Function */
    
    @IBAction func deleteOnPressed(_ sender: UIBarButtonItem) {
        arBrain.deleteAll()
    }
    
    @IBAction func takePhoto(_ sender: UIButton) {
        let photoTaken = sceneView.snapshot()
        UIImageWriteToSavedPhotosAlbum(photoTaken, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @IBAction func undoButtonPressed(_ sender: UIButton) {
        arBrain.undo()
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("Error Saving ARKit Scene \(error)")
        } else {
            print("ARKit Scene Successfully Saved")
        }
    }
}
