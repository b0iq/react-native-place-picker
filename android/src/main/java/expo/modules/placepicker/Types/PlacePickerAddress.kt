package expo.modules.placepicker

import expo.modules.kotlin.records.Field
import expo.modules.kotlin.records.Record

class PlacePickerAddress : Record {
    @Field
    var name: String = ""

    @Field
    var streetName: String = ""

    @Field
    var city: String = ""

    @Field
    var state: String = ""

    @Field
    var zipCode: String = ""

    @Field
    var country: String = ""
}
