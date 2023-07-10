package com.placepicker
import android.app.Activity
import android.app.ActivityOptions
import android.content.Intent
import com.facebook.jni.HybridData
import com.facebook.react.bridge.*
import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.module.kotlin.convertValue
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.Promise

class PlacePickerModule(reactContext: ReactApplicationContext) :
  PlacePickerSpec(reactContext) {

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
            when (resultCode) {
              Activity.RESULT_CANCELED -> {
                PlacePickerState.result.didCancel = true
              }
              Activity.RESULT_OK -> {
                PlacePickerState.result.didCancel = false
              }
            }

            if (PlacePickerState.result.didCancel && PlacePickerState.options?.rejectOnCancel == true) {
              promise.reject("cancel", "user did cancel the operation")
            } else {
              val mapper = ObjectMapper()
              val map = mapper.convertValue(PlacePickerState.result, Map::class.java) as Map<String, Any>
              val result = Arguments.makeNativeMap(map)
              promise.resolve(result)
            }
            pickerPromise = null
          }
        }
      }
    }

  init {
    reactContext.addActivityEventListener(activityEventListener)
  }

  override fun getName(): String {
    return NAME
  }

  private fun start(promise: Promise, rawOptions: ReadableMap? = null) {
    pickerPromise = promise
    val optionsHashMap = if (rawOptions != null)  rawOptions.toHashMap() else hashMapOf<String, Any>()
    val activity = currentActivity

    if (activity == null) {
      promise.reject(E_ACTIVITY_DOES_NOT_EXIST, "Activity doesn't exist")
      return
    }

    try {
      val pickerIntent = Intent(reactApplicationContext, PlacePickerActivity::class.java).apply {
        putExtra(
          PICK_OPTIONS, optionsHashMap
        )
      }
      activity.startActivityForResult(pickerIntent, PLACE_PICKER_REQUEST, ActivityOptions.makeSceneTransitionAnimation(activity).toBundle())
    } catch (t: Throwable) {
      pickerPromise?.reject(E_FAILED_TO_SHOW_PICKER, t)
      pickerPromise = null
    }

  }

  @ReactMethod
  override fun pickPlace(options: ReadableMap, promise: Promise) { start(promise, options) }
  companion object {
    const val PLACE_PICKER_REQUEST = 1
    const val E_ACTIVITY_DOES_NOT_EXIST = "E_ACTIVITY_DOES_NOT_EXIST"
    const val E_FAILED_TO_SHOW_PICKER = "E_FAILED_TO_SHOW_PICKER"
    const val NAME = "PlacePicker"
  }
}
