package expo.modules.placepicker

import expo.modules.kotlin.records.Field
import expo.modules.kotlin.records.Record

class PlacePickerResult : Record {
    @Field
    var coordinate: PlacePickerCoordinate? = null

    @Field
    var address: PlacePickerAddress? = null

    @Field
    var didCancel: Boolean? = null
}
