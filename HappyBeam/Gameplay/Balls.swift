/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Declarations and parameters for clouds and their movement.
*/

import Accessibility
import Spatial
import RealityKit

/// A data source to sync cloud information among multiple players.
class Ball: Identifiable {
    var id: Int
    var isHappy: Bool
    
    init(id: Int, isHappy: Bool) {
        self.id = id
        self.isHappy = isHappy
    }
}

/// The main cloud model; it's cloned when a new cloud spawns.
var basketballBallTemplate: Entity? = nil
var nflBallTemplate: Entity? = nil
var soccerBallTemplate: Entity? = nil
var baseballBallTemplate: Entity? = nil


var cloudNumber = 0

/// Creates a cloud and places it in the space.
@MainActor
func spawnBall() async throws -> Entity {
    let start = Point3D(
        x: ballPaths[ballPathsIndex].0,
        y: ballPaths[ballPathsIndex].1,
        z: ballPaths[ballPathsIndex].2
    )
    
    let ball = try await spawnBallExact(
        start: start,
        end: .init(
            x: start.x + BallSpawnParameters.deltaX,
            y: start.y + BallSpawnParameters.deltaY,
            z: start.z + BallSpawnParameters.deltaZ
        ),
        speed: BallSpawnParameters.speed
    )

    // Needs to increment *after* spawnCloudExact()
    ballPathsIndex += 1
    ballPathsIndex %= ballPaths.count

    ballEntities.append(ball)
    return ball
}

/// Storage for each of the linear cloud movement animations.
var ballMovementAnimations: [AnimationResource] = []

/// Randomly selects a template for spawning.
func getRandomTemplate() -> Entity? {
    let templates = [basketballBallTemplate, nflBallTemplate, soccerBallTemplate, baseballBallTemplate]
    return templates.randomElement() ?? nil
}

func doesIntersect(newEntity: Entity, start: Point3D) -> Bool {
    return false

    let newEntityBounds = newEntity.visualBounds(relativeTo: nil)
    let newEntityMin = newEntityBounds.center - newEntityBounds.extents / 2
    let newEntityMax = newEntityBounds.center + newEntityBounds.extents / 2

    let newEntityMinPositioned = newEntityMin + SIMD3<Float>(Float(start.x), Float(start.y), Float(start.z))
    let newEntityMaxPositioned = newEntityMax + SIMD3<Float>(Float(start.x), Float(start.y), Float(start.z))

    for existingEntity in ballEntities {
        let existingEntityBounds = existingEntity.visualBounds(relativeTo: nil)
        let existingEntityMin = existingEntityBounds.center - existingEntityBounds.extents / 2
        let existingEntityMax = existingEntityBounds.center + existingEntityBounds.extents / 2

        let existingEntityMinPositioned = existingEntityMin + existingEntity.position
        let existingEntityMaxPositioned = existingEntityMax + existingEntity.position

        let intersects = (newEntityMinPositioned.x <= existingEntityMaxPositioned.x && newEntityMaxPositioned.x >= existingEntityMinPositioned.x) &&
                (newEntityMinPositioned.y <= existingEntityMaxPositioned.y && newEntityMaxPositioned.y >= existingEntityMinPositioned.y) &&
                (newEntityMinPositioned.z <= existingEntityMaxPositioned.z && newEntityMaxPositioned.z >= existingEntityMinPositioned.z)
        if intersects {
            return true
        }
    }
    return false
}

func getNewStartPosition() -> Point3D {
    let randomX = Double.random(in: -1.0...1.0)
    let randomY = Double.random(in: -1.0...1.0)
    let randomZ = Double.random(in: -1.0...1.0)
    return Point3D(x: randomX, y: randomY, z: randomZ)
}

