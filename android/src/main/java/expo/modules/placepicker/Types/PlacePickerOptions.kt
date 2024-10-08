package expo.modules.placepicker

import expo.modules.kotlin.records.Field
import expo.modules.kotlin.records.Record

class PlacePickerOptions : Record {
    @Field
    val presentationStyle: PlacePickerPresentationStyle = PlacePickerPresentationStyle.fullscreen

    @Field
    val title: String = "Choose Place"

    @Field
    val searchPlaceholder: String = "Search..."

    @Field
    val color: String = "#FF0000"

    @Field
    val contrastColor: String = "#FFFFFF"

    @Field
    val locale: String = "en-US"

    @Field
    val initialCoordinates: PlacePickerCoordinate? = null

    @Field
    val enableGeocoding: Boolean = true

    @Field
    val enableSearch: Boolean = true

    @Field
    val enableUserLocation: Boolean = true

    @Field
    val enableLargeTitle: Boolean = true

    @Field
    val rejectOnCancel: Boolean = true
}
