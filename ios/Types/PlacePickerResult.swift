//
//  PlacePickerResult.swift
//  react-native-place-picker
//
//  Created by b0iq on 11/11/2022.
//

import Foundation

struct PlacePickerResult: Codable {
    let coordinate: PlacePickerCoordinate
    let address: PlacePickerAddress?
    let didCancel: Bool
}
