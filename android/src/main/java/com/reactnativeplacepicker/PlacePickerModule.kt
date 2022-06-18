package com.reactnativeplacepicker

import com.facebook.react.bridge.*

class PlacePickerModule(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {

    override fun getName(): String {
        return "PlacePicker"
    }

    // Example method
    // See https://reactnative.dev/docs/native-modules-android
    @ReactMethod
    fun pickPlaceWithOptions(options: ReadableMap, promise: Promise) {

      promise.resolve("a * b")

    }


}
