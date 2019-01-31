//
//  ARViewController.swift
//  ARML
//
//  Created by Gil Nakache on 28/01/2019.
//  Copyright © 2019 viseo. All rights reserved.
//

import ARKit
import CoreML
import Vision

class ARViewController: UIViewController, ARSessionDelegate, ARSCNViewDelegate {
    // MARK: - Variables

    let sceneView = ARSCNView()
    var currentBuffer: CVPixelBuffer?
    var previewView = UIImageView()

    // MARK: - Lifecycle

    override func loadView() {
        super.loadView()

        view = sceneView

        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Enable Horizontal plane detection
        configuration.planeDetection = .horizontal

        sceneView.autoenablesDefaultLighting = true

        // We want to receive the frames from the video
        sceneView.session.delegate = self
        //sceneView.debugOptions = [.showPhysicsShapes]

        // Run the session with the configuration
        sceneView.session.run(configuration)

        // The delegate is used to receive ARAnchors when they are detected.
        sceneView.delegate = self

        sceneView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(viewDidTap(recognizer:))))

        view.addSubview(previewView)

        previewView.translatesAutoresizingMaskIntoConstraints = false
        previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }

    // MARK: - Actions

    @objc func viewDidTap(recognizer: UITapGestureRecognizer) {
        // We get the tap location as a 2D Screen coordinate
        let tapLocation = recognizer.location(in: sceneView)

        // To transform our 2D Screen coordinates to 3D screen coordinates we use hitTest function
        let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)

        // We cast a ray from the point tapped on screen, and we return any intersection with existing planes
        guard let hitTestResult = hitTestResults.first else { return }

        let ball = BallNode(radius: 0.05)

        // We place the ball at hit point
        ball.simdTransform = hitTestResult.worldTransform
        // We place it slightly (20cm) above the plane
        ball.position.y += 0.20
        
        // We add the node to the scene
        sceneView.scene.rootNode.addChildNode(ball)
        
    }

    // MARK: - ARSessionDelegate

    func session(_: ARSession, didUpdate frame: ARFrame) {
        // We return early if currentBuffer is not nil or the tracking state of camera is not normal
        guard currentBuffer == nil, case .normal = frame.camera.trackingState else {
            return
        }

        // Retain the image buffer for Vision processing.
        currentBuffer = frame.capturedImage

        startDetection()
    }

    // MARK: - Private functions

    let handDetector = HandDetector()

    private func startDetection() {
        // To avoid force unwrap in VNImageRequestHandler
        guard let buffer = currentBuffer else { return }

        handDetector.performDetection(inputBuffer: buffer) { outputBuffer, _ in
            // Here we are on a background thread
            var previewImage: UIImage?

            defer {
                DispatchQueue.main.async {
                    self.previewView.image = previewImage
                    // Release currentBuffer when finished to allow processing next frame
                    self.currentBuffer = nil
                }
            }

            guard let outBuffer = outputBuffer else {
                return
            }

            // Create UIImage from CVPixelBuffer
            previewImage = UIImage(ciImage: CIImage(cvPixelBuffer: outBuffer))
        }
    }

    // MARK: - ARSCNViewDelegate

    func renderer(_: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let _ = anchor as? ARPlaneAnchor else { return nil }

        // We return a special type of SCNNode for ARPlaneAnchors
        return PlaneNode()
    }

    func renderer(_: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor,
            let planeNode = node as? PlaneNode else {
            return
        }
        planeNode.update(from: planeAnchor)
    }

    func renderer(_: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor,
            let planeNode = node as? PlaneNode else {
            return
        }
        planeNode.update(from: planeAnchor)
    }

}
