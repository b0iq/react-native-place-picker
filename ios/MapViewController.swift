//
//  MapViewController.swift
//  react-native-place-picker
//
//  Created by b0iq on 17/06/2022.
//

// TODO: Add user search
// TODO: Add user location

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
        let pinImage: UIImageView
        if #available(iOS 13.0, *) {
            pinImage = UIImageView(image: UIImage(systemName: "mappin"))
        } else {
            pinImage = UIImageView(image: UIImage(named: "mappin"))
        }
        pinImage.contentMode = .center
        pinImage.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        pinImage.tintColor = .white
        let pinContainer = UIView(frame: CGRect(x: 5, y: 4, width: 40, height: 40))
        pinContainer.layer.cornerRadius = 20
        pinContainer.backgroundColor = .black
        pinContainer.addSubview(pinImage)
        let heightWidth = 10
        let path = CGMutablePath()
        path.move(to: CGPoint(x:20, y: 43))
        path.addLine(to: CGPoint(x:(heightWidth/2) + 20, y: (heightWidth/2) + 43))
        path.addLine(to: CGPoint(x:heightWidth + 20, y:43))
        path.addLine(to: CGPoint(x:20, y:43))
        let shape = CAShapeLayer()
        shape.path = path
        shape.fillColor = UIColor.black.cgColor
        
        let baseView = UIView()
        
        baseView.layer.insertSublayer(shape, at: 0)
        baseView.addSubview(pinContainer)
        
        baseView.translatesAutoresizingMaskIntoConstraints = false
        return baseView
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

        let customCancelButton = UIButton()
        customCancelButton.tintColor = .gray
        if #available(iOS 13.0, *) {
            let cancelImage = UIImage(systemName: "xmark")
            customCancelButton.setImage(cancelImage, for: .normal)
        } else {
            customCancelButton.setTitle("Cancel", for: .normal)
        }
        
        customCancelButton.addTarget(self, action: #selector(closePicker), for: .touchUpInside)
        
        let customDoneButton = UIButton()
        customDoneButton.tintColor = .gray
        if #available(iOS 13.0, *) {
            let checkImage = UIImage(systemName: "checkmark")
            customDoneButton.setImage(checkImage, for: .normal)
        } else {
            customDoneButton.setTitle("Done", for: .normal)
        }
        
        customDoneButton.addTarget(self, action: #selector(finlizePicker), for: .touchUpInside)
        
        if #available(iOS 15.0, *) {
            customDoneButton.configuration = .gray()
            customCancelButton.configuration = .gray()
        }
        
        let customCancelButtonItem = UIBarButtonItem(customView: customCancelButton)
        let customDoneButtonItem = UIBarButtonItem(customView: customDoneButton)
        
        self.navigationItem.leftBarButtonItem = customCancelButtonItem
        self.navigationItem.rightBarButtonItem = customDoneButtonItem
        
    }
    override func viewDidDisappear(_ animated: Bool) {
        if resolver != nil {
            let coords = mapView.centerCoordinate
            resolver!(["latitude": coords.latitude, "longitude": coords.longitude, "canceled": true])
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        
        
        mapView.delegate = self
        if let coords = coordinates {
            mapView.region = MKCoordinateRegion(center: coords, latitudinalMeters: 1000, longitudinalMeters: 1000)
        }
        
        
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
        resolver = nil
        self.dismiss(animated: true)
    }
    @objc func finlizePicker() {
        if let resolve = resolver {
            let coords = mapView.centerCoordinate
            resolve(["latitude": coords.latitude, "longitude": coords.longitude, "canceled": false])
        }
        resolver = nil
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
