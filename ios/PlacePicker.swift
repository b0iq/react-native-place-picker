import CoreLocation
@objc(PlacePicker)
class PlacePicker: NSObject {
    
    func StartPickingLocation(_ resolve: @escaping RCTPromiseResolveBlock,_ reject: RCTPromiseRejectBlock, _ title: String? = nil,_ coordinates: CLLocationCoordinate2D? = nil) {
        DispatchQueue.main.async {
            let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            if var topController = keyWindow?.rootViewController {
                while let presentedViewController = topController.presentedViewController {
                    topController = presentedViewController
                }
                let mapViewController = MapViewController(titleText: title, coordinates: coordinates, resolver: resolve)
                let wrapperViewController = UINavigationController(rootViewController: mapViewController)
                topController.present(wrapperViewController, animated: true)
            }
        }
    }
    
    @objc
    func pickPlaceWithOptions(_ options: NSDictionary, withResolver resolve: @escaping RCTPromiseResolveBlock, withRejector reject: RCTPromiseRejectBlock) {
        guard let initialCoordinates = options["initialCoordinates"] as? NSDictionary else {
            reject(nil, "Error while parsing coordinates - 1", nil)
            return
        }
        guard let title = options["title"] as? String else {
            reject(nil, "Title must be provided", nil)
            return
        }
        guard let latitude = initialCoordinates["latitude"] as? Double else {
            reject(nil, "Error while parsing coordinates - 3", nil)
            return
        }
        guard let longitude = initialCoordinates["longitude"] as? Double else {
            reject(nil, "Error while parsing coordinates - 4", nil)
            return
        }
        let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        StartPickingLocation(resolve, reject, title, coordinates)
    }
    @objc
    func pickPlace(_ resolve: @escaping RCTPromiseResolveBlock, withRejector reject: RCTPromiseRejectBlock) {
        StartPickingLocation(resolve, reject)
    }
    
}
