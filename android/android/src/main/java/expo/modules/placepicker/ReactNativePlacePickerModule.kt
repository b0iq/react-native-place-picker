package expo.modules.placepicker

import android.content.Intent
import android.util.Log
import expo.modules.kotlin.Promise
import expo.modules.kotlin.functions.Queues
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition

const val TAG = "XX_PLACE_PCIKER"
fun lg(string: String?) {
    Log.i(TAG, string ?: "Unknown")
}

class ReactNativePlacePickerModule : Module() {
    override fun definition() = ModuleDefinition {
        Name(NAME)
        AsyncFunction("pickPlace") { options: PlacePickerOptions?, promise: Promise ->
            try {
                if (options != null) {
                    PlacePickerState.globalOptions = options
                }
                PlacePickerState.globalPromise = promise
                PlacePickerState.globalResult = PlacePickerResult()
                val activity = this@ReactNativePlacePickerModule.appContext.currentActivity
                val pickerIntent = Intent(activity, PlacePickerActivity::class.java)
                activity?.startActivityForResult(pickerIntent, PLACE_PICKER_REQUEST)
            } catch (t: Throwable) {
                promise.reject(E_FAILED_TO_SHOW_PICKER, "Unable to launch new activity", t)
                PlacePickerState.globalPromise = null
            }
        }.runOnQueue(Queues.MAIN)
    }

    companion object {
        const val PLACE_PICKER_REQUEST = 1
        const val E_ACTIVITY_DOES_NOT_EXIST = "E_ACTIVITY_DOES_NOT_EXIST"
        const val E_FAILED_TO_SHOW_PICKER = "E_FAILED_TO_SHOW_PICKER"
        const val NAME = "ReactNativePlacePicker"
    }
}