/// Places a cloud in the scene and sets it on a set journey.
@MainActor
func spawnBallExact(start: Point3D, end: Point3D, speed: Double) async throws -> Entity {
    guard let selectedTemplate = getRandomTemplate() else {
        fatalError("No template selected.")
    }

    let ball = selectedTemplate.clone(recursive: true)
    ball.generateCollisionShapes(recursive: true)
    ball.name = "CCloud\(cloudNumber)"
    cloudNumber += 1

    ball.components[PhysicsBodyComponent.self] = PhysicsBodyComponent()

    ball.position = simd_float(start.vector + .init(x: 0, y: 0, z: -0.7))
    
    if doesIntersect(newEntity: ball, start: start) {
        print("Intersection detected. Skipping spawn.")
        return try await spawnBallExact(start: getNewStartPosition(), end: end, speed: speed)
    }
    
    var accessibilityComponent = AccessibilityComponent()
    accessibilityComponent.label = "Cloud"
    accessibilityComponent.value = "Grumpy"
    accessibilityComponent.isAccessibilityElement = true
    accessibilityComponent.traits = [.button, .playsSound]
    accessibilityComponent.systemActions = [.activate]
    ball.components[AccessibilityComponent.self] = accessibilityComponent

    let animation = ballMovementAnimations[ballPathsIndex]

    ball.playAnimation(animation, transitionDuration: speed, startsPaused: false)
    ball.setMaterialParameterValues(parameter: "saturation", value: .float(0.0))
    ball.setMaterialParameterValues(parameter: "animate_texture", value: .bool(false))

    spaceOrigin.addChild(ball)
    
    return ball
}


/// Describes the 3D scene relative to the player.
func postCloudOverviewAnnouncement(gameModel: GameModel) {
    guard !ballEntities.isEmpty else {
        return
    }
    var averageCameraPositionFront: SIMD3<Float> = [0, 0, 0]
    var averageCameraPositionBehind: SIMD3<Float> = [0, 0, 0]
    var cloudsFront = 0
    var cloudsBehind = 0
    for cloud in ballEntities {
        let cloudInstance = gameModel.balls.first(where: { cloudInstance in
            if ("CCloud" + String(cloudInstance.id)) == cloud.name {
                return true
            }
            return false
        })
        if cloudInstance?.isHappy ?? false {
            continue
        }
        let cloudPosition = cloud.position(relativeTo: cameraRelativeAnchor)
        if cloudPosition.z > 0 {
            averageCameraPositionBehind += cloudPosition
            cloudsBehind += 1
        } else {
            averageCameraPositionFront += cloudPosition
            cloudsFront += 1
        }
    }
    averageCameraPositionFront /= [Float(cloudsFront), Float(cloudsFront), Float(cloudsFront)]
    var cloudPositioningAnnouncementFront: String
    if averageCameraPositionFront.y > 0.5 {
        cloudPositioningAnnouncementFront = String(localized: "\(cloudsFront) clouds above and in front of you",
                                                   comment: "Describes the position of clouds in the 3D scene.")
    } else if averageCameraPositionFront.y < -0.5 {
        cloudPositioningAnnouncementFront = String(localized: "\(cloudsFront) clouds below and in front of you",
                                                   comment: "Describes the position of clouds in the 3D scene.")
    } else {
        cloudPositioningAnnouncementFront = String(localized: "\(cloudsFront) clouds in front of you",
                                                   comment: "Describes the position of clouds in the 3D scene.")
    }
    
    if averageCameraPositionFront.x > 0.5 {
        cloudPositioningAnnouncementFront = String(localized: "\(cloudPositioningAnnouncementFront) to the right",
                                                   comment: """
                                                            Describes the position of clouds in the 3D scene.
                                                            The first parameter is a string describing the position of the clouds.
                                                            """)
    } else if averageCameraPositionFront.x < -0.5 {
        cloudPositioningAnnouncementFront = String(localized: "\(cloudPositioningAnnouncementFront) to the left",
                                                   comment: """
                                                            Describes the position of clouds in the 3D scene.
                                                            The first parameter is a string describing the position of the clouds.
                                                            """)
    }
    
    averageCameraPositionBehind /= [Float(cloudsBehind), Float(cloudsBehind), Float(cloudsBehind)]
    var cloudPositioningAnnouncementBehind: String
    if averageCameraPositionBehind.y > 0.5 {
        cloudPositioningAnnouncementBehind = String(localized: "\(cloudsFront) clouds above and behind you",
                                                    comment: "Describes the position of clouds in the 3D scene.")
    } else if averageCameraPositionBehind.y < -0.5 {
        cloudPositioningAnnouncementBehind = String(localized: "\(cloudsFront) clouds below and behind you",
                                                    comment: "Describes the position of clouds in the 3D scene.")
    } else {
        cloudPositioningAnnouncementBehind = String(localized: "\(cloudsFront) clouds behind you",
                                                    comment: "Describes the position of clouds in the 3D scene.")
    }
    
    if averageCameraPositionBehind.x > 0.5 {
        cloudPositioningAnnouncementBehind = String(localized: "\(cloudPositioningAnnouncementBehind) to the right",
                                                    comment: """
                                                             Describes the position of clouds in the 3D scene.
                                                             The first parameter is a string describing the position of the clouds.
                                                             """)
    } else if averageCameraPositionBehind.x < -0.5 {
        cloudPositioningAnnouncementBehind = String(localized: "\(cloudPositioningAnnouncementBehind) to the left",
                                                    comment: """
                                                             Describes the position of clouds in the 3D scene.
                                                             The first parameter is a string describing the position of the clouds.
                                                             """)
    }

    var cloudPositioningAnnouncement = ""
    if cloudsFront > 0 && cloudsBehind == 0 {
        cloudPositioningAnnouncement = cloudPositioningAnnouncementFront
    } else if cloudsBehind > 0 && cloudsFront == 0 {
        cloudPositioningAnnouncement = cloudPositioningAnnouncementBehind
    } else {
        cloudPositioningAnnouncement = String(localized: "\(cloudPositioningAnnouncementFront) \(cloudPositioningAnnouncementBehind)",
                                              comment: """
                                                    Text describing the position of clouds on the screen. \
                                                    The first parameter is the clouds in front and the second parameter is the clouds behind the user.
                                                    """)
    }
    
    AccessibilityNotification.Announcement(cloudPositioningAnnouncement).post()
}

