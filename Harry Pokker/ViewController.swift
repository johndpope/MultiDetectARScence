//
//  ViewController.swift
//  Harry Pokker
//
//  Created by Bilguun Batbold on 26/3/19.
//  Copyright © 2019 Bilguun. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
func colorCubeFilterForChromaKey(hueAngle: Float) -> CIFilter {
    func RGBtoHSV(r : Float, g : Float, b : Float) -> (h : Float, s : Float, v : Float) {
        var h : CGFloat = 0
        var s : CGFloat = 0
        var v : CGFloat = 0
        let col = UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1.0)
        col.getHue(&h, saturation: &s, brightness: &v, alpha: nil)
        return (Float(h), Float(s), Float(v))
    }

    let hueRange: Float = 20 // degrees size pie shape that we want to replace
    let minHueAngle: Float = (hueAngle - hueRange/2.0) / 360
    let maxHueAngle: Float = (hueAngle + hueRange/2.0) / 360

    let size = 64
    var cubeData = [Float](repeating: 0, count: size * size * size * 4)
    var rgb: [Float] = [0, 0, 0]
    var hsv: (h : Float, s : Float, v : Float)
    var offset = 0

    for z in 0 ..< size {
        rgb[2] = Float(z) / Float(size) // blue value
        for y in 0 ..< size {
            rgb[1] = Float(y) / Float(size) // green value
            for x in 0 ..< size {

                rgb[0] = Float(x) / Float(size) // red value
                hsv = RGBtoHSV(r: rgb[0], g: rgb[1], b: rgb[2])
                // TODO: Check if hsv.s > 0.5 is really nesseccary
                let alpha: Float = (hsv.h > minHueAngle && hsv.h < maxHueAngle && hsv.s > 0.5) ? 0 : 1.0

                cubeData[offset] = rgb[0] * alpha
                cubeData[offset + 1] = rgb[1] * alpha
                cubeData[offset + 2] = rgb[2] * alpha
                cubeData[offset + 3] = alpha
                offset += 4
            }
        }
    }
    let b = cubeData.withUnsafeBufferPointer { Data(buffer: $0) }
    let data = b as NSData

    let colorCube = CIFilter(name: "CIColorCube", parameters: [
        "inputCubeDimension": size,
        "inputCubeData": data
        ])
    return colorCube!
}

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARImageTrackingConfiguration()
        
        // first see if there is a folder called "ARImages" Resource Group in our Assets Folder
        if let trackedImages = ARReferenceImage.referenceImages(inGroupNamed: "ARImages", bundle: Bundle.main) {
            
            // if there is, set the images to track
            configuration.trackingImages = trackedImages
            // at any point in time, only 1 image will be tracked
            configuration.maximumNumberOfTrackedImages = 2
        }
        sceneView.showsStatistics = true
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {

        // if the anchor is not of type ARImageAnchor (which means image is not detected), just return
        guard let imageAnchor = anchor as? ARImageAnchor, let fileUrlString = Bundle.main.path(forResource: "arrow", ofType: "mov") else {return}
        //find our video file
        if(imageAnchor.referenceImage.name! == "black"){
            let videoItem = AVPlayerItem(url: URL(fileURLWithPath: fileUrlString))
            
            let player = AVPlayer(playerItem: videoItem)
            //initialize video node with avplayer
            let videoNode = SKVideoNode(avPlayer: player)
            player.play()
            let effectNode = SKEffectNode()
            effectNode.addChild(videoNode)
            effectNode.filter = colorCubeFilterForChromaKey(hueAngle: 117)

            // add observer when our player.currentItem finishes player, then start playing from the beginning
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: nil) { (notification) in
                player.seek(to: CMTime.zero)
                player.play()
                print("Looping Video")
            }
            
            // set the size (just a rough one will do)
            let videoScene = SKScene(size: CGSize(width: 480, height: 360))
            videoScene.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha:0.0 )
    //        videoScene.view = "allow"
            
            // center our video to the size of our video scene
            videoNode.position = CGPoint(x: videoScene.size.width / 2, y: videoScene.size.height / 2)
            // invert our video so it does not look upside down
            videoNode.yScale = -1.0
            // add the video to our scene
            videoScene.addChild(effectNode)
            // create a plan that has the same real world height and width as our detected image
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width/6, height: imageAnchor.referenceImage.physicalSize.height/6)
            // set the first materials content to be our video scene
            plane.firstMaterial?.diffuse.contents = videoScene
            plane.firstMaterial?.isDoubleSided = true
            // create a node out of the plane
            let planeNode = SCNNode(geometry: plane)
            let planeNodeB = SCNNode(geometry: plane)
            // since the created node will be vertical, rotate it along the x axis to have it be horizontal or parallel to our detected image
            planeNode.eulerAngles.x = -Float.pi / 2
            planeNode.position = SCNVector3(0.06,0.005,0.062)
            planeNodeB.eulerAngles.x = -Float.pi / 2
            planeNodeB.position = SCNVector3(-0.06,0.005,0.062)
            // finally add the plane node (which contains the video node) to the added node
            node.addChildNode(planeNode)
    //        let PlaneB = createArrow(fileUrlString: fileUrlString,imageAnchor: imageAnchor)
            node.addChildNode(planeNodeB)
            
            let fileUrlStringEU = Bundle.main.path(forResource: "eurocoin", ofType: "mov")!
            
            let videoItemEU = AVPlayerItem(url: URL(fileURLWithPath: fileUrlStringEU))
            
            let playerEU = AVPlayer(playerItem: videoItemEU)
            //initialize video node with avplayer
            let videoNodeEU = SKVideoNode(avPlayer: playerEU)
            
    //        let playerQ = AVQueuePlayer()
    //        let playerLayer = AVPlayerLayer(player: playerQ)
    //        let looperPlayer = AVPlayerLooper(player: playerQ, templateItem : videoItemEU)
            playerEU.play()
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerEU.currentItem, queue: nil) { (notification) in
                playerEU.seek(to: CMTime.zero)
                playerEU.play()
                print("Looping Video")
            }

            let effectNodeEU = SKEffectNode()
            effectNodeEU.addChild(videoNodeEU)
            effectNodeEU.filter = colorCubeFilterForChromaKey(hueAngle: 117)
            let videoSceneEU = SKScene(size: CGSize(width: 480, height: 360))
            videoSceneEU.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha:0.0 )
            videoNodeEU.position = CGPoint(x: videoSceneEU.size.width / 2, y: videoSceneEU.size.height / 2)
            videoNodeEU.yScale = -1.0
            videoSceneEU.addChild(effectNodeEU)
            let planeEU = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
            planeEU.firstMaterial?.diffuse.contents = videoSceneEU
            planeEU.firstMaterial?.isDoubleSided = true
            let planeNodeEU = SCNNode(geometry: planeEU)
            planeNodeEU.eulerAngles.x = -Float.pi / 2
            planeNodeEU.position = SCNVector3(0,0.0005,0)
            node.addChildNode(planeNodeEU)
        }else{
            let videoItem = AVPlayerItem(url: URL(fileURLWithPath: fileUrlString))
            
            let player = AVPlayer(playerItem: videoItem)
            //initialize video node with avplayer
            let videoNode = SKVideoNode(avPlayer: player)
            player.play()
            let effectNode = SKEffectNode()
            effectNode.addChild(videoNode)
            effectNode.filter = colorCubeFilterForChromaKey(hueAngle: 117)

            // add observer when our player.currentItem finishes player, then start playing from the beginning
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: nil) { (notification) in
                player.seek(to: CMTime.zero)
                player.play()
                print("Looping Video")
            }
            
            // set the size (just a rough one will do)
            let videoScene = SKScene(size: CGSize(width: 480, height: 360))
            videoScene.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha:0.0 )
    //        videoScene.view = "allow"
            
            // center our video to the size of our video scene
            videoNode.position = CGPoint(x: videoScene.size.width / 2, y: videoScene.size.height / 2)
            // invert our video so it does not look upside down
            videoNode.yScale = -1.0
            // add the video to our scene
            videoScene.addChild(effectNode)
            // create a plan that has the same real world height and width as our detected image
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width/6, height: imageAnchor.referenceImage.physicalSize.height/6)
            // set the first materials content to be our video scene
            plane.firstMaterial?.diffuse.contents = videoScene
            plane.firstMaterial?.isDoubleSided = true
            // create a node out of the plane
            let planeNode = SCNNode(geometry: plane)
            let planeNodeB = SCNNode(geometry: plane)
            // since the created node will be vertical, rotate it along the x axis to have it be horizontal or parallel to our detected image
            planeNode.eulerAngles.x = -Float.pi / 2
            planeNode.position = SCNVector3(0.06,0.005,0.062)
            planeNodeB.eulerAngles.x = -Float.pi / 2
            planeNodeB.position = SCNVector3(-0.06,0.005,0.062)
            // finally add the plane node (which contains the video node) to the added node
            node.addChildNode(planeNode)
    //        let PlaneB = createArrow(fileUrlString: fileUrlString,imageAnchor: imageAnchor)
            node.addChildNode(planeNodeB)
            
            let fileUrlStringEU = Bundle.main.path(forResource: "Explosion", ofType: "mov")!
            
            let videoItemEU = AVPlayerItem(url: URL(fileURLWithPath: fileUrlStringEU))
            
            let playerEU = AVPlayer(playerItem: videoItemEU)
            //initialize video node with avplayer
            let videoNodeEU = SKVideoNode(avPlayer: playerEU)
            
    //        let playerQ = AVQueuePlayer()
    //        let playerLayer = AVPlayerLayer(player: playerQ)
    //        let looperPlayer = AVPlayerLooper(player: playerQ, templateItem : videoItemEU)
            playerEU.play()
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerEU.currentItem, queue: nil) { (notification) in
                playerEU.seek(to: CMTime.zero)
                playerEU.play()
                print("Looping Video")
            }

            let effectNodeEU = SKEffectNode()
            effectNodeEU.addChild(videoNodeEU)
            effectNodeEU.filter = colorCubeFilterForChromaKey(hueAngle: 130)
            let videoSceneEU = SKScene(size: CGSize(width: 480, height: 360))
            videoSceneEU.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha:0.0 )
            videoNodeEU.position = CGPoint(x: videoSceneEU.size.width / 2, y: videoSceneEU.size.height / 2)
            videoNodeEU.yScale = -1.0
            videoSceneEU.addChild(effectNodeEU)
            let planeEU = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
            planeEU.firstMaterial?.diffuse.contents = videoSceneEU
            planeEU.firstMaterial?.isDoubleSided = true
            let planeNodeEU = SCNNode(geometry: planeEU)
            planeNodeEU.eulerAngles.x = -Float.pi / 2
            planeNodeEU.position = SCNVector3(0,0.0005,0)
            node.addChildNode(planeNodeEU)

        }

    }
}
func createArrow(fileUrlString : Any ,imageAnchor : Any) -> SCNNode{
    //find our video file

    let videoItem = AVPlayerItem(url: URL(fileURLWithPath: fileUrlString as! String))
    
    let player = AVPlayer(playerItem: videoItem)
    //initialize video node with avplayer
    let videoNode = SKVideoNode(avPlayer: player)
    player.play()
    let effectNode = SKEffectNode()
    effectNode.addChild(videoNode)
    effectNode.filter = colorCubeFilterForChromaKey(hueAngle: 117)

    // add observer when our player.currentItem finishes player, then start playing from the beginning
    NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: nil) { (notification) in
        player.seek(to: CMTime.zero)
        player.play()
        print("Looping Video")
    }
    
    // set the size (just a rough one will do)
    let videoScene = SKScene(size: CGSize(width: 480, height: 360))
    videoScene.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha:0.0 )
//        videoScene.view = "allow"
    
    // center our video to the size of our video scene
    videoNode.position = CGPoint(x: videoScene.size.width / 2, y: videoScene.size.height / 2)
    // invert our video so it does not look upside down
    videoNode.yScale = -1.0
    // add the video to our scene
    videoScene.addChild(effectNode)
    // create a plan that has the same real world height and width as our detected image
    let plane = SCNPlane(width: (imageAnchor as AnyObject).referenceImage.physicalSize.width/6, height: (imageAnchor as AnyObject).referenceImage.physicalSize.height/6)
    // set the first materials content to be our video scene
    plane.firstMaterial?.diffuse.contents = videoScene
    plane.firstMaterial?.isDoubleSided = true
    // create a node out of the plane
    let PlaneNodeArrow = SCNNode(geometry: plane)
    // since the created node will be vertical, rotate it along the x axis to have it be horizontal or parallel to our detected image
    PlaneNodeArrow.eulerAngles.x = -Float.pi / 2
    PlaneNodeArrow.position = SCNVector3(0.06,0,0.05)

    return PlaneNodeArrow
}
