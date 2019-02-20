//
//  ARViewController.swift
//  ARML
//
//  Created by Gil Nakache on 28/01/2019.
//  Copyright © 2019 viseo. All rights reserved.
//

import ARKit

open class ARViewController: UIViewController, ARSessionDelegate {
    // MARK: - Variables
    private let sceneView = ARSCNView()

    // MARK: - Lifecycle

    open override func loadView() {
        super.loadView()

        view = sceneView

        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // We want to receive the frames from the video
        sceneView.session.delegate = self

        // Run the session with the configuration
        sceneView.session.run(configuration)
    }

    // MARK: - ARSessionDelegate

    open func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // This is where we will analyse our frame
    }
}
