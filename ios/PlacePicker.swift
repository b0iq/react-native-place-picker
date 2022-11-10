import CoreLocation
@objc(PlacePicker)
class PlacePicker: NSObject {
    
    private func StartPickingLocation(_ resolver: @escaping RCTPromiseResolveBlock, options: PlacePickerOptions = PlacePickerOptions()) {
        DispatchQueue.main.async {
            let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            if var topController = keyWindow?.rootViewController {
                while let presentedViewController = topController.presentedViewController {
                    topController = presentedViewController
                }
                let mapViewController = MapViewController(resolver, options)
                let wrapperViewController = UINavigationController(rootViewController: mapViewController)
                wrapperViewController.modalPresentationStyle = .fullScreen
                topController.present(wrapperViewController, animated: true)
            }
        }
    }
    
    @objc
    func pickPlaceWithOptions(_ options: NSDictionary, withResolver resolve: @escaping RCTPromiseResolveBlock, withRejector reject: RCTPromiseRejectBlock) {
        StartPickingLocation(resolve)
    }
    @objc
    func pickPlace(_ resolve: @escaping RCTPromiseResolveBlock, withRejector reject: RCTPromiseRejectBlock) {
        StartPickingLocation(resolve)
    }
    
}
