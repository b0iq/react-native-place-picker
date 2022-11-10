//
//  Options.swift
//  react-native-place-picker
//
//  Created by b0iq on 10/11/2022.
//

import Foundation

struct PlacePickerOptions: Codable {
    var title: String = "Choose Place"
    var searchPlaceholder: String = "Search..."
    var color: String = "#FF0000"
    var contrast: String = "#FFFFFF"
    var locale: String = "en-US"
    var initialCoordinates: PlacePickerCoordinate = PlacePickerCoordinate(latitude: 25.2048, longitude: 55.2708)
    var enableGeocoding = true
    var enableSearch = true
    var enableUserlocation = true
    var enableLargeTitle = true
}
