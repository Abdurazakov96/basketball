//
//  ViewController.swift
//  basketball
//
//  Created by Магомед Абдуразаков on 14/07/2019.
//  Copyright © 2019 Магомед Абдуразаков. All rights reserved.
//

import ARKit

class ViewController: UIViewController, SCNPhysicsContactDelegate{
    
    // MARK: - IBOutlets
    
    @IBOutlet var sceneView: ARSCNView!
    
    // MARK: - Private Properties
    private var score = 0
    private var check = false
    private var scoreW = SCNNode()
    private var isHoopPlaced = false {
        didSet {
            if isHoopPlaced {
                guard  let configuration = sceneView.session.configuration as? ARWorldTrackingConfiguration
                    else { return }
                configuration.planeDetection = []
                sceneView.session.run(configuration)
            }
            
        }
        
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Set the scene to the view
        
        sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .vertical
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - Private Methods
    
    private func addHoop(result: ARHitTestResult) {
        
        let hoop = SCNScene(named: "art.scnassets/hoop.scn")!.rootNode.clone()
        hoop.simdTransform = result.worldTransform
        hoop.eulerAngles.x -= .pi / 2
        
        guard let box = hoop.childNode(withName: "box", recursively: false) else { return }
        guard let planeDown = box.childNode(withName: "planeDown", recursively: false) else { return }
        guard let planeUp = box.childNode(withName: "planeUp", recursively: false) else { return }
        guard let torusMiddle = box.childNode(withName: "torus", recursively: false) else { return }
        
        
        let boxShape = SCNPhysicsShape(node: box, options: [SCNPhysicsShape.Option.type : SCNPhysicsShape.ShapeType.concavePolyhedron])
        let boxBody = SCNPhysicsBody(type: .static, shape: boxShape)
        box.physicsBody = boxBody
        box.physicsBody?.categoryBitMask = BitMaskCategory.box
        box.physicsBody?.collisionBitMask = BitMaskCategory.ball
        box.physicsBody?.contactTestBitMask = BitMaskCategory.ball
        
        let planeUpShape = SCNPhysicsShape(node: planeUp, options: [SCNPhysicsShape.Option.type : SCNPhysicsShape.ShapeType.concavePolyhedron])
        let topPlaneUpBody = SCNPhysicsBody(type: .static, shape: planeUpShape)
        planeUp.physicsBody = topPlaneUpBody
        planeUp.physicsBody?.categoryBitMask = BitMaskCategory.planeUp
        // torusTop.physicsBody?.collisionBitMask = BitMaskCategory.ball
        planeUp.physicsBody?.contactTestBitMask = BitMaskCategory.ball
        planeUp.opacity = 0
        
        let middleTorusShape = SCNPhysicsShape(node: torusMiddle, options: [SCNPhysicsShape.Option.type : SCNPhysicsShape.ShapeType.concavePolyhedron])
        let middleTorusBody = SCNPhysicsBody(type: .static, shape: middleTorusShape)
        torusMiddle.physicsBody = middleTorusBody
        torusMiddle.physicsBody?.categoryBitMask = BitMaskCategory.torusMiddle
        torusMiddle.physicsBody?.collisionBitMask = BitMaskCategory.ball
        torusMiddle.physicsBody?.contactTestBitMask = BitMaskCategory.ball
        
        let planeDownShape = SCNPhysicsShape(node: planeDown, options: [SCNPhysicsShape.Option.type : SCNPhysicsShape.ShapeType.concavePolyhedron])
        let planeDownBody = SCNPhysicsBody(type: .static, shape: planeDownShape)
        planeDown.physicsBody = planeDownBody
        planeDown.physicsBody?.categoryBitMask = BitMaskCategory.planeDown
        planeDown.physicsBody?.contactTestBitMask = BitMaskCategory.ball
        planeDown.opacity = 0
        
        
        scoreW = CreateScoreBoard(String(score))
        
        sceneView.scene.rootNode.addChildNode(scoreW)
        
        sceneView.scene.rootNode.addChildNode(box)
        
        sceneView.scene.rootNode.enumerateChildNodes { node, _ in
            if node.name == "wall"  {
                node.removeFromParentNode()
            }
            
        }
        
    }
    
    private func addBall() {
        
        guard let frame = sceneView.session.currentFrame else {return}
        
        let ball = SCNNode(geometry: SCNSphere(radius: 0.25))
        ball.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(
            node: ball,
            options: [SCNPhysicsShape.Option.collisionMargin: 0.01]))
        ball.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "art.scnassets/ball.jpg")
        
