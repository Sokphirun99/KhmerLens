import Flutter
import UIKit
import SwiftyTesseract

public class SwiftFlutterTesseractOcrPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_tesseract_ocr", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterTesseractOcrPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        initializeTessData()
        if call.method == "extractText" {
            
            guard let args = call.arguments else {
                result("iOS could not recognize flutter arguments in method: (sendParams)")
                return
            }
            
            let params: [String : Any] = args as! [String : Any]
            let language: String? = params["language"] as? String
            var swiftyTesseract = SwiftyTesseract(language: .english)
            if let language {
                swiftyTesseract = SwiftyTesseract(language: .custom(language))
            }
            let  imagePath = params["imagePath"] as! String
            guard let image = UIImage(contentsOfFile: imagePath)else { return }
            
            swiftyTesseract.performOCR(on: image) { recognizedString in
                
                guard let extractText = recognizedString else { return }
                result(extractText)
            }
        }
    }
    
    func initializeTessData() {
        let fileManager = FileManager.default
        
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("FlutterTesseractOcr: Could not find documents directory")
            return
        }
        
        let destTessDataDir = documentsURL.appendingPathComponent("tessdata")
        let bundleTessDataDir = Bundle.main.bundleURL.appendingPathComponent("tessdata")
        
        // Create tessdata directory in Documents if it doesn't exist
        if !fileManager.fileExists(atPath: destTessDataDir.path) {
            do {
                try fileManager.createDirectory(at: destTessDataDir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("FlutterTesseractOcr: Failed to create tessdata directory: \(error)")
                return
            }
        }
        
        // Copy traineddata files from bundle to Documents/tessdata
        if fileManager.fileExists(atPath: bundleTessDataDir.path) {
            do {
                let contents = try fileManager.contentsOfDirectory(at: bundleTessDataDir, includingPropertiesForKeys: nil)
                for fileURL in contents {
                    if fileURL.pathExtension == "traineddata" {
                        let destFile = destTessDataDir.appendingPathComponent(fileURL.lastPathComponent)
                        if !fileManager.fileExists(atPath: destFile.path) {
                            try fileManager.copyItem(at: fileURL, to: destFile)
                            print("FlutterTesseractOcr: Copied \(fileURL.lastPathComponent) to Documents/tessdata")
                        }
                    }
                }
            } catch {
                print("FlutterTesseractOcr: Error copying tessdata files: \(error)")
            }
        }
    }
}
