//
//  Options.swift
//  react-native-place-picker
//
//  Created by b0iq on 10/11/2022.
//

import Foundation

struct PlacePickerOptions: Codable {
    struct Coordinate: Codable, Hashable {
        let latitude, longitude: Double
    }
    var title: String = "Choose Place"
    var searchPlaceholder: String = "Search..."
    var color: String = "#FFF000"
    var contrast: String = "#FFFFFF"
    var locale: String = "en-US"
    var initialCoordinates: Coordinate = Coordinate(latitude: 0.00, longitude: 0.00)
    var returnAddress = true
    var searchable = true
}
