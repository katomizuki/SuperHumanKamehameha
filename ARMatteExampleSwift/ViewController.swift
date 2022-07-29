
import UIKit
import Metal
import MetalKit
import ARKit
import RealityKit

extension MTKView: RenderDestinationProvider {
}

class ViewController: UIViewController, MTKViewDelegate {

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
        // Energyクラスからシーンをロードする
        let cylinder = try! Energy.loadScene().cylinder?.children.first as! ModelEntity
        let simpleMaterial = SimpleMaterial(color: .white,
                                            isMetallic: false)
        cylinder.model?.materials = [simpleMaterial]
        cylinder.orientation = simd_quatf(angle: -90 * .pi / 180,
                                          axis: [0, 0, 1])
        
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
        // sphereをクローン recursiveをtrueにすることで子要素までコピーする
        
        let originSphere = sphere.clone(recursive: true)
        // 目的地の球体をクローン
        let destinationSphere = sphere.clone(recursive: true)
        // cylinderをクローン
        let cylinder = cylinder.clone(recursive: true)
        // ライトをたくさん作る
        let lightEntity = PointLight()
        let lightEntity2 = PointLight()
        let lightEntity3 = PointLight()
        
        var direction: Float = 1
        var color: UIColor = .cyan
        
        // トラっキンングした動きで分ける
        switch specialMove {
        case .doubleHand:
            // 色を変える
            color = .purple
            // 大きさを変更する（大きくする）
            originSphere.scale = [1.2,1,1]
            // 目的Sphereも同様
            destinationSphere.scale = [1.2,1,1]
            // 右手に球アンカーを入れる
            rightHandAnchor.addChild(originSphere)
            rightHandAnchor.addChild(destinationSphere)
            // 円筒を入れる
            rightHandAnchor.addChild(cylinder)
            rightHandAnchor.addChild(lightEntity)
        case .leftHand:
            // 距離を短くする
            direction = -1
            // 色をレッド
            color = .red
            // 左手に球アンカーを追加する
            leftHandAnchor.addChild(originSphere)
            leftHandAnchor.addChild(destinationSphere)
            //円筒を入れる
            leftHandAnchor.addChild(cylinder)
            leftHandAnchor.addChild(lightEntity)
        default:
            rightHandAnchor.addChild(originSphere)
            rightHandAnchor.addChild(destinationSphere)
            rightHandAnchor.addChild(cylinder)
            rightHandAnchor.addChild(lightEntity)
            
        }
        let simpleMaterial = SimpleMaterial(color: color, isMetallic: false)
        originSphere.model?.materials = [simpleMaterial]
        destinationSphere.model?.materials = [simpleMaterial]
        
        // それぞれのポジションを指定
        originSphere.position = [-0.2 * direction, 0, 0]
        destinationSphere.position = [-0.2 * direction, 0, 0]
        cylinder.position = [-0.2 * direction, 0, 0]
        
        lightEntity.light.color = color
        lightEntity.light.intensity = 300000
        // ライトエンティティの向き先を指定 at（ここから） fromまで lightEntityのオブジェクト座標
        lightEntity.look(at: [0, 0, 0],
                         from: [1 * direction, 0, 0.3],
                         relativeTo: lightEntity)
        // 円筒への中心へどれくらいいくかを指定
        lightEntity.light.attenuationRadius = 10
        originSphere.addChild(lightEntity)
        
        lightEntity2.light.color = color
        lightEntity2.light.intensity = 300000
        lightEntity2.look(at: [0,0,0],
                          from: [-1 * direction, 0, 0.3],
                          relativeTo: lightEntity)
        lightEntity2.light.attenuationRadius = 10
        originSphere.addChild(lightEntity2)
        
        // LightEntity3を目的球アンカーに入れる
        lightEntity3.light.color = color
        lightEntity3.light.intensity = 300000
        lightEntity3.look(at: [0, 0, 0],
                          from: [1 * direction, 0, 0.3],
                          relativeTo: lightEntity)
        lightEntity3.light.attenuationRadius = 10
        destinationSphere.addChild(lightEntity3)
        
        // 円筒をmoveメソッドで動かす（toまで)
        let toTransform = Transform(scale: [1, 300, 1],
                                    translation: [0, -1.5 * direction, 0])
        // 3秒間で目的地にeaseInOutで遷移する(cylinderのオブジェクト座標）
        cylinder.move(to: toTransform,
                      relativeTo: cylinder,
                      duration: 3,
                      timingFunction: .easeInOut)
        let destinationTransform = Transform(translation: [0, -3 * direction, 0])
        //3秒間でdestinationTransform cylinder 3秒間 easeInout
        destinationSphere.move(to: destinationTransform,
                               relativeTo: cylinder,
                               duration: 3,
                               timingFunction: .easeInOut)
        
