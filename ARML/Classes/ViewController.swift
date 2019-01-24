//
//  ViewController.swift
//  ARML
//
//  Created by Gil Nakache on 24/01/2019.
//  Copyright © 2019 viseo. All rights reserved.
//

import ARKit
import CoreML
import SceneKit
import UIKit
import Vision

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    // MARK: - Variables

    let sceneView = ARSCNView()
    let previewView  = UIImageView()
    var currentBuffer: CVPixelBuffer?

    let visionQueue = DispatchQueue(label: "com.viseo.ARML.visionqueue")

    lazy var predictionRequest: VNCoreMLRequest = {
        // Load the ML model through its generated class and create a Vision request for it.
        do {
            let model = try VNCoreMLModel(for: HandModel().model)
            let request = VNCoreMLRequest(model: model)
            request.imageCropAndScaleOption = VNImageCropAndScaleOption.scaleFit
            return request
        } catch {
            fatalError("can't load Vision ML model: \(error)")
        }
    }()

    // MARK: - Lifecycle

    override func loadView() {
        super.loadView()

        view = sceneView

        sceneView.addSubview(previewView)

        previewView.translatesAutoresizingMaskIntoConstraints = false
        previewView.widthAnchor.constraint(equalToConstant: 112).isActive = true
        previewView.heightAnchor.constraint(equalToConstant: 112).isActive = true

        previewView.backgroundColor = UIColor.white
        previewView.bottomAnchor.constraint(equalTo: sceneView.bottomAnchor).isActive = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the view's delegate
        sceneView.delegate = self

        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true

        // Create a new scene
        let scene = SCNScene()

        // Set the scene to the view
        sceneView.scene = scene
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)

        sceneView.session.delegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate

    /*
     // Override to create and configure nodes for anchors added to the view's session.
     func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
     let node = SCNNode()

     return node
     }
     */

    func session(_: ARSession, didFailWithError _: Error) {
        // Present an error message to the user
    }

    func sessionWasInterrupted(_: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }

    func sessionInterruptionEnded(_: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }

    // MARK: - ARSessionDelegate

    func session(_: ARSession, didUpdate frame: ARFrame) {
        guard currentBuffer == nil, case .normal = frame.camera.trackingState else {
            return
        }

        // Retain the image buffer for Vision processing.
        currentBuffer = frame.capturedImage
        detectHand()
    }

    private func detectHand() {
        let orientation = CGImagePropertyOrientation(rawValue: UInt32(UIDevice.current.orientation.rawValue))

        let requestHandler = VNImageRequestHandler(cvPixelBuffer: currentBuffer!, orientation: .right)

        visionQueue.async {
            try? requestHandler.perform([self.predictionRequest])

            guard let observation = self.predictionRequest.results?.first as? VNPixelBufferObservation else {
                fatalError("unexpected result type from VNCoreMLRequest")
            }

            let previewImage = UIImage(pixelBuffer: observation.pixelBuffer)

            DispatchQueue.main.async {
                self.previewView.image = previewImage
                self.currentBuffer = nil
            }
        }
    }
}