        let transform = SCNMatrix4(frame.camera.transform)
        ball.transform = transform
        let power = Float(10)
        let force =  SCNVector3(power * -transform.m31, power * -transform.m32,power * -transform.m33)
        
        ball.name = "Ball"
        ball.physicsBody?.applyForce(force, asImpulse: true)
        ball.physicsBody?.categoryBitMask = BitMaskCategory.ball
        ball.physicsBody?.collisionBitMask =  BitMaskCategory.torusMiddle | BitMaskCategory.box | BitMaskCategory.ball
        ball.physicsBody?.contactTestBitMask = BitMaskCategory.planeUp | BitMaskCategory.torusMiddle | BitMaskCategory.planeDown | BitMaskCategory.box
        sceneView.scene.rootNode.addChildNode(ball)
    }
    
    private func CreateScoreBoard(_ stringForScore: String) -> SCNNode {
        
        let scoreSCN = SCNText(string: stringForScore, extrusionDepth: 1)
        scoreSCN.firstMaterial?.diffuse.contents = UIColor.red
        scoreSCN.removeAllAnimations()
        
        let scoreBoard = SCNNode(geometry: scoreSCN)
        scoreBoard.scale = SCNVector3(0.02, 0.02, 0.02)
        scoreBoard.position = SCNVector3(x: 0.1, y: 0.95, z: -1.98 )
        
        return(scoreBoard)
    }
    
    private func CreateWall(planeAnchor:ARPlaneAnchor)  -> SCNNode {
        
        let extent = planeAnchor.extent
        let width = extent.x
        let height = extent.z
        let plane = SCNPlane(width: CGFloat(width), height: CGFloat(height))
        
        plane.firstMaterial?.diffuse.contents = UIColor.red
        
        let wall = SCNNode(geometry: plane)
        
        wall.name = "wall"
        wall.eulerAngles.x = -.pi/2
        
        return wall
    }
    
        // MARK: - Public method
    
     func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        if contact.nodeA.physicsBody?.categoryBitMask == BitMaskCategory.ball && contact.nodeB.physicsBody?.categoryBitMask == BitMaskCategory.planeUp {
            check = true
        }
        
        if contact.nodeA.physicsBody?.categoryBitMask == BitMaskCategory.ball && contact.nodeB.physicsBody?.categoryBitMask == BitMaskCategory.planeDown && check == true {
            score += 1
            check = false
            scoreW.removeFromParentNode()
            scoreW.removeAllAnimations()
            scoreW = CreateScoreBoard(String(score))
            
            sceneView.scene.rootNode.addChildNode(scoreW)
        }
        
    }
    
    // MARK: - IBAction
    
    @IBAction func screenTapped(_ sender: UITapGestureRecognizer) {
        addBall()
        if isHoopPlaced {
        } else {
            let touchLocation = sender.location (in: sceneView)
            let hittestResult = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
            if let nearestresult = hittestResult.first {
                addHoop(result: nearestresult)
                sceneView.scene.physicsWorld.contactDelegate = self
                isHoopPlaced = true
            }
            
        }
        
    }
    
}

// MARK: - Extension

extension ViewController: ARSCNViewDelegate {
    
    // MARK: - Public method
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        let wall = CreateWall(planeAnchor: planeAnchor)
        node.addChildNode(wall)
    }
    
}
