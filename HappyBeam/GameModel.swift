/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's model type for game state and gameplay information.
*/

import AVKit
import RealityKit
import SwiftUI

/// State that drives the different screens of the game and options that players select.
@Observable
class GameModel {
    var isPlaying = false
    var isPaused = false {
        didSet {
            if isPaused == true {
                gameplayPlayer.pause()
                
                for child in spaceOrigin.children {
                    if child.name.contains("CCloud") {
                        child.stopAllAnimations(recursive: false)
                    }
                }
            } else {
                gameplayPlayer.play()
                
                for child in spaceOrigin.children {
                    if child.name.contains("CCloud") {
//                        let start = Point3D(child.position)
//                        let end = Point3D(
//                            start.vector + .init(
//                                x: BallSpawnParameters.deltaX,
//                                y: BallSpawnParameters.deltaY,
//                                z: BallSpawnParameters.deltaZ
//                            )
//                        )
//                        
//                        let line = FromToByAnimation<Transform>(
//                            name: "line",
//                            from: .init(scale: .init(repeating: 1), translation: simd_float(start.vector)),
//                            to: .init(scale: .init(repeating: 1), translation: simd_float(end.vector)),
//                            duration: BallSpawnParameters.speed / 10.0,
//                            bindTarget: .transform
//                        )
//                        
//                        let animation = try! AnimationResource
//                            .generate(with: line)
//                        
                        //child.playAnimation(animation, transitionDuration: 0.0, startsPaused: false)
                        //child.playAnimation(child.availableAnimations[0])
                    }
                }
            }
        }
    }
    
    /// A Boolean value that indicates that game assets have loaded.
    var readyToStart = false
    
    // Music players.
    var victoryPlayer = try! AVAudioPlayer(contentsOf: Bundle.main.url(forResource: "happyBeamVictory", withExtension: "m4a")!)
    var gameplayPlayer = try! AVAudioPlayer(contentsOf: Bundle.main.url(forResource: "happyBeamGameplay", withExtension: "m4a")!)
    var menuPlayer = try! AVAudioPlayer(contentsOf: Bundle.main.url(forResource: "happyBeamMenu", withExtension: "m4a")!)
    
    var isSharePlaying = false
    var isSpatial = false
    
    var isFinished = false {
        didSet {
            if isFinished == true {
                clear()
                gameplayPlayer.pause()
                
                victoryPlayer.numberOfLoops = -1
                victoryPlayer.volume = 0.6
                victoryPlayer.currentTime = 0
                victoryPlayer.play()
            }
        }
    }
    
    var isSoloReady = false {
        didSet {
            if isPlaying == true {
                victoryPlayer.pause()

                gameplayPlayer.volume = 0.6
                gameplayPlayer.currentTime = 0
                gameplayPlayer.play()
            }
        }
    }
    
    static let gameTime = 35
    var timeLeft = gameTime
    var isCountDownReady = false {
        didSet {
            if isCountDownReady == true {
                menuPlayer.setVolume(0, fadeDuration: Double(countDown))
            }
        }
    }
    
    var countDown = 3
    var score = 0
    var isMuted = false {
        didSet {
            if isMuted == true {
                gameplayPlayer.pause()
            } else {
                gameplayPlayer.play()
            }
        }
    }
    var isInputSelected = false
    var inputKind: InputKind = .hands
    
    var players = initialPlayers
    var balls: [Ball] = (0..<30).map { Ball(id: $0, isHappy: false) }
    var cloudSounds = [AudioFileResource]()
    
    var isUsingControllerInput = false
    var controllerX: Float = 0
    var controllerY: Float = 90.0
    var controllerInputX: Float = 0
    var controllerInputY: Float = 0
    var controllerLastInput = Date.timeIntervalSinceReferenceDate
    var controllerDismissTimer: Timer?

    /// Removes 3D content when then game is over.
    func clear() {
        spaceOrigin.children.removeAll()
    }
    
    /// Resets game state information.
    func reset() {
        isPlaying = false
        isPaused = false
        isSharePlaying = false
        isFinished = false
        isSoloReady = false
        timeLeft = GameModel.gameTime
        isCountDownReady = false
        countDown = 3
        score = 0
        level = 1
        isInputSelected = false
        inputKind = .hands
        players = initialPlayers
        
        #if targetEnvironment(simulator)
        Player.localName = players.first!.name
        #endif
        
        balls = (0..<30).map { Ball(id: $0, isHappy: false) }
        cloudNumber = 0
        hitCounts = [:]
        ballIsHit = [:]
        ballEntities = []
        isUsingControllerInput = false
        controllerX = 0
        controllerY = 90.0
        
        victoryPlayer.pause()
        gameplayPlayer.pause()
        
        clear()
    }

    func resetForNextLevel() {
        isPlaying = false
        isPaused = false
        isSoloReady = false
        timeLeft = GameModel.gameTime
        isCountDownReady = false
        countDown = 3
        players = initialPlayers

        #if targetEnvironment(simulator)
        Player.localName = players.first!.name
        #endif

        balls = (0..<30).map { Ball(id: $0, isHappy: false) }
        cloudNumber = 0
        hitCounts = [:]
        ballIsHit = [:]
        ballEntities = []
        isUsingControllerInput = false
        controllerX = 0
        controllerY = 90.0

        clear()
    }

