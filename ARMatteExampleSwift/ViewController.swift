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
    
//    var session: ARSession!
//    var renderer: Renderer!
    
    var session = ARSession()
    var renderer: Renderer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as? MTKView {
            view.device = MTLCreateSystemDefaultDevice()
            view.backgroundColor = UIColor.clear
            view.delegate = self
            print("ああああああああああ")
            renderer = Renderer(session: session, metalDevice: view.device!, mtkView: view)
            renderer.drawRectResized(size: view.bounds.size)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics = .personSegmentation
        session.run(configuration)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        print("いいいいいいいいああ")
        renderer.drawRectResized(size: size)
    }
    
    func draw(in view: MTKView) {
        print("うううううううう")
        renderer.update()
    }
    
//
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Pause the view's session
        session.pause()
    }

//
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
