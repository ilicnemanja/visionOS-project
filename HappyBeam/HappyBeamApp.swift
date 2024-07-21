/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app structure.
*/

import SwiftUI
import RealityKit
import FirebaseCore


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

/// The structure of the Happy Beam app: a main window and a Full Space for gameplay.
@main
struct HappyBeamApp: App {
    @State private var gameModel = GameModel()
    @State private var immersionState: ImmersionStyle = .mixed
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some SwiftUI.Scene {
        WindowGroup("HappyBeam", id: "happyBeamApp") {
            HappyBeam()
                .environment(gameModel)
                .onAppear {
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                        return
                    }
                        
                    windowScene.requestGeometryUpdate(.Vision(resizingRestrictions: UIWindowScene.ResizingRestrictions.none))
                }
        }
        .windowStyle(.plain)
        
        ImmersiveSpace(id: "happyBeam") {
            HappyBeamSpace(gestureModel: HeartGestureModelContainer.heartGestureModel)
                .environment(gameModel)
        }
        .immersionStyle(selection: $immersionState, in: .mixed)
    }
}

@MainActor
enum HeartGestureModelContainer {
    private(set) static var heartGestureModel = HeartGestureModel()
}