    var level = 1 {
        didSet {
            BallSpawnParameters.updateSpeed(for: level)
        }
    }

    /// Preload assets when the app launches to avoid pop-in during the game.
    init() {
        Task { @MainActor in
            
            guard let beamAsset = await loadFromRealityComposerPro(
                named: BundleAssets.heartBlasterEntity,
                fromSceneNamed: BundleAssets.heartBlasterScene
            ) else {
                fatalError("Unable to load beam from Reality Composer Pro project.")
            }
            beam = beamAsset
            beam.name = BundleAssets.beamName
            
            // Position the beam relative to the user's hand.
            beam.position = .init(x: 0, y: 0, z: -0.3)
            beam.orientation = simd_quatf(
                Rotation3D(angle: .degrees(90), axis: .y)
                    .rotated(by: Rotation3D(angle: .degrees(-90), axis: .z))
                            .rotated(by: Rotation3D(angle: .degrees(-90), axis: .x))
            )
            
            floorBeam = beam.clone(recursive: true)
            floorBeam.name = "floorBeam"
            floorBeam.position.z += 0.3
            
            let fireworks = try await Entity(named: "fireworks")
            globalFireworks = fireworks.children.first!.children.first!
            
//            turret = await loadFromRealityComposerPro(named: BundleAssets.heartTurretEntity, fromSceneNamed: BundleAssets.heartTurretScene)
//            turret?.name = "Holder"
//            turret?.position = .init(x: 0, y: 0.25, z: -1.7)
//            turret?.scale *= 0.3
//
//            heart = await loadFromRealityComposerPro(named: BundleAssets.heartLightEntity, fromSceneNamed: BundleAssets.heartLightScene)
//            heart?.name = "Heart Projector"
//            heart?.generateCollisionShapes(recursive: true)
//            heart?.position = .init(x: 0, y: 0.25, z: -1.7)
//            heart?.position.y += 0.68
//            heart?.scale *= 0.22
//            heart?.components[InputTargetComponent.self] = InputTargetComponent(allowedInputTypes: .all)

            moneyGun = try? await Entity(named: BundleAssets.moneyGunAsset)
            moneyGun?.name = "MoneyGun"
            moneyGun?.position = .init(x: 0, y: 0.8, z: -1.7)
            moneyGun?.scale *= 0.05

            #if targetEnvironment(simulator)
            let moneyGunDraggable = true
            #else
            let moneyGunDraggable = inputKind == .alternative
            #endif
            if moneyGunDraggable {
                moneyGun?.generateCollisionShapes(recursive: true)
                moneyGun?.components[InputTargetComponent.self] = InputTargetComponent(allowedInputTypes: .all)
            }

            basketballBallTemplate = try? await Entity(named: BundleAssets.basketballBall)
            nflBallTemplate = try? await Entity(named: BundleAssets.nflBall)
            soccerBallTemplate = try? await Entity(named: BundleAssets.soccerBall)
            baseballBallTemplate = try? await Entity(named: BundleAssets.baseballBall)
            
            scaleTemplate(basketballBallTemplate, to: SIMD3<Float>(0.24, 0.24, 0.24))
            scaleTemplate(nflBallTemplate, to: SIMD3<Float>(0.56, 0.28, 0.28))
            scaleTemplate(soccerBallTemplate, to: SIMD3<Float>(0.22, 0.22, 0.22))
            scaleTemplate(baseballBallTemplate, to: SIMD3<Float>(0.074, 0.074, 0.074))

            guard moneyGun != nil, basketballBallTemplate != nil, nflBallTemplate != nil, soccerBallTemplate != nil, baseballBallTemplate != nil else {
                fatalError("Error loading assets.")
            }
            
            do {
                for number in 1...4 {
                    let resource = try await AudioFileResource(named: "cloudHit\(number).m4a")
                    cloudSounds.append(resource)
                }
            } catch {
                fatalError("Error loading cloud sound resources.")
            }
            
            // Generate animations inside the cloud models.
//            let def = cloudTemplate!.availableAnimations[0].definition
//            cloudAnimations[.sadBlink] = try .generate(with: AnimationView(source: def, trimStart: 1.0, trimEnd: 7.0))
//            cloudAnimations[.smile] = try .generate(with: AnimationView(source: def, trimStart: 7.5, trimEnd: 10.0))
//            cloudAnimations[.happyBlink] = try .generate(with: AnimationView(source: def, trimStart: 10.0, trimEnd: 15.0))

//            generateBallMovementAnimations()
            
            self.readyToStart = true
        }
    }
    
    func scaleTemplate(_ template: Entity?, to realSize: SIMD3<Float>) {
        guard let template = template else { return }
        
        template.generateCollisionShapes(recursive: true)
        let templateBounds = template.visualBounds(relativeTo: nil)
        let templateSize = templateBounds.extents

        let scaleCoefficient = SIMD3<Float>(
            realSize.x / templateSize.x,
            realSize.y / templateSize.y,
            realSize.z / templateSize.z
        )

        template.scale *= scaleCoefficient
    }

    func nextLevel() {
        if level < 5 {
            level += 1
        }
    }
}

/// The kinds of input selections offered to players.
enum InputKind {
    /// An input method that uses ARKit to detect a heart gesture.
    case hands
    
    /// An input method that spawns a stationary heart projector.
    case alternative
}
