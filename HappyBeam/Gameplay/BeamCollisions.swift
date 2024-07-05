/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Collision and scoring logic for when a beam hits a cloud.
*/

import RealityKit
import SwiftUI

/// A counter for the number of collisions a particular cloud has received.
var hitCounts: [String: Int] = [:]

/// A map that determines whether the beam has collided with a particular cloud this round.
var ballIsHit: [String: Bool] = [:]

/// Determines whether a collision is a score or should be ignored.
@MainActor
func handleCollisionStart(for event: CollisionEvents.Began, gameModel: GameModel) async throws {
    if gameModel.isPaused {
        return
    }
    print("--- Collision ---",
          event.entityA.name, event.entityB.name,
          event.entityA.children.count, event.entityA.parent?.name as Any,
          event.entityB.children.count, event.entityB.parent?.name as Any
    )
    
    let targetNames = [BundleAssets.beamName, floorBeam.name, collisionEntityName]
    
    guard eventHasTargets(event: event, matching: targetNames) != nil else {
        print("No beam found in collision")
        return
    }
    
    guard let ball = eventHasTarget(event: event, matching: "CCloud") else {
        print("No ball found in collision")
        return
    }
    
    let minBallHits = 1
    var hitThisTurn = false
    if hitCounts[ball.name] == nil {
        hitCounts[ball.name] = 0
    }
    hitCounts[ball.name]! += 1
    
    if hitCounts[ball.name]! >= minBallHits && ballIsHit[ball.name] == nil {
        hitThisTurn = true
        ballIsHit[ball.name] = true
    }
    
    if hitThisTurn == false {
        return
    }
    
    try handleBallHit(for: ball, gameModel: gameModel)
}

/// Animate clouds when they're cheered up by the beam and forward the score during multiplayer.
@MainActor
func handleBallHit(for cloud: Entity, gameModel: GameModel, remote: Bool = false) throws {
    gameModel.score += 1
    
    if let localPlayer = gameModel.players.first(where: { $0.name == Player.localName }) {
        localPlayer.score += 1
    }
    
    cloudAnimate(cloud, kind: .smile, shouldRepeat: false)
    AccessibilityNotification.Announcement(String(localized: "Grumpy Cloud Hit")).post()
    
    // Play cloud hit sound.
    let cloudSound = gameModel.cloudSounds.randomElement()!
    let audioController = cloud.prepareAudio(cloudSound)
    audioController.gain = 15
    audioController.play()
    
    let goUp = FromToByAnimation<Transform>(
        name: "goUp",
        from: .init(scale: .init(repeating: 1), translation: cloud.position),
        to: .init(scale: .init(repeating: 1), translation: cloud.position + .init(x: 0, y: 2000, z: 6)),
        duration: 2,
        bindTarget: .transform
    )
    
    let goUpAnimation = try AnimationResource
        .generate(with: goUp)
    
    cloud.playAnimation(goUpAnimation, transitionDuration: 2)
    
    if let fireworks = globalFireworks {
        let clone = fireworks.clone(recursive: true)
        clone.position.y += 0.3
        clone.position.z += 0.5
        cloud.addChild(clone)
    }
    
    if remote == false {
        gameModel.balls.forEach { cloudInstance in
            if ("CCloud" + String(cloudInstance.id)) == cloud.name {
                gameModel.balls.first(where: { $0.id == cloudInstance.id })?.isHappy = true
                
                if gameModel.isSharePlaying {
                    sessionInfo?.reliableMessenger?.send(ScoreMessage(cloudID: cloudInstance.id)) { error in
                        if error != nil {
                            print("Error sending score message: ", error!)
                        }
                    }
                }
                
                cloudInstance.isHappy = true
            }
        }
    }
    
    guard cloud.descendentsWithModelComponent.first as? ModelEntity != nil else {
        fatalError("Cloud is not a model entity and has no descendents with a model entity.")
    }
    cloud.setMaterialParameterValues(parameter: "Rainbowfy", value: .float(1.0))
    cloud.setMaterialParameterValues(parameter: "animate_texture", value: .bool(true))
    
    Task { @MainActor () -> Void in
        try? await Task.sleep(for: .seconds(3))
        cloud.setMaterialParameterValues(parameter: "saturation", value: .float(1.0))
        cloud.removeFromParent()
    }
}
