import UIKit
import CoreLocation
import CoreMotion

class ViewController: UIViewController {

    @IBOutlet weak var latitudeTextField: UITextField!
    @IBOutlet weak var longitudeTextField: UITextField!
    @IBOutlet weak var arrowImageView: UIImageView!

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

        locationManager.delegate = self
        locationManager.startUpdatingHeading() // Add this line to start heading updates
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        locationManager.requestAlwaysAuthorization()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        motionManager.stopDeviceMotionUpdates()
    }

    @IBAction func confirmButtonTapped(_ sender: UIButton) {
        validateCoordinates()
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
                guard let self = self, let motion = motion, error == nil else {
                    print("Error updating device motion: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                // Check if heading and location data are available
                guard let heading = self.locationManager.heading?.trueHeading,
                      let destinationCoord = self.destinationCoordinate,
                      let myCoord = self.myCoordinates else {
                    print("Location or heading data is nil.")
                    
                    if let heading = self.locationManager.heading {
                        print("Heading data: \(heading)")
                    }
                    
                    if let destinationCoord = self.destinationCoordinate {
                        print("Destination Coordinate data: \(destinationCoord)")
                    }
                    
                    if let myCoord = self.myCoordinates {
                        print("My Coordinate data: \(myCoord)")
                    }

                    return
                }

                // Check if the initialNorthAngle needs to be calculated
                if self.initialNorthAngle == 0.0 {
                    self.initialNorthAngle = self.calculateAngleFromNorth(heading: heading, destinationCoord: destinationCoord, myCoord: myCoord)
                }

                let angleFromNorth = self.calculateAngleFromNorth(heading: heading, destinationCoord: destinationCoord, myCoord: myCoord)
                let adjustedAngle = angleFromNorth - self.initialNorthAngle
                self.updateArrowRotation(adjustedAngle: adjustedAngle)
            }
        } else {
            print("Device motion is not available")
        }
    }


    func updateArrowRotation(adjustedAngle: CGFloat) {
        print("Adjusted Angle: \(adjustedAngle)")
        let rotationTransform = CGAffineTransform(rotationAngle: adjustedAngle)
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
        guard let location = locations.first?.coordinate else {
            print("Location data is nil.")
            return
        }

        self.myCoordinates = location

        guard let destinationCoord = destinationCoordinate, let myCoord = self.myCoordinates else {
            print("Destination coordinates or my coordinates are nil.")
            return
        }

        if self.initialNorthAngle == 0.0 {
            self.initialNorthAngle = self.calculateAngleFromNorth(heading: locationManager.heading?.trueHeading ?? 0.0,
                                                                  destinationCoord: destinationCoord,
                                                                  myCoord: myCoord)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
    }
}

extension ViewController {
    func calculateAngleFromNorth(heading: CLLocationDirection, destinationCoord: CLLocationCoordinate2D, myCoord: CLLocationCoordinate2D) -> CGFloat {
        let angleToDestination = calculateAngle(from: myCoord, to: destinationCoord)
        let angleFromNorth = angleToDestination - CGFloat(heading)
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
