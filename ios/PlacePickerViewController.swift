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
        shadowView.backgroundColor = UIColor(options.color).withAlphaComponent(0.3)
        shadowView.translatesAutoresizingMaskIntoConstraints = false
        shadowView.layer.cornerRadius = 4
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOpacity = 0.2
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 2)
        shadowView.layer.shadowRadius = 6
        return shadowView
    }()

    private lazy var pinImage: UIView = {
        let pinImage: UIImageView
        if #available(iOS 13.0, *) {
            pinImage = UIImageView(image: UIImage(systemName: "mappin.circle.fill"))
        } else {
            pinImage = UIImageView(image: UIImage(named: "mappin"))
        }
        pinImage.contentMode = .scaleAspectFit
        pinImage.tintColor = UIColor(options.contrastColor)
        pinImage.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        return pinImage
    }()

    private lazy var pinLoading: UIActivityIndicatorView = {
        let loader = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        loader.color = UIColor(options.contrastColor)
        loader.hidesWhenStopped = true
        return loader
    }()

    private lazy var mapPinContentView: UIView = {
        let pinContainer = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        pinContainer.layer.cornerRadius = 20
        pinContainer.backgroundColor = UIColor(options.color)
        pinContainer.layer.shadowColor = UIColor.black.cgColor
        pinContainer.layer.shadowOpacity = 0.2
        pinContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        pinContainer.layer.shadowRadius = 4
        pinContainer.addSubview(pinImage)
        pinContainer.addSubview(pinLoading)

        // Center the pin image and loading indicator
        pinImage.center = CGPoint(
            x: pinContainer.bounds.width / 2, y: pinContainer.bounds.height / 2)
        pinLoading.center = CGPoint(
            x: pinContainer.bounds.width / 2, y: pinContainer.bounds.height / 2)

        return pinContainer
    }()

    private lazy var mapPin: UIView = {
        let pinView = UIView()

        // Create a custom pin shape using bezier path
        let pinTailPath = UIBezierPath()
        pinTailPath.move(to: CGPoint(x: 20, y: 40))
        pinTailPath.addLine(to: CGPoint(x: 16, y: 46))
        pinTailPath.addLine(to: CGPoint(x: 24, y: 46))
        pinTailPath.close()

        let tailShape = CAShapeLayer()
        tailShape.path = pinTailPath.cgPath
        tailShape.fillColor = UIColor(options.color).cgColor

        pinView.layer.insertSublayer(tailShape, at: 0)
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
        if #available(iOS 13.0, *) {
            map.overrideUserInterfaceStyle = .light
        }
        map.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: options.initialCoordinates.latitude,
                longitude: options.initialCoordinates.longitude),
            latitudinalMeters: 1000,
            longitudinalMeters: 1000)
        map.translatesAutoresizingMaskIntoConstraints = false
        return map
    }()

    private lazy var searchResultContainer: DropDown = {
        let view = DropDown()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        view.isOpaque = true
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.15
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        view.clipsToBounds = false
        return view
    }()

    // MARK: - UI setup methods
    private func setupViews() {
        // Set view background color
        self.view.backgroundColor = .white

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
            mapPinShadow.widthAnchor.constraint(equalToConstant: 8),
            mapPinShadow.heightAnchor.constraint(equalToConstant: 8),
        ])

        mapPin.setAnchorPoint(CGPoint(x: 0.5, y: 1))
        self.view.addSubview(mapPin)
        NSLayoutConstraint.activate([
            mapPin.centerXAnchor.constraint(equalTo: self.mapView.centerXAnchor),
            mapPin.bottomAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.centerYAnchor, constant: 20),
            mapPin.widthAnchor.constraint(equalToConstant: 50),
            mapPin.heightAnchor.constraint(equalToConstant: 50),
        ])

        self.view.addSubview(searchResultContainer)
        NSLayoutConstraint.activate([
            searchResultContainer.widthAnchor.constraint(
                equalTo: self.view.widthAnchor, constant: -32),
            searchResultContainer.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            searchResultContainer.topAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 56),
            searchResultContainer.bottomAnchor.constraint(
                lessThanOrEqualTo: self.view.bottomAnchor, constant: -100),
        ])

        searchResultContainer.delegate = self

        // MARK: - 2 Setup navigation bar
        setupNavigationBar()
    }

    private func setupNavigationBar() {
        // MARK: - 1 Make cancel button
        let customCancelButton = UIButton(type: .system)
        customCancelButton.tintColor = UIColor(options.color)
        customCancelButton.layer.cornerRadius = 8
        customCancelButton.backgroundColor = UIColor(options.contrastColor).withAlphaComponent(0.1)
        customCancelButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)

        if #available(iOS 13.0, *) {
            let cancelImage = UIImage(
                systemName: "xmark.circle.fill",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold))
            customCancelButton.setImage(cancelImage, for: .normal)
        } else {
            customCancelButton.setTitle("Cancel", for: .normal)
        }
        customCancelButton.addTarget(self, action: #selector(closePicker), for: .touchUpInside)

        // MARK: - 2 Make done button
        let customDoneButton = UIButton(type: .system)
        customDoneButton.tintColor = .white
        customDoneButton.backgroundColor = UIColor(options.color)
        customDoneButton.layer.cornerRadius = 8
        customDoneButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)

        if #available(iOS 13.0, *) {
            let checkImage = UIImage(
                systemName: "checkmark",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold))
            customDoneButton.setImage(checkImage, for: .normal)
            customDoneButton.setTitle(" Done", for: .normal)
        } else {
            customDoneButton.setTitle("Done", for: .normal)
        }
        customDoneButton.addTarget(self, action: #selector(finalizePicker), for: .touchUpInside)

        // MARK: - 3 Make user location button
        let customUserLocationButton = UIButton(type: .system)
        customUserLocationButton.tintColor = UIColor(options.color)
        customUserLocationButton.backgroundColor = UIColor(options.contrastColor)
            .withAlphaComponent(0.1)
        customUserLocationButton.layer.cornerRadius = 8
        customUserLocationButton.contentEdgeInsets = UIEdgeInsets(
            top: 8, left: 12, bottom: 8, right: 12)

        if #available(iOS 13.0, *) {
            let locationImage = UIImage(
                systemName: "location.circle.fill",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold))
            customUserLocationButton.setImage(locationImage, for: .normal)
        } else {
            customUserLocationButton.setTitle("location", for: .normal)
        }
        customUserLocationButton.addTarget(
            self, action: #selector(pickUserLocation), for: .touchUpInside)

        let customCancelButtonItem = UIBarButtonItem(customView: customCancelButton)
        let customDoneButtonItem = UIBarButtonItem(customView: customDoneButton)
        let customUserLocationButtonItem = UIBarButtonItem(customView: customUserLocationButton)

        if options.enableSearch {
            if #available(iOS 13.0, *) {
                searchController.automaticallyShowsCancelButton = true
                searchController.searchBar.searchTextField.clearButtonMode = .whileEditing
                searchController.searchBar.showsCancelButton = false
                searchController.searchBar.searchTextField.backgroundColor = UIColor.systemGray6
                searchController.searchBar.tintColor = UIColor(options.color)
            } else {
                searchController.searchBar.setValue("OK", forKey: "cancelButtonText")
            }
            searchController.searchBar.placeholder = options.searchPlaceholder
            searchController.searchBar.enablesReturnKeyAutomatically = true
            searchController.searchBar.returnKeyType = .search

            // Customize search bar appearance
            searchController.searchBar.layer.cornerRadius = 10
            searchController.searchBar.clipsToBounds = true

            searchController.searchResultsUpdater = self
            searchController.searchBar.delegate = self
            searchController.obscuresBackgroundDuringPresentation = false
            searchController.hidesNavigationBarDuringPresentation = false
            navigationItem.hidesSearchBarWhenScrolling = false
            definesPresentationContext = true
            navigationItem.searchController = searchController
        }

        if options.enableLargeTitle {
            self.navigationItem.largeTitleDisplayMode = .automatic
            self.navigationController?.navigationBar.prefersLargeTitles = true
        }
        var rightItems = [customDoneButtonItem]
        if options.enableUserLocation {
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
            appearance.backgroundColor = .white
            appearance.shadowColor = .clear

            // Customize the navigation bar text
            appearance.titleTextAttributes = [
                .foregroundColor: UIColor.darkText,
                .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
            ]

            appearance.largeTitleTextAttributes = [
                .foregroundColor: UIColor.darkText,
                .font: UIFont.systemFont(ofSize: 28, weight: .bold),
            ]

            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
            navigationController?.navigationBar.isTranslucent = true
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
            withDuration: 0.3, delay: 0, options: [.curveEaseOut],
            animations: {
                self.mapPin.transform = CGAffineTransform.identity.scaledBy(x: 1.2, y: 1.2)
                    .translatedBy(x: 0, y: -15)

                // Add a subtle spring effect
                self.mapPinShadow.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
                self.mapPinShadow.alpha = 0.7
            })
    }

    private func endPinAnimation(_ comp: ((Bool) -> Void)? = nil) {
        UIView.animateKeyframes(
            withDuration: 0.8,
            delay: 0,
            options: .calculationModeCubic,
            animations: {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5) {
                    self.mapPin.transform = CGAffineTransform.identity
                    self.mapPinShadow.transform = CGAffineTransform.identity
                    self.mapPinShadow.alpha = 1.0
                }

                // Add a subtle bounce effect
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.2) {
                    self.mapPin.transform = CGAffineTransform.identity.scaledBy(x: 1.1, y: 0.9)
                }

                UIView.addKeyframe(withRelativeStartTime: 0.7, relativeDuration: 0.3) {
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
