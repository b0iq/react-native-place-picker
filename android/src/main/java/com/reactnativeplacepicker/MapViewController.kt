package com.reactnativeplacepicker

import android.animation.ObjectAnimator
import android.app.Activity
import android.content.Intent
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.view.Menu
import android.view.MenuInflater
import android.view.MenuItem
import android.view.View
import androidx.core.view.WindowCompat
import com.facebook.react.bridge.Arguments
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.OnMapReadyCallback
import com.google.android.gms.maps.SupportMapFragment
import com.google.android.gms.maps.model.LatLng
import java.util.*

class MapViewController : AppCompatActivity(), OnMapReadyCallback,
  GoogleMap.OnCameraMoveStartedListener, GoogleMap.OnCameraIdleListener {

  private lateinit var pinView: View
  private lateinit var mMap: GoogleMap
  private lateinit var pinViewAnimation: ObjectAnimator
  private var latitude: Double = 0.0
  private var longitude: Double = 0.0

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    // Set map language
    setUpMapLocale()

    WindowCompat.setDecorFitsSystemWindows(window, false)

    setContentView(R.layout.activity_map_view_controller)

    gatherViews()

    val message = intent.getStringExtra(MAP_TITLE)
    latitude = intent.getDoubleExtra(MAP_LATITUDE, 0.0);
    longitude = intent.getDoubleExtra(MAP_LONGITUDE, 0.0);
    title = message
  }

  private fun gatherViews() {
    pinView = findViewById(R.id.pinView)
    pinViewAnimation = ObjectAnimator.ofFloat(pinView, "translationY", -50F).apply {
      duration = 300
    }
    val mapFragment = supportFragmentManager
      .findFragmentById(R.id.map) as SupportMapFragment
    mapFragment.getMapAsync(this)
  }

  private fun setUpMapLocale() {
    val languageToLoad = "en_US" // your desired language locale
    val locale = Locale(languageToLoad)
    Locale.setDefault(locale)
    baseContext.resources.configuration.setLocale(locale)
  }

  override fun onCreateOptionsMenu(menu: Menu?): Boolean {
    val inflater: MenuInflater = menuInflater
    inflater.inflate(R.menu.barbuttonitems, menu)
    return true
  }

  override fun onMapReady(googleMap: GoogleMap) {

    mMap = googleMap
    mMap.uiSettings.isCompassEnabled = false
    mMap.setOnCameraIdleListener(this)
    mMap.setOnCameraMoveStartedListener(this)
    mMap.uiSettings.apply {
      isCompassEnabled = true
      isMapToolbarEnabled = false
    }
    mMap.moveCamera(CameraUpdateFactory.newLatLngZoom(LatLng(latitude, longitude), 15F))
  }

  override fun onCameraMoveStarted(reason: Int) {
    pinViewAnimation.start()
  }

  override fun onCameraIdle() {
    pinViewAnimation.reverse()
  }

  override fun onOptionsItemSelected(item: MenuItem): Boolean {
    val returnIntent = Intent();
    val mapCoords = mMap.cameraPosition.target
    val returnMap = Arguments.createMap().apply {
      putDouble("latitude", mapCoords.latitude)
      putDouble("longitude", mapCoords.longitude)
    }
    val map = returnMap.toHashMap()
    returnIntent.putExtra("returnMap", map);
    setResult(
      if (item.itemId == R.id.action_close) Activity.RESULT_CANCELED else Activity.RESULT_OK,
      returnIntent
    )
    finish()
    return true
  }
}
