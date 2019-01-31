//
//  PlaneNode.swift
//  ARML
//
//  Created by Gil Nakache on 30/01/2019.
//  Copyright © 2019 Gil Nakache. All rights reserved.
//

import ARKit
import SceneKit

class PlaneNode: SCNNode {
    // We can force cast here since ARKit does not work on non metal devices
    let planeGeometry = ARSCNPlaneGeometry(device: MTLCreateSystemDefaultDevice()!)

    // MARK: - Lifecycle

    override init() {
        super.init()
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        planeGeometry?.firstMaterial?.diffuse.contents = UIColor.blue.withAlphaComponent(0.3)

        // PlaneNode geometry is an ARSCNPlaneGeometry
        // ARSCNPlaneGeometry is special type of geometry that follows the shape of plane detected by ARKit
        geometry = planeGeometry
    }
}
