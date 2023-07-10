package com.placepicker

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableMap

abstract class PlacePickerSpec internal constructor(context: ReactApplicationContext) :
  NativePlacePickerSpec(context) {
  abstract fun pickPlace(options: ReadableMap, promise: Promise)
}
