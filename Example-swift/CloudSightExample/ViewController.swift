//
//  ViewController.swift
//  CloudSightExample
//

import UIKit
import CloudSight

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CloudSightQueryDelegate {

    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    var cloudsightQuery: CloudSightQuery!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        CloudSightConnection.sharedInstance().consumerKey = "your-key";
        CloudSightConnection.sharedInstance().consumerSecret = "your-secret";
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func cameraButtonPressed(_ sender: Any) {

        // Check to see if the Camera is available
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            let imagePicker = UIImagePickerController()

            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.camera
            imagePicker.allowsEditing = false

            // Show the UIImagePickerController view
            self.present(imagePicker, animated: true, completion: nil)
        } else {
            print("Cannot access the camera");
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // Dismiss the UIImagePickerController
        self.dismiss(animated: true, completion: nil)
        
        // Assign the image reference to the image view to display
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        imageView.image = image
        
        // Create JPG image data from UIImage
        let imageData = UIImageJPEGRepresentation(image, 0.8)
        
        cloudsightQuery = CloudSightQuery(image: imageData,
                                          atLocation: CGPoint.zero,
                                          withDelegate: self,
                                          atPlacemark: nil,
                                          withDeviceId: "device-id")
        cloudsightQuery.start()
        activityIndicatorView.startAnimating()
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func cloudSightQueryDidFinishUploading(_ query: CloudSightQuery!) {
        print("cloudSightQueryDidFinishUploading")
    }
    
    func cloudSightQueryDidFinishIdentifying(_ query: CloudSightQuery!) {
        print("cloudSightQueryDidFinishIdentifying")

        // CloudSight runs in a background thread, and since we're only
        // allowed to update UI in the main thread, let's make sure it does.
        DispatchQueue.main.async {
            self.resultLabel.text = query.name()
            self.activityIndicatorView.stopAnimating()
        }
    }
    
    func cloudSightQueryDidFail(_ query: CloudSightQuery!, withError error: Error!) {
        print("CloudSight Failure: \(error)")
    }
}
