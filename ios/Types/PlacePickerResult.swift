//
//  PlacePickerResult.swift
//  react-native-place-picker
//
//  Created by b0iq on 11/11/2022.
//

import ExpoModulesCore

struct PlacePickerResult: Record {
    @Field
    var coordinate: PlacePickerCoordinate
    @Field
    var address: PlacePickerAddress?
    @Field
    var didCancel: Bool
    @Field
    var radius: Double?
    @Field
    var radiusCoordinates: RadiusCoordinates?
}

struct BoundsCoordinates: Record {
    @Field
    var northeast: PlacePickerCoordinate
    @Field
    var southwest: PlacePickerCoordinate
}

struct RadiusCoordinates: Record {
    @Field
    var center: PlacePickerCoordinate
    @Field
    var bounds: BoundsCoordinates
}
