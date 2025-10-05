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
    // Removed: private let searchController = UISearchController()
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
    private var shouldCenterMapOnUserLocationUpdate: Bool = false  // New flag to control map centering

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
        // Use a fixed black for shadow, as it generally looks good on any background
        shadowView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
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
        // Use system background color for contrast with the pin's label color
        pinImage.tintColor = .systemBackground
        pinImage.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        return pinImage
    }()
    private lazy var pinLoading: UIActivityIndicatorView = {
        let loader = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        // Use system background color for contrast with the pin's label color
        loader.color = .systemBackground
        loader.hidesWhenStopped = true
        return loader
    }()
    private lazy var mapPinContentView: UIView = {
        let pinContainer = UIView(frame: CGRect(x: 5, y: 4, width: 40, height: 40))
        pinContainer.layer.cornerRadius = 20
        // Use label color (adaptive black/white) for the pin's main body
        pinContainer.backgroundColor = .label
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
        // Use label color (adaptive black/white) for the pin's triangle
        shape.fillColor = UIColor.label.cgColor
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

    private lazy var searchTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = options.searchPlaceholder
        textField.returnKeyType = .search
        textField.enablesReturnKeyAutomatically = true
        textField.clearButtonMode = .whileEditing
        textField.translatesAutoresizingMaskIntoConstraints = false

        if #available(iOS 13.0, *) {
            textField.textColor = .label
            textField.backgroundColor = .secondarySystemBackground
            // Add search icon
            let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
            searchIcon.tintColor = .label
            searchIcon.contentMode = .scaleAspectFit
            let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 20))
            searchIcon.frame = CGRect(x: 5, y: 0, width: 20, height: 20)
            leftView.addSubview(searchIcon)
            textField.leftView = leftView
            textField.leftViewMode = .always
            textField.layer.cornerRadius = 10  // Rounded corners for modern look
            textField.clipsToBounds = true
        } else {
            textField.borderStyle = .roundedRect
        }
        return textField
    }()

    // MARK: - UI setup methods
    private func setupViews() {
        // MARK: - 1 Setup map view
        self.view.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.widthAnchor.constraint(equalTo: self.view.widthAnchor),
            mapView.heightAnchor.constraint(equalTo: self.view.heightAnchor),
        ])

        var topAnchorForSearchResultContainer: NSLayoutYAxisAnchor = self.view.safeAreaLayoutGuide
            .topAnchor

        if options.enableSearch {
            // Add search text field below the navigation bar with padding
            self.view.addSubview(searchTextField)
            searchTextField.delegate = self
            searchTextField.addTarget(
                self, action: #selector(searchTextFieldDidChange(_:)), for: .editingChanged)

            NSLayoutConstraint.activate([
                searchTextField.topAnchor.constraint(
                    equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 10),  // Padding from top
                searchTextField.leadingAnchor.constraint(
                    equalTo: self.view.leadingAnchor, constant: 16),  // Left padding
                searchTextField.trailingAnchor.constraint(
                    equalTo: self.view.trailingAnchor, constant: -16),  // Right padding
                searchTextField.heightAnchor.constraint(equalToConstant: 40),  // Standard height
            ])
            topAnchorForSearchResultContainer = searchTextField.bottomAnchor
        }

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
            searchResultContainer.topAnchor.constraint(equalTo: topAnchorForSearchResultContainer),
            searchResultContainer.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            searchResultContainer.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            searchResultContainer.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
        ])

        searchResultContainer.delegate = self
        // MARK: - 2 Setup naivgation bar
        setupNavigationBar()
    }
    private func setupNavigationBar() {
        // MARK: - 1 Make cancel button
        let customCancelButton = UIButton()
        // Use label color (adaptive black/white) for button tint
        customCancelButton.tintColor = .label
        if #available(iOS 13.0, *) {
            let cancelImage = UIImage(
                systemName: "xmark",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .bold))
            customCancelButton.setImage(cancelImage, for: .normal)
        } else {
            customCancelButton.setTitle("Cancel", for: .normal)
        }
        customCancelButton.addTarget(self, action: #selector(closePicker), for: .touchUpInside)

        // MARK: - 2 Make done button
        let customDoneButton = UIButton()
        // Use label color (adaptive black/white) for button tint
        customDoneButton.tintColor = .label
        if #available(iOS 13.0, *) {
            let checkImage = UIImage(
                systemName: "checkmark",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .bold))
            customDoneButton.setImage(checkImage, for: .normal)
        } else {
            customDoneButton.setTitle("Done", for: .normal)
        }
        customDoneButton.addTarget(self, action: #selector(finalizePicker), for: .touchUpInside)

        // MARK: - 3 Make user location button
        let customUserLocationButton = UIButton()
        // Use label color (adaptive black/white) for button tint
        customUserLocationButton.tintColor = .label
        if #available(iOS 13.0, *) {
            let checkImage = UIImage(
                systemName: "location",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .bold))
            customUserLocationButton.setImage(checkImage, for: .normal)
        } else {
            customUserLocationButton.setTitle("location", for: .normal)
        }
        customUserLocationButton.addTarget(
            self, action: #selector(pickUserLocation), for: .touchUpInside)

        if #available(iOS 15.0, *) {
            // These configurations will automatically pick up the tintColor
            customDoneButton.configuration = .borderedTinted()
            customCancelButton.configuration = .bordered()
            customUserLocationButton.configuration = .bordered()
        }

        let customCancelButtonItem = UIBarButtonItem(customView: customCancelButton)
        let customDoneButtonItem = UIBarButtonItem(customView: customDoneButton)
        let customUserLocationButtonItem = UIBarButtonItem(customView: customUserLocationButton)

        if options.enableSearch {
            // The searchTextField is now a subview of the controller's view,
            // not part of the navigation bar's titleView.
            // Delegate and target actions are set in setupViews().
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
        super.viewWillAppear(animated)
        if #available(iOS 13, *) {
            let appearance = UINavigationBarAppearance()
            // Configure with an opaque background to prevent transparency
            appearance.configureWithOpaqueBackground()
            // Explicitly set background color to system background (adaptive black/white)
            appearance.backgroundColor = .systemBackground
            // Set title text attributes to label color for black/white theme
            appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
            // Optionally remove the shadow line under the navigation bar
            appearance.shadowColor = .clear

            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
            // Ensure the navigation bar is not translucent to prevent blurring map content
            navigationController?.navigationBar.isTranslucent = false
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = options.title
        // Set the view's background color to system background for consistency
        self.view.backgroundColor = .systemBackground
        if options.enableUserLocation {
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
            completer.delegate = self
        }
        setupViews()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Removed this line to prevent map recentering on layout changes (e.g., keyboard appearance)
        // mapView.centerCoordinate = CLLocationCoordinate2D(
        //     latitude: options.initialCoordinates.latitude,
        //     longitude: options.initialCoordinates.longitude)
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
        super.viewDidDisappear(animated)
        if promise != nil && options.rejectOnCancel {
            promise?.reject("dismissed", "Modal closed by user")
        }
    }

    // MARK: - Navigation bar buttons methods
    @objc private func pickUserLocation() {
        shouldCenterMapOnUserLocationUpdate = true  // Set flag to true before requesting location
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
                    // Ensure search bar placeholder text color is readable
                    if #available(iOS 13.0, *) {
                        self.searchTextField.attributedPlaceholder = NSAttributedString(
                            string: self.options.searchPlaceholder,
                            attributes: [.foregroundColor: UIColor.secondaryLabel])
                    } else {
                        self.searchTextField.placeholder =
                            self.options.searchPlaceholder
                    }
                    return
                }
                self.lastLocation = location?.first
                if let name = location?.first?.name {
                    if #available(iOS 13.0, *) {
                        self.searchTextField.attributedPlaceholder = NSAttributedString(
                            string: name, attributes: [.foregroundColor: UIColor.secondaryLabel]
                        )
                    } else {
                        self.searchTextField.placeholder = name
                    }
                } else {
                    if #available(iOS 13.0, *) {
                        self.searchTextField.attributedPlaceholder = NSAttributedString(
                            string: self.options.searchPlaceholder,
                            attributes: [.foregroundColor: UIColor.secondaryLabel])
                    } else {
                        self.searchTextField.placeholder =
                            self.options.searchPlaceholder
                    }
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

