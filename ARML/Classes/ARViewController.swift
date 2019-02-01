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

public class ARViewController: UIViewController, ARSessionDelegate, ARSCNViewDelegate {
    // MARK: - Variables

    let sceneView = ARSCNView()
    var currentBuffer: CVPixelBuffer?
    var previewView = UIImageView()
    let touchNode = TouchNode()
    let ball = BallNode(radius: 0.05)

    // MARK: - Lifecycle

    override public func loadView() {
        super.loadView()

        view = sceneView

        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Enable Horizontal plane detection
        configuration.planeDetection = .horizontal

        sceneView.autoenablesDefaultLighting = true
        // Disabled because of random crash
        configuration.environmentTexturing = .none

        // We want to receive the frames from the video
        sceneView.session.delegate = self

        // Run the session with the configuration
        sceneView.session.run(configuration)

        // The delegate is used to receive ARAnchors when they are detected.
        sceneView.delegate = self

        sceneView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(viewDidTap(recognizer:))))

        view.addSubview(previewView)

        previewView.translatesAutoresizingMaskIntoConstraints = false
        previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        // Add spotlight to cast shadows
        let spotlightNode = SpotlightNode()
        spotlightNode.position = SCNVector3(10, 10, 0)
        sceneView.scene.rootNode.addChildNode(spotlightNode)

        // Add touchNode
        sceneView.scene.rootNode.addChildNode(touchNode)
    }

    // MARK: - Actions

    @objc private func viewDidTap(recognizer: UITapGestureRecognizer) {

        // We recycle the ball node
        ball.removeFromParentNode()
        ball.physicsBody?.clearAllForces()

        // We get the tap location as a 2D Screen coordinate
        let tapLocation = recognizer.location(in: sceneView)

        // To transform our 2D Screen coordinates to 3D screen coordinates we use hitTest function
        let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)

        // We cast a ray from the point tapped on screen, and we return any intersection with existing planes
        guard let hitTestResult = hitTestResults.first else { return }

        // We place the ball at hit point
        ball.simdTransform = hitTestResult.worldTransform
        // We place it slightly (20cm) above the plane
        ball.position.y += 0.20
        
        // We add the node to the scene
        sceneView.scene.rootNode.addChildNode(ball)
    }

    // MARK: - ARSessionDelegate

    public func session(_: ARSession, didUpdate frame: ARFrame) {
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
            var normalizedFingerTip: CGPoint?

            defer {
                DispatchQueue.main.async {
                    self.previewView.image = previewImage

                    // Release currentBuffer when finished to allow processing next frame
                    self.currentBuffer = nil

                    self.touchNode.isHidden = true
                    
                    guard let tipPoint = normalizedFingerTip else {
                        return
                    }

                    // We use a coreVideo function to get the image coordinate from the normalized point
                    let imageFingerPoint = VNImagePointForNormalizedPoint(tipPoint, Int(self.view.bounds.size.width), Int(self.view.bounds.size.height))

                    // And here again we need to hitTest to translate from 2D coordinates to 3D coordinates
                    let hitTestResults = self.sceneView.hitTest(imageFingerPoint, types: .existingPlaneUsingExtent)
                    guard let hitTestResult = hitTestResults.first else { return }

                    // We position our touchNode slighlty above the plane (1cm).
                    self.touchNode.simdTransform = hitTestResult.worldTransform
                    self.touchNode.position.y += 0.01
                    self.touchNode.isHidden = false
                }
            }

            guard let outBuffer = outputBuffer else {
                return
            }

            // Create UIImage from CVPixelBuffer
            previewImage = UIImage(ciImage: CIImage(cvPixelBuffer: outBuffer))

            normalizedFingerTip = outBuffer.searchTopPoint()

        }
    }

    // MARK: - ARSCNViewDelegate

    public func renderer(_: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let _ = anchor as? ARPlaneAnchor else { return nil }

        // We return a special type of SCNNode for ARPlaneAnchors
        return PlaneNode()
    }

    public func renderer(_: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor,
            let planeNode = node as? PlaneNode else {
            return
        }
        planeNode.update(from: planeAnchor)
    }

    public func renderer(_: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor,
            let planeNode = node as? PlaneNode else {
            return
        }
        planeNode.update(from: planeAnchor)
    }

}
