package expo.modules.placepicker

import expo.modules.kotlin.records.Field
import expo.modules.kotlin.records.Record

class PlacePickerCoordinate : Record {
    @Field
    var latitude: Double = 0.0

    @Field
    var longitude: Double = 0.0
}
