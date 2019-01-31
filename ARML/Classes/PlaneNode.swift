//
//  PlaneNode.swift
//  ARML
//
//  Created by Gil Nakache on 30/01/2019.
//  Copyright © 2019 Gil Nakache. All rights reserved.
//

import ARKit
import SceneKit

public class PlaneNode: SCNNode {

    // MARK: - Public functions

    public func update(from planeAnchor: ARPlaneAnchor) {
        // We need to create a new geometry each time because it does not seem to update correctly for physics
        guard let device = MTLCreateSystemDefaultDevice(),
            let geom = ARSCNPlaneGeometry(device: device) else {
                fatalError()
        }

        geom.firstMaterial?.diffuse.contents = UIColor.blue.withAlphaComponent(0.3)
        geom.update(from: planeAnchor.geometry)

        // We modify our plane geometry each time ARKit updates the shape of an existing plane
        geometry = geom

        // We have to specify we want to use the bounding box or it does not work
        let shape = SCNPhysicsShape(geometry: geom, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.boundingBox])

        physicsBody = SCNPhysicsBody(type: .static, shape: shape)
    }
}
