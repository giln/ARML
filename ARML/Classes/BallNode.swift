//
//  BallNode.swift
//  ARML
//
//  Created by Gil Nakache on 31/01/2019.
//  Copyright © 2019 viseo. All rights reserved.
//

import SceneKit

public class BallNode: SCNNode {
    // MARK: - Lifecycle

    public convenience init(radius: CGFloat) {
        self.init()
        let sphere = SCNSphere(radius: radius)

        // We create a Physically Based Rendering material
        let reflectiveMaterial = SCNMaterial()
        reflectiveMaterial.lightingModel = .physicallyBased
        // We want our ball to look metallic
        reflectiveMaterial.metalness.contents = 1.0
        // And shiny
        reflectiveMaterial.roughness.contents = 0.0
        sphere.firstMaterial = reflectiveMaterial

        self.geometry = sphere

        // We assign a dynamic physics body to our ball
        physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
    }
}