        // 3秒間でリピートせずに
        Timer.scheduledTimer(withTimeInterval: 3,
                             repeats: false) { timer in
            // 一秒間で間髪なくcurveEaseInOutでアニメーショをする
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 1,
                                                           delay: 0,
                                                           options: [.curveEaseInOut]) {
                // arViewのアルファを0にする
                self.arView.alpha = 0
            } completion: { UIViewAnimatingPosition in
                // あにめ〜ションが終わったら全てのオブジェクトを使えなくして、親オブジェクトを削除する
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
                    self.layerAnimation()
                    
                } completion: { UIViewAnimatingPosition in
                    Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { timer in
                        self.isSpecialMoving = false
                        
                    }
                }
            }
            
        }
    }

    // カメハメ波を打った後に画面を薄くする処理
    func layerAnimation() {
        //　薄くするアニメーションをインスタンス
        let animation = CABasicAnimation(keyPath: "opacity")
        // 1から
        animation.fromValue = 1
        // 0まで
        animation.toValue = 0
        // 一秒間で
        animation.duration = 1
        // どれくらいのアニメーションで(easeInEaseOut
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        // arViewのLayerにアニメーションを入れる
        self.arView.layer.add(animation, forKey: nil)
        // Timer二秒間でリピートはfalse
        Timer.scheduledTimer(withTimeInterval: 2,
                             repeats: false) { _timer in
            // インスタンス
            let animation = CABasicAnimation(keyPath: "opacity")
            // 0から
            animation.fromValue = 0
            // 1まで
            animation.toValue = 1
            // 二秒間で
            animation.duration = 2
            // どんなanimationで行うか
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
            // arviewに追加する
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
        // BodyAnchorを検知したら
        for anchor in anchors {
            guard let bodyAnchor = anchor as? ARBodyAnchor,
                  let rightHand = bodyAnchor.skeleton.modelTransform(for: .rightHand),
                  let leftHand = bodyAnchor.skeleton.modelTransform(for: .leftHand) else { continue }
            // それぞれライトハンドと左はんどを取ってきて変数に入れる
            // それぞれの座標をわかりやすく変数に入れる。
            let rightHandX = rightHand.columns.3.x
            let leftHandX = leftHand.columns.3.x
            let rightHandY = rightHand.columns.3.y
            let leftHandY = leftHand.columns.3.y
            let rightHandZ = rightHand.columns.3.z
            let leftHandZ = leftHand.columns.3.z
            
            // 右手のx座標と右手座標の絶対値でどっちが遠いか判断する// 左手も同様。これはどこから光を放つかを想定。
            let rightMaxDistanceFromRoot = max(abs(rightHandX), abs(rightHandZ))
            let leftMaxDistanceFromRoot = max(abs(leftHandX), abs(leftHandZ))
            
            if rightHandX < -0.4 || rightHandX > 0.4 || leftHandX < -0.4 || leftHandX > 0.4
                || rightHandZ < -0.4 || rightHandZ > 0.4 || leftHandZ < -0.4 || leftHandZ > 0.4,
               !isSpecialMoving {
                // 発射し始めたのでここをtrueにする
                isSpecialMoving = true
                var specialMoveType: SpecialMoveType = .rightHand
                // 左手と右手のXの座標の差
                let xDistance = abs(rightHandX - leftHandX)
                // 左手と右手の座標の差
                let yDistance = abs(rightHandY - leftHandY)
                // 左手と右手の座標の差（ｚ座標）
                let zDistance = abs(rightHandZ - leftHandZ)
                // これらを全て足す。
                let totalDistanceBetweenRightAndLeft = xDistance + yDistance + zDistance
                // ここの距離が0.3より小さければ両手で反応しているということになる。
                if totalDistanceBetweenRightAndLeft < 0.3 {
                    // 両手モード
                    specialMoveType = .doubleHand
                } else if leftMaxDistanceFromRoot > rightMaxDistanceFromRoot {
                    // 左手モード
                    specialMoveType = .leftHand
                }
                // カメハメ波を発射。
                specialMove(specialMove: specialMoveType)
            }
            
            // bodyAnchorを更新
            self.bodyAnchor.transform = Transform(matrix: bodyAnchor.transform)
            // 秒列で移動 & 更新
            let handTransform = bodyAnchor.transform * rightHand
            rightHandAnchor.transform = Transform(matrix: handTransform)
            // 行列移動 & 更新
            let leftHandTransform = bodyAnchor.transform * leftHand
            leftHandAnchor.transform = Transform(matrix: leftHandTransform)
        }
    }
}
