//
//  ARViewController.swift
//  ARML
//
//  Created by Gil Nakache on 28/01/2019.
//  Copyright © 2019 viseo. All rights reserved.
//

import ARKit

public class ARViewController: UIViewController {
    // MARK: - Variables
    let sceneView = ARSCNView()

    // MARK: - Lifecycle

    public override func loadView() {
        super.loadView()

        view = sceneView

        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the session with the configuration
        sceneView.session.run(configuration)
    }
}
