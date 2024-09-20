package expo.modules.placepicker

import expo.modules.kotlin.Promise

class PlacePickerState {
    companion object {
        var globalPromise: Promise? = null
        var globalOptions: PlacePickerOptions = PlacePickerOptions()
        var globalResult: PlacePickerResult = PlacePickerResult()
    }
}