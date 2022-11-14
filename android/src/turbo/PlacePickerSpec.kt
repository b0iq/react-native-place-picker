package com.placepicker
import com.facebook.react.bridge.ReactApplicationContext

abstract class PlacePickerSpec internal constructor(context: ReactApplicationContext) :
  NativePlacePickerSpec(context) {
    abstract fun pickPlace(options: ReadableMap, promise: Promise)
}
