import Flutter
import UIKit

public class SoundpoolPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        SwiftSoundpoolPlugin.register(with: registrar)
    }
}
