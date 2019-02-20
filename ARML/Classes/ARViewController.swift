//
//  ARViewController.swift
//  ARML
//
//  Created by Gil Nakache on 28/01/2019.
//  Copyright © 2019 viseo. All rights reserved.
//

import ARKit

open class ARViewController: UIViewController, ARSessionDelegate, ARSCNViewDelegate {
    // MARK: - Variables

    private let sceneView = ARSCNView()
    private var currentBuffer: CVPixelBuffer?
    private let handDetector = HandDetector()
    private let previewView = UIImageView()

    // MARK: - Lifecycle

    open override func loadView() {
        super.loadView()

        view = sceneView

        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Enable Horizontal plane detection
        configuration.planeDetection = .horizontal

        // The delegate is used to receive ARAnchors when they are detected.
        sceneView.delegate = self

        // We want to receive the frames from the video
        sceneView.session.delegate = self

        // Run the session with the configuration
        sceneView.session.run(configuration)

        view.addSubview(previewView)

        previewView.translatesAutoresizingMaskIntoConstraints = false
        previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }

    // MARK: - ARSessionDelegate

    open func session(_: ARSession, didUpdate frame: ARFrame) {
        // We return early if currentBuffer is not nil or the tracking state of camera is not normal
        guard currentBuffer == nil, case .normal = frame.camera.trackingState else {
            return
        }

        // Retain the image buffer for Vision processing.
        currentBuffer = frame.capturedImage

        startDetection()
    }

    // MARK: - Private functions

    private func startDetection() {
        // Here we will do our CoreML request on currentBuffer
        guard let someBuffer = currentBuffer else { return }

        handDetector.performDetection(inputBuffer: someBuffer) { outputPixelBuffer, _ in

            if let outputBuffer = outputPixelBuffer {

                DispatchQueue.main.async {
                    self.previewView.image = UIImage(ciImage: CIImage(cvPixelBuffer: outputBuffer))
                }

            }
            // Release currentBuffer to allow processing next frame
            self.currentBuffer = nil
        }
    }

    // MARK: - ARSCNViewDelegate

    public func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let _ = anchor as? ARPlaneAnchor else { return nil }

        // We return a special type of SCNNode for ARPlaneAnchors
        return PlaneNode()
    }

    public func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor,
            let planeNode = node as? PlaneNode else {
                return
        }
        planeNode.update(from: planeAnchor)
    }

    public func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor,
            let planeNode = node as? PlaneNode else {
                return
        }
        planeNode.update(from: planeAnchor)
    }
}
