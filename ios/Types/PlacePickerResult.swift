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
}
