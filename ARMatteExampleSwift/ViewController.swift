/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller that connects the host app renderer to a display.
*/

import UIKit
import Metal
import MetalKit
import ARKit

extension MTKView: RenderDestinationProvider {
}

class ViewController: UIViewController, MTKViewDelegate, ARSessionDelegate {
    
    var session = ARSession()
    var renderer: Renderer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // トラッキングを設定
        let configuration = ARWorldTrackingConfiguration()
        // 人のセグメントを取りたいので.personSegmentationに設定する
        configuration.frameSemantics = .personSegmentation
        session.run(configuration)
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
        // セッションにパース
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
}
