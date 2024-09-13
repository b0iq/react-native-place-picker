import ExpoModulesCore

public class ReactNativePlacePickerModule: Module {
    
    public func definition() -> ModuleDefinition {
        
        Name("ReactNativePlacePicker")

        AsyncFunction("pickPlace") { (options: PlacePickerOptions?, promise: Promise) in
            let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            if var topController = keyWindow?.rootViewController {
                while let presentedViewController = topController.presentedViewController {
                    topController = presentedViewController
                }
                let placePickerViewController = UINavigationController(rootViewController: PlacePickerViewController(options ?? PlacePickerOptions(), promise))
                if options?.presentationStyle == .fullscreen {
                    placePickerViewController.modalPresentationStyle = .fullScreen
                }
                topController.present(placePickerViewController, animated: true)
            }
        }.runOnQueue(.main)
    }
}
