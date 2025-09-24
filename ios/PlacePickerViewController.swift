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
    private let completer = MKLocalSearchCompleter()

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
    private lazy var customSearchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = options.searchPlaceholder
        searchBar.barTintColor = .white
        searchBar.backgroundImage = UIImage()
        searchBar.layer.cornerRadius = 12
        searchBar.layer.masksToBounds = true
        searchBar.searchBarStyle = .minimal
        searchBar.tintColor = UIColor(options.color)
        searchBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
        searchBar.translatesAutoresizingMaskIntoConstraints = false

        // Add shadow
        searchBar.layer.shadowColor = UIColor.black.cgColor
        searchBar.layer.shadowOffset = CGSize(width: 0, height: 2)
        searchBar.layer.shadowRadius = 4
        searchBar.layer.shadowOpacity = 0.1
        searchBar.delegate = self

        return searchBar
    }()

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

    private lazy var pinLoading: UIActivityIndicatorView = {
        let loader = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        loader.color = UIColor(options.contrastColor)
        loader.hidesWhenStopped = true
        return loader
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

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        if #available(iOS 13.0, *) {
            let cancelImage = UIImage(systemName: "xmark.circle.fill")
            button.setImage(cancelImage, for: .normal)
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
        }
        button.setTitleColor(UIColor(options.color), for: .normal)
        button.backgroundColor = UIColor(options.contrastColor).withAlphaComponent(0.1)
        button.layer.cornerRadius = 12
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.1
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowRadius = 3
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(closePicker), for: .touchUpInside)
        return button
    }()

    private lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Done", for: .normal)
        if #available(iOS 13.0, *) {
            let doneImage = UIImage(systemName: "checkmark")
            button.setImage(doneImage, for: .normal)
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
        }
        button.setTitleColor(UIColor.white, for: .normal)
        button.backgroundColor = UIColor(options.color)
        button.layer.cornerRadius = 12
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(finalizePicker), for: .touchUpInside)
        return button
    }()

    private lazy var locationButton: UIButton = {
        let button = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            let locationImage = UIImage(systemName: "location.circle.fill")
            button.setImage(locationImage, for: .normal)
        } else {
            button.setTitle("My Location", for: .normal)
        }
        button.setTitleColor(UIColor(options.color), for: .normal)
        button.tintColor = UIColor(options.color)
        button.backgroundColor = UIColor.white
        button.layer.cornerRadius = 12
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(pickUserLocation), for: .touchUpInside)
        return button
    }()

    // MARK: - UI setup methods
    private func setupViews() {
        // Set view background color
        self.view.backgroundColor = .white

        // MARK: - 1 Setup map view and default Apple pin
        self.view.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: self.view.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
        ])

        // Add title label
        let titleLabel = UILabel()
        titleLabel.text = options.title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16),
        ])

        // Add custom search bar
        self.view.addSubview(customSearchBar)
        NSLayoutConstraint.activate([
            customSearchBar.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            customSearchBar.leadingAnchor.constraint(
                equalTo: self.view.leadingAnchor, constant: 16),
            customSearchBar.trailingAnchor.constraint(
                equalTo: self.view.trailingAnchor, constant: -16),
            customSearchBar.heightAnchor.constraint(equalToConstant: 44),
        ])

        self.view.addSubview(searchResultContainer)
        NSLayoutConstraint.activate([
            searchResultContainer.topAnchor.constraint(
                equalTo: customSearchBar.bottomAnchor, constant: 8),
            searchResultContainer.leadingAnchor.constraint(
                equalTo: self.view.leadingAnchor, constant: 16),
            searchResultContainer.trailingAnchor.constraint(
                equalTo: self.view.trailingAnchor, constant: -16),
            searchResultContainer.heightAnchor.constraint(lessThanOrEqualToConstant: 220),
        ])

        searchResultContainer.delegate = self

        // Add buttons
        self.view.addSubview(closeButton)
        self.view.addSubview(doneButton)

        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16),
            closeButton.bottomAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            doneButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16),
            doneButton.bottomAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])

        if options.enableUserLocation {
            self.view.addSubview(locationButton)
            NSLayoutConstraint.activate([
                locationButton.trailingAnchor.constraint(
                    equalTo: self.view.trailingAnchor, constant: -16),
                locationButton.topAnchor.constraint(
                    equalTo: searchResultContainer.bottomAnchor, constant: 16),
                locationButton.widthAnchor.constraint(equalToConstant: 44),
                locationButton.heightAnchor.constraint(equalToConstant: 44),
            ])
        }

        // Shadow under the pin
        self.view.addSubview(mapPinShadow)
        NSLayoutConstraint.activate([
            mapPinShadow.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            mapPinShadow.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            mapPinShadow.widthAnchor.constraint(equalToConstant: 8),
            mapPinShadow.heightAnchor.constraint(equalToConstant: 8),
        ])

        // Add loading indicator for pin
        pinLoading.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(pinLoading)
        NSLayoutConstraint.activate([
            pinLoading.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            pinLoading.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: -20),
            pinLoading.widthAnchor.constraint(equalToConstant: 30),
            pinLoading.heightAnchor.constraint(equalToConstant: 30),
        ])
    }

    // MARK: - UIViewController Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        if options.enableUserLocation {
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
            completer.delegate = self
        }
        navigationController?.setNavigationBarHidden(true, animated: false)
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

    // MARK: - Button action methods
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
                    self.customSearchBar.placeholder = self.options.searchPlaceholder
                    return
                }
                self.lastLocation = location?.first
                if let name = location?.first?.name {
                    self.customSearchBar.placeholder = name
                } else {
                    self.customSearchBar.placeholder = self.options.searchPlaceholder
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
                // Use shadow animation to indicate pin movement
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
                    self.mapPinShadow.transform = CGAffineTransform.identity
                    self.mapPinShadow.alpha = 1.0
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
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchText.isEmpty {
            completer.queryFragment = searchText
        } else {
            completerResults.removeAll()
        }
    }

    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        self.completerResults.removeAll()
        return true
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
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
                self?.customSearchBar.text = ""
                self?.customSearchBar.resignFirstResponder()
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
