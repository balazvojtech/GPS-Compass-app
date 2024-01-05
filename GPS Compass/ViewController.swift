import UIKit
import CoreLocation
import CoreMotion

class ViewController: UIViewController {

    @IBOutlet weak var latitudeTextField: UITextField!
    @IBOutlet weak var longitudeTextField: UITextField!
    @IBOutlet weak var arrowImageView: UIImageView!
    @IBOutlet var distanceLabel: UILabel!
    @IBOutlet weak var myAltitudeLabel: UILabel!
    @IBOutlet var distanceImage: UIImageView!
    @IBOutlet var altitudeImage: UIImageView!
    @IBOutlet var timezoneLabel: UILabel!
    @IBOutlet var headingDirectionLabel: UILabel!
    @IBOutlet var timezoneImage: UIImageView!
    @IBOutlet var directionImage: UIImageView!
    @IBOutlet var stateLabel: UILabel!
    
    var destinationCoordinate: CLLocationCoordinate2D?
    let motionManager = CMMotionManager()

    private let locationManager = CLLocationManager()

    private var myCoordinates: CLLocationCoordinate2D? = nil
    private var initialNorthAngle: CGFloat = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()
        latitudeTextField.delegate = self
        longitudeTextField.delegate = self
        startDeviceMotionUpdates()

        // Set background text for the text fields
        latitudeTextField.placeholder = "Insert latitude"
        longitudeTextField.placeholder = "Insert longitude"
        
        updateInterfaceForCurrentTraitCollection()

