//
//  PlacePickerAddress.swift
//  react-native-place-picker
//
//  Created by b0iq on 11/11/2022.
//
//  :p Copied from https://medium.com/geekculture/working-with-details-of-location-in-swiftui-faf7b139270b
//

import ExpoModulesCore
import CoreLocation.CLPlacemark

struct PlacePickerAddress: Record {
    init() {
        self.name = nil
        self.streetName = nil
        self.city = nil
        self.state = nil
        self.zipCode = nil
        self.country = nil
    }
    
    @Field
    var name: String? = ""
    @Field
    var streetName: String? = ""
    @Field
    var city: String? = ""
    @Field
    var state: String? = ""
    @Field
    var zipCode: String? = ""
    @Field
    var country: String? = ""
    init(with placemark: CLPlacemark?) {
        if let p = placemark {
            self.name           = p.name ?? ""
            self.streetName     = p.thoroughfare ?? ""
            self.city           = p.locality ?? ""
            self.state          = p.administrativeArea ?? ""
            self.zipCode        = p.postalCode ?? ""
            self.country        = p.country ?? ""
        } else {
            self.name = nil
            self.streetName = nil
            self.city = nil
            self.state = nil
            self.zipCode = nil
            self.country = nil
        }
    }
}
