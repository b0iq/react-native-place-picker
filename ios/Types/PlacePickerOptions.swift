//
//  Options.swift
//  react-native-place-picker
//
//  Created by b0iq on 10/11/2022.
//

import Foundation


class PlacePickerOptions: Codable {
    var presentationStyle: PlacePickerPresentationStyle
    var title: String
    var searchPlaceholder: String
    var color: String
    var contrastColor: String
    var locale: String
    var initialCoordinates: PlacePickerCoordinate
    var enableGeocoding: Bool
    var enableSearch: Bool
    var enableUserLocation: Bool
    var enableLargeTitle: Bool
    var rejectOnCancel: Bool
    
    enum CodingKeys: String, CodingKey {
        case presentationStyle = "presentationStyle"
        case title = "title"
        case searchPlaceholder = "searchPlaceholder"
        case color = "color"
        case contrastColor = "contrastColor"
        case locale = "locale"
        case initialCoordinates = "initialCoordinates"
        case enableGeocoding = "enableGeocoding"
        case enableSearch = "enableSearch"
        case enableUserLocation = "enableUserLocation"
        case enableLargeTitle = "enableLargeTitle"
        case rejectOnCancel = "rejectOnCancel"
    }
    init() {
        self.presentationStyle = PlacePickerPresentationStyle.fullscreen
        self.title = "Choose Place"
        self.searchPlaceholder = "Search..."
        self.color = "FF0000"
        self.contrastColor = "FFFFFF"
        self.locale = "en-US"
        self.initialCoordinates = PlacePickerCoordinate(latitude: 25.2048, longitude: 55.2708)
        self.enableGeocoding = true
        self.enableSearch = true
        self.enableUserLocation = true
        self.enableLargeTitle = true
        self.rejectOnCancel = true
        
    }
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let initialCoords = PlacePickerCoordinate(latitude: 25.2048, longitude: 55.2708)
        self.presentationStyle = try container.decodeIfPresent(PlacePickerPresentationStyle.self, forKey: .presentationStyle) ??  .fullscreen
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ??  "Choose Place"
        self.searchPlaceholder = try container.decodeIfPresent(String.self, forKey: .searchPlaceholder) ??  "Search..."
        self.color = try container.decodeIfPresent(String.self, forKey: .color) ??  "#FF0000"
        self.contrastColor = try container.decodeIfPresent(String.self, forKey: .contrastColor) ??  "#FFFFFF"
        self.locale = try container.decodeIfPresent(String.self, forKey: .locale) ??  "en-US"
        self.initialCoordinates = try container.decodeIfPresent(PlacePickerCoordinate.self, forKey: .initialCoordinates) ?? initialCoords
        self.enableGeocoding = try container.decodeIfPresent(Bool.self, forKey: .enableGeocoding) ??  true
        self.enableSearch = try container.decodeIfPresent(Bool.self, forKey: .enableSearch) ??  true
        self.enableUserLocation = try container.decodeIfPresent(Bool.self, forKey: .enableUserLocation) ??  true
        self.enableLargeTitle = try container.decodeIfPresent(Bool.self, forKey: .enableLargeTitle) ??  true
        self.rejectOnCancel = try container.decodeIfPresent(Bool.self, forKey: .rejectOnCancel) ??  true
    }
}
