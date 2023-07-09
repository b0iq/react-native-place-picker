package com.placepicker

import com.facebook.react.bridge.ReactApplicationContext

abstract class PlacePickerSpec internal constructor(context: ReactApplicationContext) :
  NativePlacePickerSpec(context) {
    // ...
    private val isNull = false
}