/// Cloud spawn parameters (in meters).
struct BallSpawnParameters {
    static var deltaX = 0.02
    static var deltaY = -0.12
    static var deltaZ = 12.0
    
    static var speed = 11.73
}

/// A counter that advances to the next cloud path.
var ballPathsIndex = 0

/// A hand-picked selection of random starting parameters for the motion of the clouds.
let ballPaths: [(Double, Double, Double)] = [
    (x: 1.757_231_498_429_01, y: 1.911_673_694_896_59, z: -8.094_368_331_589_704),
    (x: -0.179_269_237_592_594_17, y: 1.549_268_306_906_908_4, z: -7.254_713_426_424_875),
    (x: -0.013_296_800_013_828_491, y: 2.147_766_026_068_617_8, z: -8.601_541_438_900_849),
    (x: 2.228_704_746_539_703, y: 0.963_797_733_336_365_2, z: -7.183_621_312_117_454),
    (x: -0.163_925_123_812_864_4, y: 1.821_619_897_406_197, z: -8.010_893_563_433_282),
    (x: 0.261_716_575_589_896_03, y: 1.371_932_443_334_715, z: -7.680_206_361_333_17),
    (x: 1.385_410_631_256_254_6, y: 1.797_698_998_556_775_5, z: -7.383_548_882_448_866),
    (x: -0.462_798_470_454_367_4, y: 1.431_650_092_907_264_4, z: -7.169_154_476_151_876),
    (x: 1.112_766_805_791_563, y: 0.859_548_406_627_492_2, z: -7.147_229_496_720_969),
    (x: 1.210_194_536_657_374, y: 0.880_254_638_358_228_8, z: -8.051_132_737_691_349),
    (x: 0.063_637_772_899_141_52, y: 1.973_172_635_040_014_7, z: -8.503_837_407_474_947),
    (x: 0.883_082_630_134_997_2, y: 1.255_268_496_843_653_4, z: -7.760_994_300_660_705),
    (x: 0.891_719_821_716_725_7, y: 2.085_000_111_104_786_7, z: -8.908_048_018_555_112),
    (x: 0.422_260_067_132_894_2, y: 1.370_335_319_771_187, z: -7.525_853_388_894_509),
    (x: 0.473_470_811_107_753_46, y: 1.864_930_149_962_240_6, z: -8.164_641_191_459_626)
]
