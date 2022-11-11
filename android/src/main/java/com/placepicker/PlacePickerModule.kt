package com.placepicker
import android.app.Activity
import android.content.Intent
import android.widget.Toast
import com.facebook.react.bridge.*

const val MAP_TITLE = "com.placepicker.MAP_TITLE"
const val MAP_LATITUDE = "com.placepicker.MAP_LATITUDE"
const val MAP_LONGITUDE = "com.placepicker.MAP_LONGITUDE"


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
            val data = intent?.getSerializableExtra("returnMap") as? HashMap<String, Any>
            when (resultCode) {
              Activity.RESULT_CANCELED -> {
                data?.set("canceled", true)
              }
              Activity.RESULT_OK -> {
                data?.set("canceled", false)
              }
            }
            // because I hate Android programming...
            val toJSmap = Arguments.createMap().apply {
              if (data?.get("latitude") != null) {
                putDouble("latitude", data["latitude"] as Double)
              } else {
                putDouble("latitude", 0.0)
              }
              if (data?.get("longitude") != null) {
                putDouble("longitude", data["longitude"] as Double)
              } else {
                putDouble("longitude", 0.0)
              }
              if (data?.get("canceled") != null) {
                putBoolean("canceled", data["canceled"] as Boolean)
              } else {
                putBoolean("canceled", true)
              }
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
    return NAME
  }

  @ReactMethod
  fun pickPlace(promise: Promise) {
    val activity = currentActivity

    if (activity == null) {
      promise.reject(E_ACTIVITY_DOES_NOT_EXIST, "Activity doesn't exist")
      return
    }

    pickerPromise = promise

    try {
      val pickerIntent = Intent(reactApplicationContext, MapViewController::class.java).apply {
        putExtra(
          MAP_TITLE, "Pick a Place"
        )
      }
      activity.startActivityForResult(pickerIntent, PLACE_PICKER_REQUEST)
    } catch (t: Throwable) {
      pickerPromise?.reject(E_FAILED_TO_SHOW_PICKER, t)
      pickerPromise = null
    }

  }

  @ReactMethod
  fun pickPlaceWithOptions(options: ReadableMap, promise: Promise) {
    val coords = options.getMap("initialCoordinates")?: run {
      promise.reject("PARSER_ERROR", "Unable to parse initialCoordinates")
      return
    }
    val title = options.getString("title")?: run {
      promise.reject("PARSER_ERROR", "Unable to parse title")
      return
    }
    val latitude = coords.getDouble("latitude")
    val longitude = coords.getDouble("longitude")
    val activity = currentActivity

    if (activity == null) {
      promise.reject(E_ACTIVITY_DOES_NOT_EXIST, "Activity doesn't exist")
      return
    }

    pickerPromise = promise

    try {
      val pickerIntent = Intent(reactApplicationContext, MapViewController::class.java).apply {
        putExtra(
          MAP_TITLE, title
        )
        putExtra(MAP_LATITUDE, latitude)
        putExtra(MAP_LONGITUDE, longitude)
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
    const val E_FAILED_TO_SHOW_PICKER = "E_FAILED_TO_SHOW_PICKER"
    const val NAME = "PlacePicker"
  }


}
