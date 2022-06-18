package com.reactnativeplacepicker

import android.app.Activity
import android.content.Intent
import android.content.Intent.getIntent
import com.facebook.react.bridge.*


const val EXTRA_MESSAGE = "com.reactnativeplacepicker.MESSAGE"

class PlacePickerModule(reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext) {

  private var pickerPromise: Promise? = null

  private val activityEventListener =
    object : BaseActivityEventListener() {
      override fun onActivityResult(
        activity: Activity?,
        requestCode: Int,
        resultCode: Int,
        intent: Intent?
      ) {
        if (requestCode == PLACE_PICKER_REQUEST) {
          pickerPromise?.let { promise ->
            val data = intent?.getSerializableExtra("returnMap") as HashMap<String, Any>
            when (resultCode) {
              Activity.RESULT_CANCELED -> {
                data["canceled"] = true
              }
              Activity.RESULT_OK -> {
                data["canceled"] = false
              }
            }
            // because I hate Android programming...
            val toJSmap = Arguments.createMap().apply {
              putDouble("latitude", data["latitude"] as Double)
              putDouble("longitude", data["longitude"] as Double)
              putBoolean("canceled", data["canceled"] as Boolean)
            }
            promise.resolve(toJSmap)
            pickerPromise = null
          }
        }
      }
    }

  init {
    reactContext.addActivityEventListener(activityEventListener)
  }

  override fun getName(): String {
    return "PlacePicker"
  }

  // Example method
  // See https://reactnative.dev/docs/native-modules-android
  @ReactMethod
  fun pickPlaceWithOptions(options: ReadableMap, promise: Promise) {
    val activity = currentActivity

    if (activity == null) {
      promise.reject(E_ACTIVITY_DOES_NOT_EXIST, "Activity doesn't exist")
      return
    }

    pickerPromise = promise

    try {
      val pickerIntent = Intent(reactApplicationContext, MapViewController::class.java).apply {
        putExtra(
          EXTRA_MESSAGE, "Hi"
        )
      }
      activity.startActivityForResult(pickerIntent, PLACE_PICKER_REQUEST)
    } catch (t: Throwable) {
      pickerPromise?.reject(E_FAILED_TO_SHOW_PICKER, t)
      pickerPromise = null
    }
  }

  companion object {
    const val PLACE_PICKER_REQUEST = 1
    const val E_ACTIVITY_DOES_NOT_EXIST = "E_ACTIVITY_DOES_NOT_EXIST"
    const val E_PICKER_CANCELLED = "E_PICKER_CANCELLED"
    const val E_FAILED_TO_SHOW_PICKER = "E_FAILED_TO_SHOW_PICKER"
    const val E_NO_IMAGE_DATA_FOUND = "E_NO_IMAGE_DATA_FOUND"
  }


}
