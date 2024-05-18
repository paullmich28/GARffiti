//
//  ARBrain.swift
//  gARffiti
//
//  Created by Paulus Michael on 18/05/24.
//

import Foundation
import ARKit

struct ARBrain {
    var fullPaintArray = [[SCNNode]]()
    var singlePaintArray = [SCNNode]()
    
    mutating func paint(_ node: SCNNode, _ color: UIColor, _ hitResult: ARHitTestResult){
        let sphereMaterial = SCNMaterial()
        sphereMaterial.diffuse.contents = color
        
        node.geometry?.materials = [sphereMaterial]
        
        node.position = SCNVector3(
            x: hitResult.worldTransform.columns.3.x,
            y: hitResult.worldTransform.columns.3.y,
            z: hitResult.worldTransform.columns.3.z
        )
        
        singlePaintArray.append(node)
    }
    
    mutating func afterPaint(){
        fullPaintArray.append(singlePaintArray)
        singlePaintArray.removeAll()
    }
    
    mutating func deleteAll(){
        for nodes in fullPaintArray {
            for node in nodes{
                node.removeFromParentNode()
            }
        }
        
        fullPaintArray.removeAll()
    }
    
    mutating func undo(){
        if let nodeWillDelete = fullPaintArray.last {
            for node in nodeWillDelete {
                node.removeFromParentNode()
            }
            
            fullPaintArray.removeLast()
        }else{
            print("Kosong")
        }
    }
    
    func anchorPointDetected(_ anchor: ARPlaneAnchor) -> SCNNode{
        let plane = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        
        let planeNode = SCNNode()
        
        planeNode.position = SCNVector3(x: anchor.center.x, y: 0, z: anchor.center.z)
        
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
        
        let gridMaterial = SCNMaterial()
        gridMaterial.diffuse.contents = UIColor.white
        gridMaterial.transparency = 0.5
        
        plane.materials = [gridMaterial]
        
        planeNode.geometry = plane
        
        return planeNode
    }
}
