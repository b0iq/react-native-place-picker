import CoreLocation
@objc(PlacePicker)
class PlacePicker: NSObject {
    
    private func start(
        _ resolver: @escaping RCTPromiseResolveBlock,
        _ rejector: @escaping RCTPromiseRejectBlock,
        options: PlacePickerOptions = PlacePickerOptions()) {
        DispatchQueue.main.async {
            let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            if var topController = keyWindow?.rootViewController {
                while let presentedViewController = topController.presentedViewController {
                    topController = presentedViewController
                }
                let placePickerViewController = UINavigationController(rootViewController: PlacePickerViewController(resolver, rejector, options))
                if options.presentationStyle == .fullscreen {
                    placePickerViewController.modalPresentationStyle = .fullScreen
                }
                topController.present(placePickerViewController, animated: true)
            }
        }
    }
    
    @objc
    func pickPlace(_ options: NSDictionary, withResolver resolve: @escaping RCTPromiseResolveBlock, withRejector reject: @escaping RCTPromiseRejectBlock) {
        do {
            let opts: PlacePickerOptions = try options.asClass()
            start(resolve, reject, options: opts)
        } catch {
            reject("parsing", "Cannot parse options", NSError(domain: "pickPlaceWithOptions", code: 10))
        }
    }
    
}
