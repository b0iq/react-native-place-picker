package expo.modules.placepicker


import android.Manifest
import android.animation.ObjectAnimator
import android.animation.PropertyValuesHolder
import android.content.pm.PackageManager
import android.graphics.Color
import android.location.Address
import android.location.Geocoder
import android.os.Bundle
import android.view.Menu
import android.view.MenuInflater
import android.view.MenuItem
import android.view.View
import android.widget.SearchView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.graphics.toColorInt
import androidx.core.view.WindowCompat
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationServices
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.OnMapReadyCallback
import com.google.android.gms.maps.SupportMapFragment
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.Circle
import com.google.android.gms.maps.model.CircleOptions
import java.util.Locale
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
    private var radiusCircle: Circle? = null
    private var currentRadius: Double = 1000.0
    private var radiusHandle: View? = null
    private var isDragging: Boolean = false

    private fun getLocationProvider(): FusedLocationProviderClient {
        if (mLocationProvider == null) {
            mLocationProvider = LocationServices.getFusedLocationProviderClient(this)
        }
        return mLocationProvider!!
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setUpMapLocale()
        setContentView(R.layout.activity_place_picker)
        if (supportActionBar == null) {
            val toolbar = findViewById<androidx.appcompat.widget.Toolbar>(R.id.toolbar)
            setSupportActionBar(toolbar)
        }
        WindowCompat.setDecorFitsSystemWindows(window, false)
        gatherViews()
        geocoder =
            Geocoder(
                applicationContext, Locale.forLanguageTag(PlacePickerState.globalOptions.locale) ?: Locale.getDefault()
            )
        this.title = PlacePickerState.globalOptions.title
        supportActionBar?.subtitle = ""
        if (PlacePickerState.globalOptions.enableRangeSelection) {
            currentRadius = PlacePickerState.globalOptions.initialRadius
                .coerceIn(PlacePickerState.globalOptions.minRadius, PlacePickerState.globalOptions.maxRadius)
        }
    }

    private fun gatherViews() {
        pinView = findViewById(R.id.pinView)
        pinView.background.setTint(PlacePickerState.globalOptions.color.toColorInt())
        val scaleXVal: PropertyValuesHolder = PropertyValuesHolder.ofFloat("scaleX", 1.5F)
        val scaleYVal: PropertyValuesHolder = PropertyValuesHolder.ofFloat("scaleY", 1.5F)
        val transVal: PropertyValuesHolder = PropertyValuesHolder.ofFloat("translationY", -50F)
        pinViewAnimation =
            ObjectAnimator.ofPropertyValuesHolder(pinView, scaleXVal, scaleYVal, transVal).apply {
                duration = 300
            }
        val mapFragment = supportFragmentManager.findFragmentById(R.id.map) as SupportMapFragment
        mapFragment.getMapAsync(this)
    }

    private fun setUpMapLocale() {
        val locale = Locale(PlacePickerState.globalOptions.locale)
        Locale.setDefault(locale)
        baseContext.resources.configuration.setLocale(locale)
    }

    override fun onMapReady(googleMap: GoogleMap) {
        mMap = googleMap
        mMap.setOnCameraIdleListener(this)
        mMap.setOnCameraMoveStartedListener(this)
        mMap.uiSettings.apply {
            isCompassEnabled = true
            isMapToolbarEnabled = true
            isMyLocationButtonEnabled = true

        }
        mMap.moveCamera(
            CameraUpdateFactory.newLatLngZoom(
                LatLng(
                    PlacePickerState.globalOptions.initialCoordinates?.latitude ?: 25.2048,
                    PlacePickerState.globalOptions.initialCoordinates?.longitude ?: 55.2708
                ), 15F
            )
        )
        if (PlacePickerState.globalOptions.enableRangeSelection) {
            setupRadiusSelection()
        }
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
        if (!PlacePickerState.globalOptions.enableGeocoding) {
            pinViewAnimation.reverse()
            animationIsUp = false
            if (PlacePickerState.globalOptions.enableRangeSelection) {
                updateRadiusHandlePosition()
                updateCircle()
            }
            return
        }
        mapMoveTask?.cancel(true)
        lastAddress = null
        val lat = mMap.cameraPosition.target.latitude
        val long = mMap.cameraPosition.target.longitude
        mapMoveTask = Executors.newSingleThreadScheduledExecutor().schedule({
            val address = geocoder.getFromLocation(lat, long, 1)
            lastAddress = address?.first()
            runOnUiThread {
                try {
                    supportActionBar?.subtitle = lastAddress?.featureName ?: "Unknown location"
                    pinViewAnimation.reverse()
                    animationIsUp = false
                    if (PlacePickerState.globalOptions.enableRangeSelection) {
                        updateRadiusHandlePosition()
                        updateCircle()
                    }
                } catch (e: Exception) {
                    supportActionBar?.subtitle = ""
                    pinViewAnimation.reverse()
                    animationIsUp = false
                    if (PlacePickerState.globalOptions.enableRangeSelection) {
                        updateRadiusHandlePosition()
                        updateCircle()
                    }
                }
            }
        }, 1, TimeUnit.SECONDS)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        when (requestCode) {
            1 -> {
                if (grantResults.isNotEmpty()
                    && grantResults[0] == PackageManager.PERMISSION_GRANTED
                ) {
                    val findMenu = mMenu.findItem(R.id.findMe)
                    findMenu.isVisible = true
                }
                return
            }
        }
    }

    private fun isLocationPermissionGranted(): Boolean {
        return if (ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_COARSE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED && ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(
                    Manifest.permission.ACCESS_FINE_LOCATION,
                    Manifest.permission.ACCESS_COARSE_LOCATION
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
        if (!PlacePickerState.globalOptions.enableSearch) {
            searchItem.isVisible = false
            return
        }
        val searchView = searchItem.actionView as SearchView
        searchView.queryHint = PlacePickerState.globalOptions.searchPlaceholder
        val that = this

        searchView.setOnQueryTextListener(object : SearchView.OnQueryTextListener {
            override fun onQueryTextSubmit(query: String): Boolean {
                try {
                    val location = geocoder.getFromLocationName(query, 1)
                    if (location?.isEmpty()!!) {
                        Toast.makeText(that, "No location was founded", Toast.LENGTH_SHORT).show()
                        return true
                    }
                    val address = location.first()
                    if (address != null) {
                        mMap.animateCamera(
                            CameraUpdateFactory.newLatLngZoom(
                                LatLng(
                                    address.latitude,
                                    address.longitude
                                ), 15F
                            )
                        )
                    }
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
        lg("onCreateOptionsMenu")
        val inflater: MenuInflater = menuInflater
        inflater.inflate(R.menu.barbuttonitems, menu)
        mMenu = menu
        setupSearch(menu)
        if (!PlacePickerState.globalOptions.enableUserLocation || !isLocationPermissionGranted()) {
            val findMe = menu.findItem(R.id.findMe)
            findMe.isVisible = false
        }
        return true
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        when (item.itemId) {
            R.id.findMe -> {
                if (ActivityCompat.checkSelfPermission(
                        this,
                        Manifest.permission.ACCESS_FINE_LOCATION
                    ) != PackageManager.PERMISSION_GRANTED && ActivityCompat.checkSelfPermission(
                        this,
                        Manifest.permission.ACCESS_COARSE_LOCATION
                    ) != PackageManager.PERMISSION_GRANTED
                ) {
                    // TODO: Consider calling
                    //    ActivityCompat#requestPermissions
                    // here to request the missing permissions, and then overriding
                    //   public void onRequestPermissionsResult(int requestCode, String[] permissions,
                    //                                          int[] grantResults)
                    // to handle the case where the user grants the permission. See the documentation
                    // for ActivityCompat#requestPermissions for more details.
                    return false
                }
                getLocationProvider().lastLocation.addOnSuccessListener { task ->
                    if (task == null) {
                        Toast.makeText(this, "Unable to get location", Toast.LENGTH_SHORT).show()
                    } else {
                        mMap.animateCamera(
                            CameraUpdateFactory.newLatLng(
                                LatLng(
                                    task.latitude,
                                    task.longitude
                                )
                            )
                        )
                    }
                }
            }

            R.id.action_done, R.id.action_close -> {
                PlacePickerState.globalResult.coordinate = PlacePickerCoordinate().apply {
                    latitude = mMap.cameraPosition.target.latitude
                    longitude = mMap.cameraPosition.target.longitude
                }
                if (lastAddress != null && PlacePickerState.globalOptions.enableGeocoding) {
                    PlacePickerState.globalResult.address = PlacePickerAddress()
                    val add = lastAddress
                    PlacePickerState.globalResult.address?.apply {
                        name = add?.featureName ?: ""
                        streetName = add?.thoroughfare ?: ""
                        city = add?.locality ?: ""
                        state = add?.adminArea ?: ""
                        zipCode = add?.postalCode ?: ""
                        country = add?.countryName ?: ""
                    }
                }
                if (PlacePickerState.globalOptions.enableRangeSelection) {
                    appendRadiusData()
                }
                if (item.itemId == R.id.action_done) {
                    PlacePickerState.globalResult.didCancel = false
                    PlacePickerState.globalPromise?.resolve(PlacePickerState.globalResult)
                } else {
                    if (PlacePickerState.globalOptions.rejectOnCancel) {
                        PlacePickerState.globalPromise?.reject(
                            "cancel",
                            "User cancel the operation and `rejectOnCancel` is enabled",
                            null
                        )
                    }
                }

                finish()
            }

        }
        return true
    }

    // Radius helpers
    private fun setupRadiusSelection() {
        setupRadiusHandle()
        updateCircle()
        updateRadiusHandlePosition()
    }

    private fun updateCircle() {
        radiusCircle?.remove()
        radiusCircle = mMap.addCircle(
            CircleOptions()
                .center(mMap.cameraPosition.target)
                .radius(currentRadius)
                .fillColor(parseFillColor())
                .strokeColor(parseStrokeColor())
                .strokeWidth(PlacePickerState.globalOptions.radiusStrokeWidth.toFloat())
        )
    }

    private fun setupRadiusHandle() {
        if (radiusHandle != null) return
        val handle = View(this)
        val size = 56
        handle.layoutParams = android.view.ViewGroup.LayoutParams(size, size)
        handle.background = pinView.background.mutate()
        handle.background.setTint(Color.parseColor(PlacePickerState.globalOptions.color))
        handle.setOnTouchListener { _, event ->
            when (event.action) {
                android.view.MotionEvent.ACTION_DOWN -> {
                    isDragging = true
                    true
                }
                android.view.MotionEvent.ACTION_MOVE -> {
                    if (!isDragging) return@setOnTouchListener true
                    val centerScreen = mMap.projection.toScreenLocation(mMap.cameraPosition.target)
                    val dx = event.rawX - centerScreen.x
                    val dy = event.rawY - centerScreen.y
                    val distancePx = kotlin.math.sqrt(dx*dx + dy*dy)
                    val metersPerPixel = metersPerPixelAtLatitude(mMap.cameraPosition.target.latitude)
                    val newRadius = (distancePx * metersPerPixel).toDouble()
                        .coerceIn(PlacePickerState.globalOptions.minRadius, PlacePickerState.globalOptions.maxRadius)
                    currentRadius = newRadius
                    updateRadiusHandlePosition()
                    true
                }
                android.view.MotionEvent.ACTION_UP, android.view.MotionEvent.ACTION_CANCEL -> {
                    isDragging = false
                    updateCircle()
                    true
                }
                else -> false
            }
        }
        addContentView(handle, handle.layoutParams)
        radiusHandle = handle
    }

    private fun updateRadiusHandlePosition() {
        val handle = radiusHandle ?: return
        val centerGeo = mMap.cameraPosition.target
        val eastGeo = offsetCoordinate(centerGeo.latitude, centerGeo.longitude, currentRadius, 0.0)
        val edgeScreen = mMap.projection.toScreenLocation(eastGeo)
        handle.x = edgeScreen.x - handle.width / 2f
        handle.y = edgeScreen.y - handle.height / 2f
    }

    private fun metersPerPixelAtLatitude(lat: Double): Float {
        val earthCircumference = 40075016.686
        val zoom = mMap.cameraPosition.zoom.toDouble()
        val scale = Math.pow(2.0, zoom)
        val metersPerPixel = (Math.cos(Math.toRadians(lat)) * earthCircumference) / (256.0 * scale)
        return metersPerPixel.toFloat()
    }

    private fun parseFillColor(): Int {
        val color = if (PlacePickerState.globalOptions.radiusColor.isNotEmpty()) PlacePickerState.globalOptions.radiusColor else PlacePickerState.globalOptions.color
        val base = Color.parseColor(color)
        return Color.argb(64, Color.red(base), Color.green(base), Color.blue(base))
    }

    private fun parseStrokeColor(): Int {
        val color = if (PlacePickerState.globalOptions.radiusStrokeColor.isNotEmpty()) PlacePickerState.globalOptions.radiusStrokeColor else PlacePickerState.globalOptions.color
        return Color.parseColor(color)
    }

    private fun appendRadiusData() {
        PlacePickerState.globalResult.radius = currentRadius
        val center = PlacePickerCoordinate().apply {
            latitude = mMap.cameraPosition.target.latitude
            longitude = mMap.cameraPosition.target.longitude
        }
        val ne = offsetCoordinate(center.latitude, center.longitude, currentRadius, currentRadius)
        val sw = offsetCoordinate(center.latitude, center.longitude, -currentRadius, -currentRadius)
        val bounds = BoundsCoordinates().apply {
            northeast = PlacePickerCoordinate().apply {
                latitude = ne.latitude
                longitude = ne.longitude
            }
            southwest = PlacePickerCoordinate().apply {
                latitude = sw.latitude
                longitude = sw.longitude
            }
        }
        PlacePickerState.globalResult.radiusCoordinates = RadiusCoordinates().apply {
            this.center = center
            this.bounds = bounds
        }
    }

    private fun offsetCoordinate(lat: Double, lon: Double, metersEast: Double, metersNorth: Double): LatLng {
        val earthRadius = 6378137.0
        val dLat = metersNorth / earthRadius
        val dLon = metersEast / (earthRadius * kotlin.math.cos(Math.toRadians(lat)))
        val newLat = lat + Math.toDegrees(dLat)
        val newLon = lon + Math.toDegrees(dLon)
        return LatLng(newLat, newLon)
    }
}
