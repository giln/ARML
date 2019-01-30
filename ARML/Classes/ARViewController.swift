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

class ARViewController: UIViewController, ARSessionDelegate {
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
}