// Removed: extension PlacePickerViewController: UISearchBarDelegate

extension PlacePickerViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Only center the map if explicitly requested by the user tapping the location button
        if shouldCenterMapOnUserLocationUpdate, let coordinate = locations.first?.coordinate {
            mapView.setCenter(coordinate, animated: true)
            shouldCenterMapOnUserLocationUpdate = false  // Reset the flag after centering
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
        shouldCenterMapOnUserLocationUpdate = false  // Reset flag on failure
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
                // When a place is selected, explicitly center the map on that location
                self?.mapView.setCenter(coords, animated: true)
                self?.searchTextField.text = ""
                self?.searchTextField.resignFirstResponder()  // Dismiss keyboard
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

// Removed: extension PlacePickerViewController: UISearchResultsUpdating

extension PlacePickerViewController: UITextFieldDelegate {
    @objc private func searchTextFieldDidChange(_ textField: UITextField) {
        if let searchText = textField.text, !searchText.isEmpty {
            completer.queryFragment = searchText
        } else {
            completerResults.removeAll()
        }
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        searchResultContainer.isHidden =
            completerResults.count < 1 && textField.text?.isEmpty ?? true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        searchResultContainer.isHidden = true
        completerResults.removeAll()  // Clear results when editing ends
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()  // Dismiss keyboard on return
        // You could also trigger a full search here if desired
        return true
    }
}
