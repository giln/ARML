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
    let previewView = UIImageView()
    var currentBuffer: CVPixelBuffer?
    let redView = UIView()
    var previousNode: SCNNode?

    let touchNode : SCNNode = {
        // Touch node configuration
        let sphere = SCNSphere(radius: 0.02)

        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red

        sphere.firstMaterial = material

        let sphereNode = SCNNode(geometry: nil)
        //sphereNode.isHidden = true

        let sphereShape = SCNPhysicsShape(geometry: sphere, options: nil)

        let physicsBody = SCNPhysicsBody(type: .kinematic, shape: sphereShape)
        sphereNode.physicsBody = physicsBody

        return sphereNode
    }()

    let visionQueue = DispatchQueue(label: "com.viseo.ARML.visionqueue")


    lazy var predictionRequest: VNCoreMLRequest = {
        // Load the ML model through its generated class and create a Vision request for it.
        do {
            let model = try VNCoreMLModel(for: HandModel().model)
            let request = VNCoreMLRequest(model: model)
            request.imageCropAndScaleOption = VNImageCropAndScaleOption.scaleFill
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

        sceneView.addSubview(redView)

        sceneView.automaticallyUpdatesLighting = false
        sceneView.autoenablesDefaultLighting = false

        redView.backgroundColor = UIColor.red
        redView.translatesAutoresizingMaskIntoConstraints = false
        redView.widthAnchor.constraint(equalToConstant: 10).isActive = true
        redView.heightAnchor.constraint(equalToConstant: 10).isActive = true

        previewView.translatesAutoresizingMaskIntoConstraints = false
        previewView.widthAnchor.constraint(equalToConstant: 112).isActive = true
        previewView.heightAnchor.constraint(equalToConstant: 112).isActive = true

        previewView.backgroundColor = UIColor.black
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

        sceneView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(viewDidTap(recognizer:))))


        sceneView.scene.rootNode.addChildNode(touchNode)

        insertSpotLight(position: SCNVector3(10, 50, 0))

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        configuration.planeDetection = .horizontal
        configuration.environmentTexturing = .automatic

        // Run the view's session
        sceneView.session.run(configuration)

        sceneView.session.delegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Pause the view's session
        sceneView.session.pause()

    }

    // MARK: - Actions

    func insertSpotLight(position: SCNVector3) {
        let spotLight = SCNLight()
        spotLight.type = .directional
        spotLight.shadowMode = .deferred
        spotLight.castsShadow = true
        spotLight.shadowRadius = 5.0
        // spotLight.categoryBitMask = 4
        spotLight.shadowColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.2)

        let spotNode = SCNNode()
        spotNode.light = spotLight
        spotNode.position = position
        spotNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        sceneView.scene.rootNode.addChildNode(spotNode)
    }

    @objc func viewDidTap(recognizer: UITapGestureRecognizer) {

        previousNode?.removeFromParentNode()

        let sphere = SCNSphere(radius: 0.05)

        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red

        let reflectiveMaterial = SCNMaterial()
        reflectiveMaterial.lightingModel = .physicallyBased
        reflectiveMaterial.metalness.contents = 0.8
        reflectiveMaterial.roughness.contents = 0.4
        sphere.firstMaterial = reflectiveMaterial

        //sphere.materials = [material]

        let sphereNode = SCNNode(geometry: sphere)

        let tapLocation = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)

        guard let hitTestResult = hitTestResults.first else { return }

        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        sphereNode.physicsBody = physicsBody
        //rocketshipNode.name = rocketshipNodeName

        sphereNode.simdTransform = hitTestResult.worldTransform

        sphereNode.position.y += 0.5

        sphereNode.castsShadow = true
        sceneView.scene.rootNode.addChildNode(sphereNode)

        previousNode = sphereNode
    }

    // MARK: - ARSCNViewDelegate

    /*
     // Override to create and configure nodes for anchors added to the view's session.
     func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
     let node = SCNNode()

     return node
     }
     */

    func renderer(_: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

        // 2
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)

        // 3

        let material = SCNMaterial()
        material.lightingModel = .constant
        //material.readsFromDepthBuffer = true
        material.writesToDepthBuffer = true
        material.colorBufferWriteMask = []

        plane.firstMaterial = material

        // 4
        var planeNode = SCNNode(geometry: plane)
        planeNode.castsShadow = false

        // 5
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
        planeNode.eulerAngles.x = -.pi / 2

        update(&planeNode, withGeometry: plane, type: .static)
        // 6
        node.addChildNode(planeNode)
    }

    func renderer(_: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // 1
        guard let planeAnchor = anchor as? ARPlaneAnchor,
            var planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
        else { return }

        // 2
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height

        // 3
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)

        update(&planeNode, withGeometry: plane, type: .static)

    }

    func update(_ node: inout SCNNode, withGeometry geometry: SCNGeometry, type: SCNPhysicsBodyType) {
        let shape = SCNPhysicsShape(geometry: geometry, options: nil)
        let physicsBody = SCNPhysicsBody(type: type, shape: shape)
        node.physicsBody = physicsBody
    }

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
        // why right orientation?
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: currentBuffer!, orientation: .right)

        visionQueue.async {
            try? requestHandler.perform([self.predictionRequest])

            guard let observation = self.predictionRequest.results?.first as? VNPixelBufferObservation else {
                fatalError("unexpected result type from VNCoreMLRequest")
            }

            let previewImage = UIImage(pixelBuffer: observation.pixelBuffer)
            let foundPoint = observation.pixelBuffer.search()

            DispatchQueue.main.async {
                self.previewView.image = previewImage
                self.currentBuffer = nil

                if let point = foundPoint {
                    let imagePoint = VNImagePointForNormalizedPoint(point, Int(self.view.bounds.size.width), Int(self.view.bounds.size.height))
                    self.redView.isHidden = true
                    self.redView.center = imagePoint

                    let hitTestResults = self.sceneView.hitTest(imagePoint, types: .existingPlaneUsingExtent)

                    guard let hitTestResult = hitTestResults.first else { return }

                    self.touchNode.simdTransform = hitTestResult.worldTransform


                } else {
                    self.redView.isHidden = true
                }
            }
        }
    }
}
