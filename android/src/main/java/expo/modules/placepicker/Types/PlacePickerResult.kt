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

    @Field
    var radius: Double? = null

    @Field
    var radiusCoordinates: RadiusCoordinates? = null
}

class BoundsCoordinates : Record {
    @Field
    var northeast: PlacePickerCoordinate? = null
    @Field
    var southwest: PlacePickerCoordinate? = null
}

class RadiusCoordinates : Record {
    @Field
    var center: PlacePickerCoordinate? = null
    @Field
    var bounds: BoundsCoordinates? = null
}
