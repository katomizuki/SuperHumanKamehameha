/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller that connects the host app renderer to a display.
*/

import UIKit
import Metal
import MetalKit
import ARKit
import RealityKit

extension MTKView: RenderDestinationProvider {
}

class ViewController: UIViewController, MTKViewDelegate {
    private var audioPlayer:AVAudioPlayer?
    var isSpecialMoving = false
    var session = ARSession()
    var renderer: Renderer!
    var arView: ARView!
    var bodyAnchor: AnchorEntity = AnchorEntity()
    var rightHandAnchor: AnchorEntity = AnchorEntity()
    var leftHandAnchor: AnchorEntity = AnchorEntity()
    private lazy var sphere: ModelEntity = {
        let sphere = MeshResource.generateSphere(radius: 0.15)
        let simpleMaterial = SimpleMaterial(color: .cyan,
                                            isMetallic: false)
        // ModelEntityの作成
        let sphereEntity = ModelEntity(mesh: sphere,
                                 materials:[simpleMaterial])
        return sphereEntity
    }()
    
    private var layer: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.75)
        return layer
    }()
    
    private lazy var cylinder:ModelEntity = {
        let cylinder = try! Energy.loadScene().cylinder?.children.first as! ModelEntity
        cylinder.model?.materials = [SimpleMaterial(color: .white, isMetallic: false)]
        cylinder.orientation = simd_quatf(angle: -90 * .pi / 180, axis: [0,0,1])
        
        return cylinder
    }()

    enum SpecialMoveType {
        case rightHand
        case leftHand
        case doubleHand
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        arView = ARView(frame: view.bounds)
        // MTKViewに変換する。
        if let view = self.view as? MTKView {
          // MetalKitのデフォメソッドでDeviceを取得する
            view.device = MTLCreateSystemDefaultDevice()
            // 背景を透明
            view.backgroundColor = UIColor.clear
            // MTLViewDelegateを委任
            view.delegate = self
            // rendererをインスタンス化
            renderer = Renderer(session: session,
                                metalDevice: view.device!,
                                mtkView: view)
            // rendererのdrawメソッドを呼び出す
            renderer.drawRectResized(size: view.bounds.size)
        }
        view.addSubview(arView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // トラッキングを設定(身体トラック）
        let configuration = ARBodyTrackingConfiguration()
        // 人のセグメントを取りたいので.personSegmentationに設定する
        configuration.frameSemantics = .personSegmentation
        // セッションラン
        session.run(configuration)
        // arViewに右手アンカーと左手アンカーを使用する
        arView.scene.addAnchor(rightHandAnchor)
        arView.scene.addAnchor(leftHandAnchor)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // サイズの変更があった場合に再度レンダリングし直し
        renderer.drawRectResized(size: size)
    }
    
    func draw(in view: MTKView) {
        // ビューレンダリングが呼び出されたら発火。
        // rendererのupdateメソッドを呼び出す。
        renderer.update()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // セッションにパース 画面消えたら終わり
        session.pause()
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user

    }

    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay

    }

    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required

    }
    
    func specialMove(specialMove:SpecialMoveType) {
        // sphere
        let originSphere = sphere.clone(recursive: true)
        let destinationSphere = sphere.clone(recursive: true)
        let cylinder = cylinder.clone(recursive: true)
        let lightEntity = PointLight()
        let lightEntity2 = PointLight()
        let lightEntity3 = PointLight()
        
        var direction:Float = 1
        var color:UIColor = .cyan
        
        switch specialMove {
        case .doubleHand:
            color = .purple
            originSphere.scale = [1.2,1,1]
            destinationSphere.scale = [1.2,1,1]
            rightHandAnchor.addChild(originSphere)
            rightHandAnchor.addChild(destinationSphere)
            rightHandAnchor.addChild(cylinder)
            rightHandAnchor.addChild(lightEntity)
        case .leftHand:
            direction = -1
            color = .red
            leftHandAnchor.addChild(originSphere)
            leftHandAnchor.addChild(destinationSphere)
            leftHandAnchor.addChild(cylinder)
            leftHandAnchor.addChild(lightEntity)
        default:
            rightHandAnchor.addChild(originSphere)
            rightHandAnchor.addChild(destinationSphere)
            rightHandAnchor.addChild(cylinder)
            rightHandAnchor.addChild(lightEntity)
            
        }
        
        originSphere.model?.materials = [SimpleMaterial(color: color, isMetallic: false)]
        destinationSphere.model?.materials = [SimpleMaterial(color: color, isMetallic: false)]
        
        originSphere.position = [-0.2*direction,0,0]
        destinationSphere.position = [-0.2*direction,0,0]
        cylinder.position = [-0.2*direction,0,0]
        
        lightEntity.light.color = color
        lightEntity.light.intensity = 300000
        lightEntity.look(at: [0,0,0], from: [1*direction,0,0.3], relativeTo: lightEntity)
        lightEntity.light.attenuationRadius = 10
        
        lightEntity2.light.color = color
        lightEntity2.light.intensity = 300000
        lightEntity2.look(at: [0,0,0], from: [-1*direction,0,0.3], relativeTo: lightEntity)
        lightEntity2.light.attenuationRadius = 10
        originSphere.addChild(lightEntity2)
        
        lightEntity3.light.color = color
        lightEntity3.light.intensity = 300000
        lightEntity3.look(at: [0,0,0], from: [1*direction,0,0.3], relativeTo: lightEntity)
        lightEntity3.light.attenuationRadius = 10
        destinationSphere.addChild(lightEntity3)
        
        cylinder.move(to: Transform(scale: [1,300,1], translation: [0,-1.5*direction,0]), relativeTo: cylinder, duration: 3, timingFunction: .easeInOut)
        destinationSphere.move(to: Transform(translation: [0,-3*direction,0]), relativeTo: cylinder, duration: 3, timingFunction: .easeInOut)
        
        do {
            let audioResource = try AudioFileResource.load(named: "explosion.mp3",
                                                           in: nil,
                                                           inputMode: .spatial,
                                                           loadingStrategy: .preload,
                                                           shouldLoop: false)
            
            let audioPlaybackController = originSphere.prepareAudio(audioResource)
            audioPlaybackController.play()
        } catch {
            print("Error loading audio file")
        }
        
        Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { timer in
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 1, delay: 0, options: [.curveEaseInOut]) {
                self.arView.alpha = 0
            } completion: { UIViewAnimatingPosition in
                originSphere.isEnabled = false
                destinationSphere.isEnabled = false
                cylinder.isEnabled = false
                lightEntity.isEnabled = false
                originSphere.removeFromParent()
                destinationSphere.removeFromParent()
                cylinder.removeFromParent()
                lightEntity.removeFromParent()
                UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 2, delay: 1, options: [.curveEaseOut]) {
                    self.arView.alpha = 1
                    
                } completion: { UIViewAnimatingPosition in
                    Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { timer in
                        self.isSpecialMoving = false
                    }
                }
            }
            
        }
    }

    func layerAnimation() {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1
        animation.toValue = 0
        animation.duration = 1
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        self.arView.layer.add(animation, forKey: nil)
        Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _timer in
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = 0
            animation.toValue = 1
            animation.duration = 2
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
            self.arView.layer.add(animation, forKey: nil)
        }
    }
    
}

extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
    }
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        
    }
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let bodyAnchor = anchor as? ARBodyAnchor,
                  let rightHand = bodyAnchor.skeleton.modelTransform(for: .rightHand),
                  let leftHand = bodyAnchor.skeleton.modelTransform(for: .leftHand) else { continue }
            let rightHandX = rightHand.columns.3.x
            let leftHandX = leftHand.columns.3.x
            let rightHandY = rightHand.columns.3.y
            let leftHandY = leftHand.columns.3.y
            let rightHandZ = rightHand.columns.3.z
            let leftHandZ = leftHand.columns.3.z
            
            let rightMaxDistanceFromRoot = max(abs(rightHandX), abs(rightHandZ))
            let leftMaxDistanceFromRoot = max(abs(leftHandX), abs(leftHandZ))
            
            if rightHandX < -0.4 || rightHandX > 0.4 || leftHandX < -0.4 || leftHandX > 0.4
                || rightHandZ < -0.4 || rightHandZ > 0.4 || leftHandZ < -0.4 || leftHandZ > 0.4,
               !isSpecialMoving {
                isSpecialMoving = true
                var specialMoveType:SpecialMoveType = .rightHand
                
                let xDistance = abs(rightHandX - leftHandX)
                let yDistance = abs(rightHandY - leftHandY)
                let zDistance = abs(rightHandZ - leftHandZ)
                let totalDistanceBetweenRightAndLeft = xDistance + yDistance + zDistance
                if totalDistanceBetweenRightAndLeft < 0.3 {
                    specialMoveType = .doubleHand
                } else if leftMaxDistanceFromRoot > rightMaxDistanceFromRoot {
                    specialMoveType = .leftHand
                }
                specialMove(specialMove: specialMoveType)
            }
            
            if isSpecialMoving &&
                rightHandX > -0.4 && rightHandX < 0.4 && leftHandX > -0.4 && leftHandX < 0.4
                && rightHandZ > -0.4 && rightHandZ < 0.4 && leftHandZ > -0.4 && leftHandZ < 0.4 {
                
            }
            
            self.bodyAnchor.transform = Transform(matrix: bodyAnchor.transform)
            
            let handTransform = bodyAnchor.transform * rightHand
            rightHandAnchor.transform = Transform(matrix: handTransform)
            let leftHandTransform = bodyAnchor.transform * leftHand
            leftHandAnchor.transform = Transform(matrix: leftHandTransform)
        }
    }
}