        locationManager.delegate = self
        locationManager.startUpdatingHeading() // Add this line to start heading updates
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.async {
            self.checkLocationServices()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateInterfaceForCurrentTraitCollection()
            updateAltitudeImageForCurrentTraitCollection()
        }
    }

    func updateInterfaceForCurrentTraitCollection() {
        if traitCollection.userInterfaceStyle == .dark {
            // Switch to the dark mode image for distance
            distanceImage.image = UIImage(named: "distanceDarkMode")
            // Use the same image for both dark and light mode for timezone
            timezoneImage.image = UIImage(named: "timezoneDarkMode")
            // Switch to the dark mode image for direction
            directionImage.image = UIImage(named: "directionDarkMode")
        } else {
            // Switch to the original image for distance in light mode
            distanceImage.image = UIImage(named: "distanceLightMode")
            // Use the same image for both dark and light mode for timezone
            timezoneImage.image = UIImage(named: "timezoneLightMode")
            // Switch to the original image for direction in light mode
            directionImage.image = UIImage(named: "directionLightMode")
        }
    }

    func updateAltitudeImageForCurrentTraitCollection() {
        if traitCollection.userInterfaceStyle == .dark {
            // Switch to the dark mode image for altitude
            altitudeImage.image = UIImage(named: "altitudeDarkMode")
        } else {
            // Switch to the original image for altitude in light mode
            altitudeImage.image = UIImage(named: "altitudeLightMode")
        }
    }

    func checkLocationServices() {
        locationManager.delegate = self

        let authorizationStatus = locationManager.authorizationStatus

        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            DispatchQueue.main.async {
                self.locationManager.startUpdatingLocation()
            }
        case .denied, .restricted:
            // Handle case where location services are denied or restricted
            displayErrorAlert(message: "Location services are not authorized.")
        @unknown default:
            fatalError("Unhandled authorization status.")
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        motionManager.stopDeviceMotionUpdates()
    }

    @IBAction func confirmButtonTapped(_ sender: UIButton) {
        validateCoordinates()
    }

    func getTimeDifference(from sourceTimeZone: TimeZone, to destinationTimeZone: TimeZone) -> String {
        let sourceOffset = sourceTimeZone.secondsFromGMT()
        let destinationOffset = destinationTimeZone.secondsFromGMT()

        let difference = (destinationOffset - sourceOffset) / 3600

        if difference > 0 {
            return String(format: "Timezone: +%d hours", difference)
        } else if difference < 0 {
            return String(format: "Timezone: %d hours", difference)
        } else {
            return "Same time zone"
        }
    }

    func getTimeZone(for coordinates: CLLocationCoordinate2D, completionHandler: @escaping (TimeZone?) -> Void) {
        let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Reverse geocoding error: \(error.localizedDescription)")
                completionHandler(nil)
                return
            }

            guard let placemark = placemarks?.first else {
                print("No placemark found for the given coordinates.")
                completionHandler(nil)
                return
            }

            if let timeZone = placemark.timeZone {
                let userTimeZone = TimeZone.current
                let timeDifference = self.getTimeDifference(from: userTimeZone, to: timeZone)

                print("Time Difference: \(timeDifference)")
                completionHandler(timeZone)
            } else {
                print("No time zone information available.")
                completionHandler(nil)
            }
        }
    }

    private var myAngle: Double = 0.0

    func validateCoordinates() {
        guard
            let latitudeText = latitudeTextField.text, !latitudeText.isEmpty,
            let longitudeText = longitudeTextField.text, !longitudeText.isEmpty
        else {
            // Handle empty fields
            displayErrorAlert(message: "Invalid coordinates. Please enter valid latitude and longitude.")
            return
        }

        let latitude = (latitudeText as NSString).doubleValue
        let longitude = (longitudeText as NSString).doubleValue

        guard CLLocationCoordinate2DIsValid(CLLocationCoordinate2D(latitude: latitude, longitude: longitude)) else {
            // Handle invalid coordinates
            displayErrorAlert(message: "Invalid coordinates. Please enter valid latitude and longitude.")
            return
        }

        destinationCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

        view.endEditing(true)

        guard let destinationCoord = destinationCoordinate else {
            displayErrorAlert(message: "Destination coordinates not set.")
            return
        }

        startDeviceMotionUpdates()

        if let myCoord = self.myCoordinates {
            self.myAngle = calculateAngle(from: myCoord, to: destinationCoord)
        }
    }

    func displayErrorAlert(message: String) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }

    func startDeviceMotionUpdates() {
            if motionManager.isDeviceMotionAvailable {
                motionManager.deviceMotionUpdateInterval = 0.01
                motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
                    guard let self = self else { return }

                    if let error = error {
                        print("Error updating device motion: \(error.localizedDescription)")
                        return
                    }

                    guard motion != nil else {
                        print("Motion data is nil.")
                        return
                    }

                    // Check if heading and location data are available
                    guard let heading = self.locationManager.heading?.trueHeading,
                          let destinationCoord = self.destinationCoordinate,
                          let myCoord = self.myCoordinates else {
                        print("Location or heading data is nil.")
                        return
                    }

                    let bearing = self.calculateBearing(from: myCoord, to: destinationCoord)
                    let angleFromNorth = bearing - CGFloat(heading)
                    self.updateArrowRotation(adjustedAngle: angleFromNorth)
                }
            } else {
                print("Device motion is not available")
            }
        }

    func updateArrowRotation(adjustedAngle: CGFloat) {
        // Convert degrees to radians
        let rotationAngleInRadians = adjustedAngle * CGFloat.pi / 180.0

        print("Adjusted Angle: \(adjustedAngle)")
        print("Rotation Angle (Radians): \(rotationAngleInRadians)")

        let rotationTransform = CGAffineTransform(rotationAngle: rotationAngleInRadians)
        arrowImageView.transform = rotationTransform
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        // You can add additional validation logic here if needed
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Handle authorization changes
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            print("Location data is nil.")
            return
        }
        
        self.myCoordinates = location.coordinate
        
        guard let destinationCoord = destinationCoordinate, let myCoord = self.myCoordinates else {
            print("Destination coordinates or my coordinates are nil.")
            return
        }
        
        if self.initialNorthAngle == 0.0 {
            self.initialNorthAngle = self.calculateAngleFromNorth(heading: locationManager.heading?.trueHeading ?? 0.0,
                                                                  destinationCoord: destinationCoord,
                                                                  myCoord: myCoord)
        }
        
        // Calculate distance
        let distance = calculateDistance(from: myCoord, to: destinationCoord)
        
        // Format distance based on magnitude
        let formattedDistance: String
        if distance < 1000.0 {
            formattedDistance = String(format: "%.0f meters", distance)
        } else {
            formattedDistance = String(format: "%.1f kilometers", distance / 1000.0)
        }
        
        // Display altitude information in the label
        let myAltitudeText = String(format: "My Altitude: %.0f meters", location.altitude)
        
        // Get destination timezone and update label
        getTimeZone(for: destinationCoord) { timeZone in
            DispatchQueue.main.async {
                if let timeZone = timeZone {
                    let timeDifference = self.getTimeDifference(from: TimeZone.current, to: timeZone)
                    self.timezoneLabel.text = "\(timeDifference)"
                } else {
                    self.timezoneLabel.text = "Unknown"
                }
            }
        }
        
        // Update heading direction and label
        if let heading = locationManager.heading?.trueHeading {
            let headingDirection = calculateHeadingDirection(heading: heading)
            headingDirectionLabel.text = "Direction: \(headingDirection)"
        }
        
        // Update labels
        distanceLabel.text = "Distance: \(formattedDistance)"
        myAltitudeLabel.text = myAltitudeText
        
        print("Updated location: \(location.coordinate)")
        print("My Altitude: \(location.altitude) meters")
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Update heading direction when a new heading is available
        if let heading = locationManager.heading?.trueHeading {
            let headingDirection = calculateHeadingDirection(heading: heading)
            headingDirectionLabel.text = "Direction: \(headingDirection)"
        }
    }
}

