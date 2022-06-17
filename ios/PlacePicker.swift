import UIKit

@objc(PlacePicker)
class PlacePicker: NSObject {
    
    @objc
    func constantsToExport() -> [AnyHashable : Any]! {
      return ["projectName": "ModuleName"]
    }

    @objc
    static func requiresMainQueueSetup() -> Bool {
      return true
    }
    @objc
      func functionWithPromise(
        _ resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
      ) -> Void {
        if (1 != 2) {
          let error = NSError(domain: "", code: 200, userInfo: nil)
          reject("ERROR_FOUND", "failure", error)
        } else {
          resolve("success")
        }
      }
    @objc
    func multiply(a: Float, b: Float, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) -> Void {
        resolve(a*b)
    }
    @objc
    func sqrt(a: Int, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) -> Void {
            let results = a * a
            resolve(results)
    }
}
