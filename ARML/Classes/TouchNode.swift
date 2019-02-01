//
//  TouchNode.swift
//  ARML
//
//  Created by Gil Nakache on 31/01/2019.
//  Copyright © 2019 viseo. All rights reserved.
//

import SceneKit

public class TouchNode: SCNNode {

    // MARK: - Lifecycle

    public override init() {
        super.init()
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        // Touch node configuration
        let sphere = SCNSphere(radius: 0.01)

        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red

        // Uncomment to see the node for debugging purposes
        //geometry = sphere
        sphere.firstMaterial = material

        let sphereShape = SCNPhysicsShape(geometry: sphere, options: nil)

        physicsBody = SCNPhysicsBody(type: .kinematic, shape: sphereShape)
    }
}