func calculateHeadingDirection(heading: CLLocationDirection) -> String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW", "N"]

        let index = Int((heading + 22.5) / 45.0) & 7
        return directions[index]
    }

extension ViewController {
    func calculateBearing(from sourceCoordinate: CLLocationCoordinate2D, to destinationCoordinate: CLLocationCoordinate2D) -> CLLocationDirection {
        let lat1 = sourceCoordinate.latitude.toRadians()
        let lon1 = sourceCoordinate.longitude.toRadians()
        let lat2 = destinationCoordinate.latitude.toRadians()
        let lon2 = destinationCoordinate.longitude.toRadians()

        let deltaLon = lon2 - lon1

        let x = sin(deltaLon) * cos(lat2)
        let y = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)

        let bearing = atan2(x, y)

        return bearing.toDegrees().normalizedDegree()
    }

    func calculateAngleFromNorth(heading: CLLocationDirection, destinationCoord: CLLocationCoordinate2D, myCoord: CLLocationCoordinate2D) -> CGFloat {
        let bearing = self.calculateBearing(from: myCoord, to: destinationCoord)
        let angleFromNorth = bearing - CGFloat(heading)
        return angleFromNorth
    }

    func calculateAngle(from sourceCoordinate: CLLocationCoordinate2D, to destinationCoordinate: CLLocationCoordinate2D) -> CGFloat {
        let deltaX = destinationCoordinate.longitude - sourceCoordinate.longitude
        let deltaY = destinationCoordinate.latitude - sourceCoordinate.latitude

        let angle = atan2(deltaY, deltaX)
        let angleInDegrees = angle * (180.0 / CGFloat.pi)
        let positiveAngle = (angleInDegrees + 360).truncatingRemainder(dividingBy: 360)

        return positiveAngle
    }
}

extension Double {
    func toRadians() -> Double {
        return self * .pi / 180.0
    }

    func toDegrees() -> Double {
        return self * 180.0 / .pi
    }
}

extension CLLocationDirection {
    func normalizedDegree() -> CLLocationDirection {
        return (self + 360.0).truncatingRemainder(dividingBy: 360.0)
    }
}

func calculateDistance(from sourceCoordinate: CLLocationCoordinate2D, to destinationCoordinate: CLLocationCoordinate2D) -> CLLocationDistance {
    let R = 6371000.0 // Earth radius in meters

    let dLat = (destinationCoordinate.latitude - sourceCoordinate.latitude).toRadians()
    let dLon = (destinationCoordinate.longitude - sourceCoordinate.longitude).toRadians()

    let a = sin(dLat/2) * sin(dLat/2) + cos(sourceCoordinate.latitude.toRadians()) * cos(destinationCoordinate.latitude.toRadians()) * sin(dLon/2) * sin(dLon/2)
    let c = 2 * atan2(sqrt(a), sqrt(1-a))

    let distance = R * c
    return distance
}
