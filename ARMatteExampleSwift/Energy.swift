//
//  Energy.swift
//  ARMatteExampleSwift
//
//  Created by ミズキ on 2022/07/29.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import RealityKit
import simd
import Combine

@available(iOS 13.0, macOS 10.15, *)
public enum Energy {

    public enum LoadRealityFileError: Error {
        case fileNotFound(String)
    }

    private static var streams = [Combine.AnyCancellable]()

    public static func loadScene() throws -> Energy.Scene {
        guard let realityFileURL = Foundation.Bundle(for: Energy.Scene.self).url(forResource: "energy", withExtension: "reality") else {
            throw Energy.LoadRealityFileError.fileNotFound("energy.reality")
        }

        let realityFileSceneURL = realityFileURL.appendingPathComponent("scene", isDirectory: false)
        let anchorEntity = try Energy.Scene.loadAnchor(contentsOf: realityFileSceneURL)
        return createScene(from: anchorEntity)
    }

    public static func loadSceneAsync(completion: @escaping (Swift.Result<Energy.Scene, Swift.Error>) -> Void) {
        guard let realityFileURL = Foundation.Bundle(for: Energy.Scene.self).url(forResource: "energy", withExtension: "reality") else {
            completion(.failure(Energy.LoadRealityFileError.fileNotFound("energy.reality")))
            return
        }

        var cancellable: Combine.AnyCancellable?
        let realityFileSceneURL = realityFileURL.appendingPathComponent("scene", isDirectory: false)
        let loadRequest = Energy.Scene.loadAnchorAsync(contentsOf: realityFileSceneURL)
        cancellable = loadRequest.sink(receiveCompletion: { loadCompletion in
            if case let .failure(error) = loadCompletion {
                completion(.failure(error))
            }
            streams.removeAll { $0 === cancellable }
        }, receiveValue: { entity in
            completion(.success(Energy.createScene(from: entity)))
        })
        cancellable?.store(in: &streams)
    }

    private static func createScene(from anchorEntity: RealityKit.AnchorEntity) -> Energy.Scene {
        let scene = Energy.Scene()
        scene.anchoring = anchorEntity.anchoring
        scene.addChild(anchorEntity)
        return scene
    }

    public class Scene: RealityKit.Entity, RealityKit.HasAnchoring {

        public var cylinder: RealityKit.Entity? {
            return self.findEntity(named: "cylinder")
        }



        public var originSphere: RealityKit.Entity? {
            return self.findEntity(named: "originSphere")
        }



    }

}
