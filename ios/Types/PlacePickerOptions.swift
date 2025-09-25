//
//  Options.swift
//  react-native-place-picker
//
//  Created by b0iq on 10/11/2022.
//

import ExpoModulesCore

struct PlacePickerOptions: Record {
    @Field
    var presentationStyle: PlacePickerPresentationStyle = .fullscreen
    @Field
    var title: String = "Choose Place"
    @Field
    var searchPlaceholder: String = "Search..."
    @Field
    var color: String = "FF0000"
    @Field
    var contrastColor: String = "FFFFFF"
    @Field
    var locale: String = "en-US"
    @Field
    var initialCoordinates: PlacePickerCoordinate = PlacePickerCoordinate(latitude: .init(wrappedValue: 25.2048), longitude: .init(wrappedValue: 55.2708))
    @Field
    var enableGeocoding: Bool = true
    @Field
    var enableSearch: Bool = true
    @Field
    var enableUserLocation: Bool = true
    @Field
    var enableLargeTitle: Bool = true
    @Field
    var rejectOnCancel: Bool = true
    @Field
    var enableRangeSelection: Bool = false
    @Field
    var initialRadius: Double = 1000
    @Field
    var minRadius: Double = 100
    @Field
    var maxRadius: Double = 10000
    @Field
    var radiusColor: String = ""
    @Field
    var radiusStrokeColor: String = ""
    @Field
    var radiusStrokeWidth: Double = 2
}
