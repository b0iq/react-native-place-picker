//
//  MapViewController.swift
//  react-native-place-picker
//
//  Created by b0iq on 17/06/2022.
//


import UIKit
import MapKit
import ExpoModulesCore

class PlacePickerViewController: UIViewController {
    // MARK: - Variables
    private var promise: Promise?
    private let options: PlacePickerOptions
    private let searchController = UISearchController()
    private let completer = MKLocalSearchCompleter()
    private var completerResults: [CustomSearchCompletion] = [] {
        didSet {
            searchResultContainer.dataSource = completerResults
            searchResultContainer.isHidden = completerResults.count < 1
        }
    }
    private var firstMapLoad: Bool = true
    private var lastLocation: CLPlacemark?
    private var mapMoveDebounceTimer:Timer?
    private let geocoder = CLGeocoder()
    private let locationManager = CLLocationManager()
    private var circleOverlay: MKCircle?
    private var currentRadius: Double = 1000
    private var radiusHandle: UIView?
    private var radiusPanGesture: UIPanGestureRecognizer?
    private var didSetInitialRegion: Bool = false
    
    // MARK: - Inits
    init(_ options: PlacePickerOptions,_ promise: Promise) {
        self.promise = promise
        self.options = options
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Views
    private lazy var mapPinShadow: UIView = {
        let shadowView = UIView()
        shadowView.backgroundColor = UIColor(options.color).withAlphaComponent(0.5)
        shadowView.translatesAutoresizingMaskIntoConstraints = false
        shadowView.layer.cornerRadius = 2.5
        return shadowView
    }()
    private lazy var pinImage: UIView = {
        let pinImage: UIImageView
        if #available(iOS 13.0, *) {
            pinImage = UIImageView(image: UIImage(systemName: "mappin"))
        } else {
            pinImage = UIImageView(image: UIImage(named: "mappin"))
        }
        pinImage.contentMode = .center
        pinImage.tintColor = UIColor(options.contrastColor)
        pinImage.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        return pinImage
    }()
    private lazy var pinLoading: UIActivityIndicatorView = {
        let loader = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        loader.color = UIColor(options.contrastColor)
        loader.hidesWhenStopped = true
        return loader
    }()
    private lazy var mapPinContentView: UIView = {
        let pinContainer = UIView(frame: CGRect(x: 5, y: 4, width: 40, height: 40))
        pinContainer.layer.cornerRadius = 20
        pinContainer.backgroundColor = UIColor(options.color)
        pinContainer.addSubview(pinImage)
        pinContainer.addSubview(pinLoading)
        return pinContainer
    }()
    private lazy var mapPin: UIView = {
        let heightWidth = 10
        let path = CGMutablePath()
        path.move(to: CGPoint(x:20, y: 43))
        path.addLine(to: CGPoint(x:(heightWidth/2) + 20, y: (heightWidth/2) + 43))
        path.addLine(to: CGPoint(x:heightWidth + 20, y:43))
        path.addLine(to: CGPoint(x:20, y:43))
        let shape = CAShapeLayer()
        shape.path = path
        shape.fillColor = UIColor(options.color).cgColor
        let pinView = UIView()
        pinView.layer.insertSublayer(shape, at: 0)
        pinView.addSubview(mapPinContentView)
        pinView.translatesAutoresizingMaskIntoConstraints = false
        return pinView
    }()
    private lazy var mapView: MKMapView = {
        let map = MKMapView()
        map.showsUserLocation   = true
        map.showsBuildings      = true
        map.showsTraffic        = false
        map.showsCompass        = true
        map.showsScale          = true
        map.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: options.initialCoordinates.latitude, longitude: options.initialCoordinates.longitude), latitudinalMeters: 1000, longitudinalMeters: 1000)
        map.translatesAutoresizingMaskIntoConstraints = false
        return map
    }()
    
    private lazy var searchResultContainer: DropDown = {
        let view = DropDown()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        view.isOpaque = true
        return view
    }()
    
    // MARK: - UI setup methods
    private func setupViews() {
        // MARK: - 1 Setup map view
        self.view.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.widthAnchor.constraint(equalTo: self.view.widthAnchor),
            mapView.heightAnchor.constraint(equalTo: self.view.heightAnchor),
            //            mapView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            //            mapView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
        ])
        self.view.addSubview(mapPinShadow)
        NSLayoutConstraint.activate([
            mapPinShadow.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            mapPinShadow.centerYAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerYAnchor),
            mapPinShadow.widthAnchor.constraint(equalToConstant: 5),
            mapPinShadow.heightAnchor.constraint(equalToConstant: 5)
        ])
        
        mapPin.setAnchorPoint(CGPoint(x: 0.5, y: 1))
        self.view.addSubview(mapPin)
        NSLayoutConstraint.activate([
            mapPin.centerXAnchor.constraint(equalTo: self.mapView.centerXAnchor),
            mapPin.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerYAnchor, constant: 25),
            mapPin.widthAnchor.constraint(equalToConstant: 50),
            mapPin.heightAnchor.constraint(equalToConstant: 50)
        ])
        self.view.addSubview(searchResultContainer)
        NSLayoutConstraint.activate([
            searchResultContainer.widthAnchor.constraint(equalTo: self.view.widthAnchor),
            searchResultContainer.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            searchResultContainer.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
        searchResultContainer.delegate = self
        // MARK: - 2 Setup naivgation bar
        setupNavigationBar()
    }
    private func setupNavigationBar() {
        // MARK: - 1 Make cancel button
        let customCancelButton = UIButton()
        if #available(iOS 26.0, *) {
            customCancelButton.tintColor = UIColor.clear
        } else {
            customCancelButton.tintColor = UIColor(options.color)
        }
        if #available(iOS 13.0, *) {
            let cancelImage = UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .bold))
            customCancelButton.setImage(cancelImage, for: .normal)
        } else {
            customCancelButton.setTitle("Cancel", for: .normal)
        }
        customCancelButton.addTarget(self, action: #selector(closePicker), for: .touchUpInside)
        
        // MARK: - 2 Make done button
        let customDoneButton = UIButton()
        customDoneButton.tintColor = UIColor(options.color)
        if #available(iOS 13.0, *) {
            let checkImage = UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .bold))
            customDoneButton.setImage(checkImage, for: .normal)
        } else {
            customDoneButton.setTitle("Done", for: .normal)
        }
        customDoneButton.addTarget(self, action: #selector(finalizePicker), for: .touchUpInside)
        
        // MARK: - 3 Make user location button
        let customUserLocationButton = UIButton()
        customUserLocationButton.tintColor = UIColor(options.color)
        if #available(iOS 13.0, *) {
            let checkImage = UIImage(systemName: "location", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .bold))
            customUserLocationButton.setImage(checkImage, for: .normal)
        } else {
            customUserLocationButton.setTitle("location", for: .normal)
        }
        customUserLocationButton.addTarget(self, action: #selector(pickUserLocation), for: .touchUpInside)
        
        if #available(iOS 15.0, *) {
            customDoneButton.configuration = .borderedTinted()
            customCancelButton.configuration = .borderedProminent()
            customUserLocationButton.configuration = .bordered()
        }
        
        let customCancelButtonItem = UIBarButtonItem(customView: customCancelButton)
        let customDoneButtonItem = UIBarButtonItem(customView: customDoneButton)
        let customUserLocationButtonItem = UIBarButtonItem(customView: customUserLocationButton)
        
        if (options.enableSearch) {
            if #available(iOS 13.0, *) {
                searchController.automaticallyShowsCancelButton = true
                searchController.searchBar.searchTextField.clearButtonMode = .whileEditing
                searchController.searchBar.showsCancelButton = false
            } else {
                searchController.searchBar.setValue("OK", forKey: "cancelButtonText")
            }
            searchController.searchBar.placeholder = options.searchPlaceholder
            searchController.searchBar.enablesReturnKeyAutomatically = true
            searchController.searchBar.returnKeyType = .search
            
            searchController.searchResultsUpdater = self
            searchController.searchBar.delegate = self
            searchController.obscuresBackgroundDuringPresentation = false
            searchController.hidesNavigationBarDuringPresentation = false
            navigationItem.hidesSearchBarWhenScrolling = false
            definesPresentationContext = true
            navigationItem.searchController = searchController
        }
        
        if (options.enableLargeTitle) {
            self.navigationItem.largeTitleDisplayMode = .automatic
            self.navigationController?.navigationBar.prefersLargeTitles = true
        }
        var rightItems = [customDoneButtonItem]
        if (options.enableUserLocation) {
            rightItems.append(customUserLocationButtonItem)
        }
        self.navigationItem.leftBarButtonItem = customCancelButtonItem
        self.navigationItem.rightBarButtonItems = rightItems
    }
    
    // MARK: - UIViewController Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        if #available(iOS 13, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
            navigationController?.navigationBar.isTranslucent = true
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = options.title
        if (options.enableUserLocation) {
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
            completer.delegate = self
        }
        setupViews()
        if (options.enableRangeSelection) {
            currentRadius = max(options.minRadius, min(options.maxRadius, options.initialRadius))
            setupRadiusSelection()
        }
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !didSetInitialRegion {
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: options.initialCoordinates.latitude, longitude: options.initialCoordinates.longitude),
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )
            mapView.setRegion(region, animated: false)
            mapView.delegate = self
            didSetInitialRegion = true
        }
        if options.enableRangeSelection {
            updateRadiusHandlePosition()
        }
    }
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        if (!firstMapLoad) {
            UIView.animate(withDuration: 0.3) { self.view.layoutIfNeeded() }
            mapView.setCenter(mapView.centerCoordinate, animated: true)
        } else {
            firstMapLoad = false
        }
    }
    override func viewDidDisappear(_ animated: Bool) {
        if (promise != nil && options.rejectOnCancel) {
            promise?.reject("dismissed", "Modal closed by user")
        }
    }
    
    // MARK: - Navigation bar buttons methods
    @objc private func pickUserLocation() {
        locationManager.requestLocation()
    }
    @objc private func closePicker() {
        if (options.rejectOnCancel) {
            if (promise != nil) {
                promise?.reject("cancel", "User cancel the operation and `rejectOnCancel` is enabled")
            }
        } else {
            let center = mapView.centerCoordinate
            let ne = coordinateOffset(from: center, metersEast: currentRadius, metersNorth: currentRadius)
            let sw = coordinateOffset(from: center, metersEast: -currentRadius, metersNorth: -currentRadius)
            let result = PlacePickerResult(
                coordinate: .init(wrappedValue:  PlacePickerCoordinate(latitude: .init(wrappedValue: mapView.centerCoordinate.latitude), longitude: .init(wrappedValue: mapView.centerCoordinate.longitude))),
                address: .init(wrappedValue: PlacePickerAddress(with: self.lastLocation)),
                didCancel: .init(wrappedValue: true),
                radius: .init(wrappedValue: currentRadius),
                radiusCoordinates: .init(
                    wrappedValue: RadiusCoordinates(
                        center: .init(
                            wrappedValue: PlacePickerCoordinate(
                                latitude: .init(wrappedValue: mapView.centerCoordinate.latitude),
                                longitude: .init(wrappedValue: mapView.centerCoordinate.longitude))),
                        bounds: .init(
                            wrappedValue: BoundsCoordinates(
                                northeast: .init(
                                    wrappedValue: PlacePickerCoordinate(
                                        latitude: .init(
                                            wrappedValue: ne.latitude),
                                        longitude: .init(
                                            wrappedValue: ne.longitude))),
                                southwest: .init(
                                    wrappedValue: PlacePickerCoordinate(
                                        latitude: .init(
                                            wrappedValue: sw.latitude),
                                        longitude: .init(
                                            wrappedValue: sw.longitude)))))))
            )
            promise?.resolve(result)
        }
        promise = nil
        DispatchQueue.main.async {
            self.dismiss(animated: true)
        }
    }
    @objc private func finalizePicker() {
        let center = mapView.centerCoordinate
        let ne = coordinateOffset(from: center, metersEast: currentRadius, metersNorth: currentRadius)
        let sw = coordinateOffset(from: center, metersEast: -currentRadius, metersNorth: -currentRadius)
        let result = PlacePickerResult(
            coordinate: .init(wrappedValue:  PlacePickerCoordinate(latitude: .init(wrappedValue: mapView.centerCoordinate.latitude), longitude: .init(wrappedValue: mapView.centerCoordinate.longitude))),
            address: .init(wrappedValue: PlacePickerAddress(with: self.lastLocation)),
            didCancel: .init(wrappedValue: false),
            radius: .init(wrappedValue: currentRadius),
            radiusCoordinates: .init(
                wrappedValue: RadiusCoordinates(
                    center: .init(
                        wrappedValue: PlacePickerCoordinate(
                            latitude: .init(wrappedValue: mapView.centerCoordinate.latitude),
                            longitude: .init(wrappedValue: mapView.centerCoordinate.longitude))),
                    bounds: .init(
                        wrappedValue: BoundsCoordinates(
                            northeast: .init(
                                wrappedValue: PlacePickerCoordinate(
                                    latitude: .init(
                                        wrappedValue: ne.latitude),
                                    longitude: .init(
                                        wrappedValue: ne.longitude))),
                            southwest: .init(
                                wrappedValue: PlacePickerCoordinate(
                                    latitude: .init(
                                        wrappedValue: sw.latitude),
                                    longitude: .init(
                                        wrappedValue: sw.longitude))))))))
        promise?.resolve(result)
        promise = nil
        DispatchQueue.main.async {
            self.dismiss(animated: true)
        }
    }
    
    // MARK: - Private methods
    private func setLoading(_ state: Bool) {
        pinImage.isHidden = state
        if (state) {
            pinLoading.startAnimating()
        } else {
            pinLoading.stopAnimating()
        }
    }
    private func mapWillMove() {
        startPinAnimation()
    }
    private func mapDidMove() {
        mapMoveDebounceTimer?.invalidate()
        mapMoveDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) {
            [weak self] _ in guard let self = self else { return }
            if (options.enableGeocoding) {
                setLoading(true)
                geocoder.reverseGeocodeLocation(CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude), preferredLocale: Locale(identifier: options.locale)) { location, error in
                    if let _ = error {
                        self.setLoading(false)
                        self.endPinAnimation()
                        self.lastLocation = nil
                        self.navigationItem.searchController?.searchBar.placeholder = self.options.searchPlaceholder
                        return
                    }
                    self.lastLocation = location?.first
                    if let name = location?.first?.name {
                        self.navigationItem.searchController?.searchBar.placeholder = name
                    } else {
                        self.navigationItem.searchController?.searchBar.placeholder = self.options.searchPlaceholder
                    }
                    self.setLoading(false)
                    self.endPinAnimation()
                
                }
            } else {
                self.endPinAnimation()
            }
            if options.enableRangeSelection {
                updateCircleOverlay()
                updateRadiusHandlePosition()
            }
        }
    }
    private func startPinAnimation() {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
            self.mapPin.transform =  CGAffineTransform.identity.scaledBy(x: 1.3, y: 1.3).translatedBy(x: 0, y: -10)
        })
    }
    private func endPinAnimation(_ comp: ((Bool) -> Void)? = nil) {
        let rotationAmount: CGFloat = 0.5
        UIView.animateKeyframes(withDuration: 1.8,
                                delay: 0,
                                animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1/6) {
                self.mapPin.transform =  CGAffineTransform.identity
            }
            UIView.addKeyframe(withRelativeStartTime: 1 / 6, relativeDuration: 1/6) {
                self.mapPin.transform =  CGAffineTransform.identity.rotated(by: -rotationAmount / 2)
            }
            UIView.addKeyframe(withRelativeStartTime: 2 / 6, relativeDuration: 1/6) {
                self.mapPin.transform =  CGAffineTransform.identity.rotated(by: rotationAmount / 3)
            }
            UIView.addKeyframe(withRelativeStartTime: 3 / 6, relativeDuration: 1/6) {
                self.mapPin.transform =  CGAffineTransform.identity.rotated(by: -rotationAmount / 4)
            }
            UIView.addKeyframe(withRelativeStartTime: 4 / 6, relativeDuration: 1/6) {
                self.mapPin.transform =  CGAffineTransform.identity.rotated(by: rotationAmount / 5)
            }
            UIView.addKeyframe(withRelativeStartTime: 5 / 6, relativeDuration: 1/6) {
                self.mapPin.transform =  CGAffineTransform.identity
            }
        }, completion: comp)
    }

    // MARK: - Radius selection helpers
    private func setupRadiusSelection() {
        updateCircleOverlay()
        setupRadiusHandle()
        updateRadiusHandlePosition()
    }

    private func updateCircleOverlay() {
        if let overlay = circleOverlay {
            mapView.removeOverlay(overlay)
        }
        let circle = MKCircle(center: mapView.centerCoordinate, radius: currentRadius)
        circleOverlay = circle
        mapView.addOverlay(circle)
    }

    private func setupRadiusHandle() {
        if radiusHandle == nil {
            let handle = UIView(frame: CGRect(x: 0, y: 0, width: 28, height: 28))
            handle.layer.cornerRadius = 14
            handle.layer.borderWidth = 2
            handle.layer.borderColor = UIColor(options.contrastColor).cgColor
            handle.backgroundColor = UIColor(options.color)
            let pan = UIPanGestureRecognizer(target: self, action: #selector(handleRadiusPan(_:)))
            handle.addGestureRecognizer(pan)
            self.view.addSubview(handle)
            self.radiusHandle = handle
            self.radiusPanGesture = pan
        }
    }

    @objc private func handleRadiusPan(_ gesture: UIPanGestureRecognizer) {
        guard let handle = radiusHandle else { return }
        let location = gesture.location(in: self.view)
        let centerPoint = mapView.convert(mapView.centerCoordinate, toPointTo: self.view)
        let dx = Double(location.x - centerPoint.x)
        let dy = Double(location.y - centerPoint.y)
        let distancePoints = sqrt(dx*dx + dy*dy)
        let newRadiusMeters = pointsToMeters(points: distancePoints)
        currentRadius = max(options.minRadius, min(options.maxRadius, newRadiusMeters))
        updateRadiusHandlePosition()
        if gesture.state == .ended {
            updateCircleOverlay()
        }
        if gesture.state == .ended {
            _ = handle
        }
    }

    private func updateRadiusHandlePosition() {
        guard let handle = radiusHandle else { return }
        let center = mapView.centerCoordinate
        let east = coordinateOffset(from: center, metersEast: currentRadius, metersNorth: 0)
        let point = mapView.convert(east, toPointTo: self.view)
        handle.center = point
    }

    private func pointsToMeters(points: Double) -> Double {
        let center = mapView.centerCoordinate
        let east = coordinateOffset(from: center, metersEast: 1.0, metersNorth: 0)
        let p1 = mapView.convert(center, toPointTo: self.view)
        let p2 = mapView.convert(east, toPointTo: self.view)
        let oneMeterPoints = hypot(Double(p2.x - p1.x), Double(p2.y - p1.y))
        if oneMeterPoints == 0 { return currentRadius }
        return points / oneMeterPoints
    }

    private func coordinateOffset(from coord: CLLocationCoordinate2D, metersEast: Double, metersNorth: Double) -> CLLocationCoordinate2D {
        let earthRadius = 6378137.0
        let dLat = metersNorth / earthRadius
        let dLon = metersEast / (earthRadius * cos(coord.latitude * .pi / 180))
        let lat = coord.latitude + (dLat * 180 / .pi)
        let lon = coord.longitude + (dLon * 180 / .pi)
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

extension PlacePickerViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        mapDidMove()
        
    }
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        mapWillMove()
    }
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let circle = overlay as? MKCircle {
            let renderer = MKCircleRenderer(circle: circle)
            let fillColorHex = options.radiusColor.isEmpty ? options.color : options.radiusColor
            let strokeColorHex = options.radiusStrokeColor.isEmpty ? options.color : options.radiusStrokeColor
            renderer.fillColor = UIColor(fillColorHex).withAlphaComponent(0.2)
            renderer.strokeColor = UIColor(strokeColorHex)
            renderer.lineWidth = CGFloat(options.radiusStrokeWidth)
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
}
extension PlacePickerViewController: UISearchBarDelegate {
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        self.completerResults.removeAll()
        return true
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //        print("DID SEARCH")
    }
}
extension PlacePickerViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coordinate = locations.first?.coordinate {
            mapView.setCenter(coordinate, animated: true)
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}
extension PlacePickerViewController: DropDownButtonDelegate {
    func didSelect(_ index: Int) {
        let selectedResult = completerResults[index]
        if let title = selectedResult.attrTitle?.string, let subTitle = selectedResult.attrSubtitle?.string {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = subTitle.contains(title) ? subTitle : title + ", " + subTitle
            let search = MKLocalSearch(request: request)
            search.start { [weak self] (result, error) in
                guard error == nil, let coords = result?.mapItems.first?.placemark.coordinate else {return}
                self?.mapView.setCenter(coords, animated: false)
                self?.searchController.searchBar.text = ""
                self?.searchController.isActive = false
            }
        }
    }
}
extension PlacePickerViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completerResults = completer.results.map { r in
            return CustomSearchCompletion(
                attrTitle: highlightedText(r.title, inRanges: r.titleHighlightRanges),
                attrSubtitle: highlightedText(r.subtitle, inRanges: r.subtitleHighlightRanges)
            )
        }
    }
}
extension PlacePickerViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            completer.queryFragment = searchText
        } else {
            completerResults.removeAll()
        }
    }
}
