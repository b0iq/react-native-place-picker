package com.reactnativeplacepicker

import android.app.Activity
import android.content.Intent
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.view.Menu
import android.view.MenuInflater
import android.view.MenuItem
import androidx.core.view.WindowCompat
import com.facebook.react.bridge.Arguments

class MapViewController : AppCompatActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    WindowCompat.setDecorFitsSystemWindows(window, false)
    setContentView(R.layout.activity_map_view_controller)
    val message = intent.getStringExtra(EXTRA_MESSAGE)
    setTitle(message)
  }

  override fun onCreateOptionsMenu(menu: Menu?): Boolean {
    val inflater: MenuInflater = menuInflater
    inflater.inflate(R.menu.barbuttonitems, menu)
    return true
  }

  override fun onOptionsItemSelected(item: MenuItem): Boolean {
    val returnIntent = Intent();
    val returnMap = Arguments.createMap().apply {
      putDouble("latitude", 25.23092)
      putDouble("longitude", 55.23092)
    }
    val map = returnMap.toHashMap()
    returnIntent.putExtra("returnMap", map);
    setResult(if (item.itemId == R.id.action_close) Activity.RESULT_CANCELED else Activity.RESULT_OK, returnIntent)
    finish()
    return true
  }
}
