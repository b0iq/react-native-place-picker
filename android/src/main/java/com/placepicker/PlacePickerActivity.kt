package com.placepicker

import android.animation.ObjectAnimator
import android.annotation.SuppressLint
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Address
import android.location.Geocoder
import android.os.Bundle
import android.view.*
import android.widget.SearchView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.view.WindowCompat
import com.fasterxml.jackson.module.kotlin.convertValue
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationServices
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.OnMapReadyCallback
import com.google.android.gms.maps.SupportMapFragment
import com.google.android.gms.maps.model.LatLng
import java.util.*
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit


class PlacePickerActivity : AppCompatActivity(), OnMapReadyCallback,
  GoogleMap.OnCameraMoveStartedListener, GoogleMap.OnCameraIdleListener {

  private lateinit var pinView: View
  private lateinit var mMap: GoogleMap
  private lateinit var mMenu: Menu
  private lateinit var pinViewAnimation: ObjectAnimator
  private var mLocationProvider: FusedLocationProviderClient? = null
  private lateinit var geocoder: Geocoder
  private lateinit var options: PlacePickerOptions

  private fun getLocationProvider(): FusedLocationProviderClient {
    if (mLocationProvider == null) {
      mLocationProvider = LocationServices.getFusedLocationProviderClient(this)
    }
    return mLocationProvider!!
  }
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    val optionsHashMap = intent.getSerializableExtra(PICK_OPTIONS) as HashMap<*, *>
    val mapper = jacksonObjectMapper()
    options = mapper.convertValue(optionsHashMap)
    PlacePickerState.options = options
    setUpMapLocale()
    setContentView(R.layout.activity_map_view_controller)
    WindowCompat.setDecorFitsSystemWindows(window, false)
    gatherViews()
    geocoder =
      Geocoder(applicationContext, Locale.forLanguageTag(options.locale) ?: Locale.getDefault())
    this.title = options.title
    supportActionBar?.subtitle = ""
  }
  private fun gatherViews() {
    pinView = findViewById(R.id.pinView)
    pinViewAnimation = ObjectAnimator.ofFloat(pinView, "translationY", -50F).apply {
      duration = 300
    }
    val mapFragment = supportFragmentManager.findFragmentById(R.id.map) as SupportMapFragment
    mapFragment.getMapAsync(this)
  }
  private fun setUpMapLocale() {
    val locale = Locale(options.locale)
    Locale.setDefault(locale)
    baseContext.resources.configuration.setLocale(locale)
  }

  @SuppressLint("MissingPermission")
  override fun onMapReady(googleMap: GoogleMap) {
    mMap = googleMap
    mMap.setOnCameraIdleListener(this)
    mMap.setOnCameraMoveStartedListener(this)
    mMap.uiSettings.apply {
      isCompassEnabled = true
      isMapToolbarEnabled = false
      isMyLocationButtonEnabled = false

    }
//    mMap.setPadding(10, (supportActionBar?.height ?: 0), 10, getActionBarHeight())
    mMap.isMyLocationEnabled = options.enableUserLocation
    mMap.moveCamera(
      CameraUpdateFactory.newLatLngZoom(
        LatLng(
          options.initialCoordinates.latitude,
          options.initialCoordinates.longitude
        ), 15F
      )
    )
  }
  override fun onCameraMoveStarted(reason: Int) {
    if (!animationIsUp) {
      pinViewAnimation.start()
      animationIsUp = true
    }
  }
  private var animationIsUp = false
  private var mapMoveTask: ScheduledFuture<*>? = null
  private var lastAddress: Address? = null
  override fun onCameraIdle() {
    if (!options.enableGeocoding) {
      pinViewAnimation.reverse()
      animationIsUp = false
      return
    }
    mapMoveTask?.cancel(true)
    lastAddress = null
    val lat = mMap.cameraPosition.target.latitude
    val long = mMap.cameraPosition.target.longitude
    mapMoveTask = Executors.newSingleThreadScheduledExecutor().schedule({
      val address = geocoder.getFromLocation(lat, long, 1)
      lastAddress = address.first()
      runOnUiThread {
        try {
          supportActionBar?.subtitle = lastAddress?.featureName ?: "Unknown location"
          pinViewAnimation.reverse()
          animationIsUp = false
        } catch (e: Exception) {
          supportActionBar?.subtitle = ""
          pinViewAnimation.reverse()
          animationIsUp = false
        }
      }
    }, 1, TimeUnit.SECONDS)
  }
  @SuppressLint("MissingPermission")
  override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
    super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    when (requestCode) {
      1 -> { // REQUEST_CODE_ACCESS_FINE_LOCATION
        if (grantResults.size > 0
          && grantResults[0] == PackageManager.PERMISSION_GRANTED
        ) {
          val findme = mMenu.findItem(R.id.findme)
          findme.isVisible = true
        }
        return
      }
    }
  }
  private fun isLocationPermissionGranted(): Boolean {
    return if (ActivityCompat.checkSelfPermission(
        this,
        android.Manifest.permission.ACCESS_COARSE_LOCATION
      ) != PackageManager.PERMISSION_GRANTED && ActivityCompat.checkSelfPermission(
        this,
        android.Manifest.permission.ACCESS_FINE_LOCATION
      ) != PackageManager.PERMISSION_GRANTED
    ) {
      ActivityCompat.requestPermissions(
        this,
        arrayOf(
          android.Manifest.permission.ACCESS_FINE_LOCATION,
          android.Manifest.permission.ACCESS_COARSE_LOCATION
        ),
        1
      )
      false
    } else {
      true
    }
  }

  // MENU SECTION
  private fun setupSearch(menu: Menu) {
    val searchItem = menu.findItem(R.id.search)
    if (!options.enableSearch) {
      searchItem.isVisible = false
      return
    }
    val searchView = searchItem.actionView as SearchView
    searchView.queryHint = options.searchPlaceholder
    val that = this

    searchView.setOnQueryTextListener(object : SearchView.OnQueryTextListener {
      override fun onQueryTextSubmit(query: String): Boolean {
        try {
          val location = geocoder.getFromLocationName(query, 1)
          if (location.isEmpty()) {
            Toast.makeText(that, "No location was founded", Toast.LENGTH_SHORT).show()
            return true
          }
          val address = location.first()
            mMap.animateCamera(
              CameraUpdateFactory.newLatLngZoom(
                LatLng(
                  address.latitude,
                  address.longitude
                ), 15F
              )
            )
          searchView.onActionViewCollapsed()
        } catch (error: Exception) {
          Toast.makeText(that, error.message, Toast.LENGTH_SHORT).show()
        }
        return true
      }

      override fun onQueryTextChange(p0: String?): Boolean {
        return true
      }
    })
  }
  override fun onCreateOptionsMenu(menu: Menu): Boolean {
    val inflater: MenuInflater = menuInflater
    inflater.inflate(R.menu.barbuttonitems, menu)
    mMenu = menu
    setupSearch(menu)
    if (!options.enableUserLocation || !isLocationPermissionGranted()) {
      val findme = menu.findItem(R.id.findme)
      findme.isVisible = false
    } else {

    }
    return true
  }
  @SuppressLint("MissingPermission")
  override fun onOptionsItemSelected(item: MenuItem): Boolean {
    when (item.itemId) {
      R.id.findme -> {
        getLocationProvider().lastLocation.addOnSuccessListener { task ->
          if (task == null) {
            Toast.makeText(this, "Unable to get location", Toast.LENGTH_SHORT).show()
          } else {
            mMap.animateCamera(CameraUpdateFactory.newLatLng(LatLng(task.latitude, task.longitude)))
          }
        }
      }
      R.id.action_done, R.id.action_close -> {
        PlacePickerState.result.coordinate = PlacePickerCoordinate(mMap.cameraPosition.target.latitude, mMap.cameraPosition.target.longitude)
        if (lastAddress != null && options.enableGeocoding) {
          PlacePickerState.result.address = PlacePickerAddress()
          val add = lastAddress!!
          PlacePickerState.result.address?.apply {
            name        = add.featureName
            streetName  = add.thoroughfare
            city        = add.locality
            state       = add.adminArea
            zipCode     = add.postalCode
            country     = add.countryName
          }
        }
        val returnIntent = Intent()
        setResult(
          if (item.itemId == R.id.action_done) Activity.RESULT_OK else Activity.RESULT_CANCELED,
          returnIntent
        )
        finish()
      }

    }
    return true
  }

}
