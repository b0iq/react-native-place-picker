//
//  MapViewController.swift
//  react-native-place-picker
//
//  Created by b0iq on 17/06/2022.
//

// TODO: Add user search
// TODO: Add user location
// TODO: Add handler button

import UIKit
import MapKit
class MapViewController: UIViewController {
    
    var titleText: String? = "Pick a Place"
    var resolver: RCTPromiseResolveBlock?
    var coordinates: CLLocationCoordinate2D?
    
    init(titleText: String?, coordinates: CLLocationCoordinate2D?, resolver: @escaping RCTPromiseResolveBlock) {
        self.titleText = titleText
        self.resolver = resolver
        self.coordinates = coordinates
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    let mapView: MKMapView = {
        let map = MKMapView()
        map.showsUserLocation   = true
        map.showsBuildings      = true
        map.showsTraffic        = true
        map.showsCompass        = true
        map.showsScale          = true
        map.translatesAutoresizingMaskIntoConstraints = false
        return map
    }()
    
    let mapPin: UIView = {
        let view = UIView()
        // TODO: Add pin image
        view.backgroundColor = UIColor(white: 0, alpha: 0.5)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let mapPinShadow: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.5)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 2.5
        return view
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        if #available(iOS 13, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            navigationController?.navigationBar.standardAppearance = appearance;
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
            navigationController?.navigationBar.isTranslucent = true
        }
    }
    private func setupNavigationBar() {
        let closeStyle: UIBarButtonItem.SystemItem
        if #available(iOS 13.0, *) {
            closeStyle = .close
        } else {
            closeStyle = .cancel
        }
        let dismissButton = UIBarButtonItem(barButtonSystemItem: closeStyle, target: self, action: #selector(closePicker))
        let selectButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(finlizePicker))
        self.navigationItem.leftBarButtonItem = dismissButton
        self.navigationItem.rightBarButtonItem = selectButton
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        if let coords = coordinates {
            mapView.region = MKCoordinateRegion(center: coords, latitudinalMeters: 1000, longitudinalMeters: 1000)
        }
        mapView.delegate = self
        view.addSubview(mapView)
        view.addSubview(mapPinShadow)
        view.addSubview(mapPin)
        NSLayoutConstraint.activate([
            mapPinShadow.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mapPinShadow.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            mapPinShadow.widthAnchor.constraint(equalToConstant: 5),
            mapPinShadow.heightAnchor.constraint(equalToConstant: 5),
            
            mapPin.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mapPin.bottomAnchor.constraint(equalTo: mapPinShadow.topAnchor),
            mapPin.widthAnchor.constraint(equalToConstant: 50),
            mapPin.heightAnchor.constraint(equalToConstant: 50),
            
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
    
    @objc func closePicker() {
        if let resolve = resolver {
            let coords = mapView.centerCoordinate
            resolve(["latitude": coords.latitude, "longitude": coords.longitude, "canceled": true])
        }
        self.dismiss(animated: true)
    }
    @objc func finlizePicker() {
        if let resolve = resolver {
            let coords = mapView.centerCoordinate
            resolve(["latitude": coords.latitude, "longitude": coords.longitude, "canceled": false])
        }
        self.dismiss(animated: true)
    }
    
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
            self.mapPin.transform = CGAffineTransform(translationX: 0, y: 0)
        })
    }
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
            self.mapPin.transform =  CGAffineTransform(translationX: 0, y: -15)
        })
    }
}
