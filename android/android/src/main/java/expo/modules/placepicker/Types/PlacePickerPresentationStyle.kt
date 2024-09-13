package expo.modules.placepicker

import expo.modules.kotlin.types.Enumerable


enum class PlacePickerPresentationStyle(val value: String) : Enumerable {
    modal("modal"),
    fullscreen("fullscreen")
}