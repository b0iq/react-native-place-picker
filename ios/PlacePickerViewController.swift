//
//  MapViewController.swift
//  react-native-place-picker
//
//  Created by b0iq on 17/06/2022.
//

import ExpoModulesCore
import MapKit
import UIKit

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
    private var mapMoveDebounceTimer: Timer?
    private let geocoder = CLGeocoder()
    private let locationManager = CLLocationManager()

    // MARK: - Inits
    init(_ options: PlacePickerOptions, _ promise: Promise) {
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
        path.move(to: CGPoint(x: 20, y: 43))
        path.addLine(to: CGPoint(x: (heightWidth / 2) + 20, y: (heightWidth / 2) + 43))
        path.addLine(to: CGPoint(x: heightWidth + 20, y: 43))
        path.addLine(to: CGPoint(x: 20, y: 43))
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
        map.showsUserLocation = true
        map.showsBuildings = true
        map.showsTraffic = false
        map.showsCompass = true
        map.showsScale = true
        map.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: options.initialCoordinates.latitude,
                longitude: options.initialCoordinates.longitude), latitudinalMeters: 1000,
            longitudinalMeters: 1000)
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
        ])
        self.view.addSubview(mapPinShadow)
        NSLayoutConstraint.activate([
            mapPinShadow.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            mapPinShadow.centerYAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.centerYAnchor),
            mapPinShadow.widthAnchor.constraint(equalToConstant: 5),
            mapPinShadow.heightAnchor.constraint(equalToConstant: 5),
        ])

        mapPin.setAnchorPoint(CGPoint(x: 0.5, y: 1))
        self.view.addSubview(mapPin)
        NSLayoutConstraint.activate([
            mapPin.centerXAnchor.constraint(equalTo: self.mapView.centerXAnchor),
            mapPin.bottomAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.centerYAnchor, constant: 25),
            mapPin.widthAnchor.constraint(equalToConstant: 50),
            mapPin.heightAnchor.constraint(equalToConstant: 50),
        ])
        self.view.addSubview(searchResultContainer)
        NSLayoutConstraint.activate([
            searchResultContainer.widthAnchor.constraint(equalTo: self.view.widthAnchor),
            searchResultContainer.topAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            searchResultContainer.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
        ])

        searchResultContainer.delegate = self
        // MARK: - 2 Setup naivgation bar
        setupNavigationBar()
    }
    private func setupNavigationBar() {
        // MARK: - 1 Make cancel button (Shad CN secondary/outline)
        let customCancelButton = UIButton(type: .system)
        customCancelButton.addTarget(self, action: #selector(closePicker), for: .touchUpInside)

        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.baseForegroundColor = UIColor(options.color)
            if #available(iOS 13.0, *) {
                config.image = UIImage(
                    systemName: "xmark",
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .bold))
            }
            config.contentInsets = NSDirectionalEdgeInsets(
                top: 8, leading: 8, bottom: 8, trailing: 8)
            config.background.strokeColor = nil
            config.background.strokeWidth = 0
            config.background.cornerRadius = 8
            customCancelButton.configuration = config
        } else {
            customCancelButton.tintColor = UIColor(options.color)
            if #available(iOS 13.0, *) {
                let cancelImage = UIImage(
                    systemName: "xmark",
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .bold))
                customCancelButton.setImage(cancelImage, for: .normal)
            } else {
                // For iOS versions prior to 13, system images are not available.
                // Ensure a title is set and give it a background for better visibility.
                customCancelButton.setTitle("Cancel", for: .normal)
            }
            // Add a background color for older iOS versions to make the button stand out
            customCancelButton.backgroundColor = UIColor(white: 0.95, alpha: 1.0)  // Light gray background
            // customCancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold) // Not needed for icon-only
            customCancelButton.layer.cornerRadius = 8  // Kept rounded corners for shape
            customCancelButton.layer.borderColor = nil  // Removed border
            customCancelButton.layer.borderWidth = 0  // Removed border
            customCancelButton.contentEdgeInsets = UIEdgeInsets(
                top: 8, left: 8, bottom: 8, right: 8)  // Symmetrical for icon
        }

        // MARK: - 2 Make submit button (Shad CN primary)
        let customSubmitButton = UIButton(type: .system)
        customSubmitButton.addTarget(self, action: #selector(finalizePicker), for: .touchUpInside)

        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.filled()
            config.baseBackgroundColor = UIColor(options.color)
            config.baseForegroundColor = UIColor(options.contrastColor)
            config.title = "Submit"
            config.contentInsets = NSDirectionalEdgeInsets(
                top: 8, leading: 16, bottom: 8, trailing: 16)
            config.background.cornerRadius = 16  // Made all rounded (half of estimated button height 32)
            customSubmitButton.configuration = config
        } else {
            customSubmitButton.setTitle("Submit", for: .normal)
            customSubmitButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            customSubmitButton.backgroundColor = UIColor(options.color)
            customSubmitButton.tintColor = UIColor(options.contrastColor)
            customSubmitButton.layer.cornerRadius = 16  // Made all rounded (half of estimated button height 32)
            customSubmitButton.contentEdgeInsets = UIEdgeInsets(
                top: 8, left: 16, bottom: 8, right: 16)
        }

        // MARK: - 3 Make user location button (Shad CN secondary/icon-only)
        let customUserLocationButton = UIButton(type: .system)
        customUserLocationButton.addTarget(
            self, action: #selector(pickUserLocation), for: .touchUpInside)

        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.baseForegroundColor = UIColor(options.color)
            if #available(iOS 13.0, *) {
                config.image = UIImage(
                    systemName: "location",
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .bold))
            }
            config.contentInsets = NSDirectionalEdgeInsets(
                top: 8, leading: 8, bottom: 8, trailing: 8)
            config.background.strokeColor = nil
            config.background.strokeWidth = 0
            config.background.cornerRadius = 8
            customUserLocationButton.configuration = config
        } else {
            customUserLocationButton.tintColor = UIColor(options.color)
            if #available(iOS 13.0, *) {
                let locationImage = UIImage(
                    systemName: "location",
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .bold))
                customUserLocationButton.setImage(locationImage, for: .normal)
            } else {
                // For iOS versions prior to 13, system images are not available.
                // Ensure a title is set and give it a background for better visibility.
                customUserLocationButton.setTitle("Location", for: .normal)  // Ensure title is set
            }
            // Add a background color for older iOS versions to make the button stand out
            customUserLocationButton.backgroundColor = UIColor(white: 0.95, alpha: 1.0)  // Light gray background
            customUserLocationButton.layer.cornerRadius = 8
            customUserLocationButton.layer.borderColor = nil  // Removed border
            customUserLocationButton.layer.borderWidth = 0  // Removed border
            customUserLocationButton.contentEdgeInsets = UIEdgeInsets(
                top: 8, left: 8, bottom: 8, right: 8)
        }

        let customCancelButtonItem = UIBarButtonItem(customView: customCancelButton)
        let customSubmitButtonItem = UIBarButtonItem(customView: customSubmitButton)
        let customUserLocationButtonItem = UIBarButtonItem(customView: customUserLocationButton)

        if options.enableSearch {
            if #available(iOS 13.0, *) {
                searchController.automaticallyShowsCancelButton = true
                searchController.searchBar.searchTextField.clearButtonMode = .whileEditing
                searchController.searchBar.showsCancelButton = false

                // Shad CN search bar styling
                searchController.searchBar.searchTextField.backgroundColor =
                    .secondarySystemBackground
                searchController.searchBar.searchTextField.layer.cornerRadius = 8
                searchController.searchBar.searchTextField.clipsToBounds = true
                searchController.searchBar.tintColor = UIColor(options.color)  // Cursor tint
                // Changed to systemBackground for consistency with the navigation bar background
                searchController.searchBar.barTintColor = .systemBackground
                searchController.searchBar.backgroundColor = .systemBackground
            } else {
                searchController.searchBar.setValue("OK", forKey: "cancelButtonText")
                // Changed to systemBackground for consistency with the navigation bar background
                searchController.searchBar.barTintColor = .systemBackground
                searchController.searchBar.backgroundColor = .systemBackground
            }
            searchController.searchBar.placeholder = options.searchPlaceholder
            searchController.searchBar.enablesReturnKeyAutomatically = true
            searchController.searchBar.returnKeyType = .search

            searchController.searchResultsUpdater = self
            searchController.searchBar.delegate = self
            searchController.obscuresBackgroundDuringPresentation = false
            searchController.hidesNavigationBarDuringPresentation = false  // Keep search bar always visible
            navigationItem.hidesSearchBarWhenScrolling = false
            definesPresentationContext = true
            navigationItem.searchController = searchController
        }

        if options.enableLargeTitle {
            self.navigationItem.largeTitleDisplayMode = .automatic
            self.navigationController?.navigationBar.prefersLargeTitles = true
        } else {
            // Ensure title is inline if large title is not preferred, for consistency with search bar below title.
            self.navigationItem.largeTitleDisplayMode = .never
            self.navigationController?.navigationBar.prefersLargeTitles = false
        }

        var rightItems = [customSubmitButtonItem]
        if options.enableUserLocation {
            rightItems.append(customUserLocationButtonItem)
        }
        self.navigationItem.leftBarButtonItem = customCancelButtonItem
        self.navigationItem.rightBarButtonItems = rightItems
    }

    // MARK: - UIViewController Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 13, *) {
            let appearance = UINavigationBarAppearance()
            // Configure with a solid background color for visibility
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemBackground  // Use system background for visibility
            appearance.shadowColor = nil  // Remove any shadow line if desired

            // Ensure title and large title text are visible against the chosen background
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
            appearance.titleTextAttributes = [.foregroundColor: UIColor.label]

            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
            navigationController?.navigationBar.compactAppearance = appearance
            navigationController?.navigationBar.isTranslucent = false  // Set to false with opaque background
        } else {
            // Fallback for older iOS: Make navigation bar opaque
            self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
            self.navigationController?.navigationBar.shadowImage = nil
            self.navigationController?.navigationBar.isTranslucent = false
            self.navigationController?.navigationBar.backgroundColor = .systemBackground  // Use system background for visibility
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = options.title
        if options.enableUserLocation {
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
            completer.delegate = self
        }
        setupViews()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        mapView.centerCoordinate = CLLocationCoordinate2D(
            latitude: options.initialCoordinates.latitude,
            longitude: options.initialCoordinates.longitude)
        mapView.delegate = self
    }
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        if !firstMapLoad {
            UIView.animate(withDuration: 0.3) { self.view.layoutIfNeeded() }
            mapView.setCenter(mapView.centerCoordinate, animated: true)
        } else {
            firstMapLoad = false
        }
    }
    override func viewDidDisappear(_ animated: Bool) {
        if promise != nil && options.rejectOnCancel {
            promise?.reject("dismissed", "Modal closed by user")
        }
    }

    // MARK: - Navigation bar buttons methods
    @objc private func pickUserLocation() {
        locationManager.requestLocation()
    }
    @objc private func closePicker() {
        if options.rejectOnCancel {
            if promise != nil {
                promise?.reject(
                    "cancel", "User cancel the operation and `rejectOnCancel` is enabled")
            }
        } else {
            let result = PlacePickerResult(
                coordinate: .init(
                    wrappedValue: PlacePickerCoordinate(
                        latitude: .init(wrappedValue: mapView.centerCoordinate.latitude),
                        longitude: .init(wrappedValue: mapView.centerCoordinate.longitude))),
                address: .init(wrappedValue: PlacePickerAddress(with: self.lastLocation)),
                didCancel: .init(wrappedValue: true))
            promise?.resolve(result)
        }
        promise = nil
        DispatchQueue.main.async {
            self.dismiss(animated: true)
        }
    }
    @objc private func finalizePicker() {
        let result = PlacePickerResult(
            coordinate: .init(
                wrappedValue: PlacePickerCoordinate(
                    latitude: .init(wrappedValue: mapView.centerCoordinate.latitude),
                    longitude: .init(wrappedValue: mapView.centerCoordinate.longitude))),
            address: .init(wrappedValue: PlacePickerAddress(with: self.lastLocation)),
            didCancel: .init(wrappedValue: false))
        promise?.resolve(result)
        promise = nil
        DispatchQueue.main.async {
            self.dismiss(animated: true)
        }
    }

    // MARK: - Private methods
    private func setLoading(_ state: Bool) {
        pinImage.isHidden = state
        if state {
            pinLoading.startAnimating()
        } else {
            pinLoading.stopAnimating()
        }
    }
    private func mapWillMove() {
        startPinAnimation()
    }
    private func mapDidMove() {
        if options.enableGeocoding {
            setLoading(true)
            geocoder.reverseGeocodeLocation(
                CLLocation(
                    latitude: mapView.centerCoordinate.latitude,
                    longitude: mapView.centerCoordinate.longitude),
                preferredLocale: Locale(identifier: options.locale)
            ) { location, error in
                if error != nil {
                    self.setLoading(false)
                    self.endPinAnimation()
                    self.lastLocation = nil
                    // Update search bar placeholder with default if error
                    self.navigationItem.searchController?.searchBar.placeholder =
                        self.options.searchPlaceholder
                    return
                }
                self.lastLocation = location?.first
                if let name = location?.first?.name {
                    self.navigationItem.searchController?.searchBar.placeholder = name
                } else {
                    self.navigationItem.searchController?.searchBar.placeholder =
                        self.options.searchPlaceholder
                }
                self.setLoading(false)
                self.endPinAnimation()

            }
        } else {
            self.endPinAnimation()
        }
    }
    private func startPinAnimation() {
        UIView.animate(
            withDuration: 0.3, delay: 0, options: [.curveEaseInOut],
            animations: {
                self.mapPin.transform = CGAffineTransform.identity.scaledBy(x: 1.3, y: 1.3)
                    .translatedBy(x: 0, y: -10)
            })
    }
    private func endPinAnimation(_ comp: ((Bool) -> Void)? = nil) {
        let rotationAmount: CGFloat = 0.5
        UIView.animateKeyframes(
            withDuration: 1.8,
            delay: 0,
            animations: {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1 / 6) {
                    self.mapPin.transform = CGAffineTransform.identity
                }
                UIView.addKeyframe(withRelativeStartTime: 1 / 6, relativeDuration: 1 / 6) {
                    self.mapPin.transform = CGAffineTransform.identity.rotated(
                        by: -rotationAmount / 2)
                }
                UIView.addKeyframe(withRelativeStartTime: 2 / 6, relativeDuration: 1 / 6) {
                    self.mapPin.transform = CGAffineTransform.identity.rotated(
                        by: rotationAmount / 3)
                }
                UIView.addKeyframe(withRelativeStartTime: 3 / 6, relativeDuration: 1 / 6) {
                    self.mapPin.transform = CGAffineTransform.identity.rotated(
                        by: -rotationAmount / 4)
                }
                UIView.addKeyframe(withRelativeStartTime: 4 / 6, relativeDuration: 1 / 6) {
                    self.mapPin.transform = CGAffineTransform.identity.rotated(
                        by: rotationAmount / 5)
                }
                UIView.addKeyframe(withRelativeStartTime: 5 / 6, relativeDuration: 1 / 6) {
                    self.mapPin.transform = CGAffineTransform.identity
                }
            }, completion: comp)
    }
}

extension PlacePickerViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        mapDidMove()

    }
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        mapWillMove()
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
        if let title = selectedResult.attrTitle?.string,
            let subTitle = selectedResult.attrSubtitle?.string
        {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery =
                subTitle.contains(title) ? subTitle : title + ", " + subTitle
            let search = MKLocalSearch(request: request)
            search.start { [weak self] (result, error) in
                guard error == nil, let coords = result?.mapItems.first?.placemark.coordinate else {
                    return
                }
                self?.mapView.setCenter(coords, animated: true)
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
