//
//  SpotlightNode.swift
//  ARML
//
//  Created by Gil Nakache on 31/01/2019.
//  Copyright © 2019 viseo. All rights reserved.
//

import SceneKit

public class SpotlightNode: SCNNode {

    // MARK: - Lifecycle
    public override init() {
        super.init()
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        let spotLight = SCNLight()
        // used to cast shadows
        spotLight.type = .directional
        spotLight.shadowMode = .deferred
        spotLight.castsShadow = true
        spotLight.shadowRadius = 100.0
        spotLight.shadowColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.2)

        light = spotLight
        // Light is pointing toward the ground
        eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
    }
}
