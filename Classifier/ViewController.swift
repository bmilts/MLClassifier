//
//  ViewController.swift
//  Classifier
//
//  Created by Brendan Milton on 29/06/2019.
//  Copyright © 2019 Brendan Milton. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    


    let imagePicker = UIImagePickerController()

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .camera
    }
    

    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
        
            guard let convertedCIImage = CIImage(image: userPickedImage) else {
                
                fatalError("Could not convert image to CIImage.")
                
            }
        
            detect(image: convertedCIImage)
            
        // Sets image view to user taken image
        //imageView.image = userPickedImage
        
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    // Detect issue with image
    func detect(image: CIImage){
        
        // Vision container for ML Model
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            
            fatalError("Cannot import model")
        }
        
        // Request to core data
        let request = VNCoreMLRequest(model: model) { (request, error) in
            
            guard let classification = request.results?.first as? VNClassificationObservation else
                {fatalError("Could not classify image.")
    
            }
            
            // Describes what flower/cable/disease is
            self.navigationItem.title = classification.identifier.capitalized
            
            self.requestInfo(objectName: classification.identifier)
            
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
        
        
    }
    
    func requestInfo(objectName: String){
        
        // & Json objects returned
        // "" returns information about object for display
        // All going well will change search based on object
        
        // Added SDWebImage to extract image in thumbsize 500
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : objectName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
        ]
        
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON
            { (response) in
                
                if response.result.isSuccess {
                    print("Got the wikipedia info.")
                    print(response)
                }
                
                // Safe to unwrap due to alamofire success
                let objectJSON : JSON = JSON(response.result.value!)
                
                // Retrieve page ID
                let pageid = objectJSON["query"]["pageids"][0].stringValue
                
                // Retrieve object extract or description
                let objectDescription = objectJSON["query"]["pages"][pageid]["extract"].stringValue
                
                let objectImageURL = objectJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                
                self.imageView.sd_setImage(with: URL(string: objectImageURL))
                
                self.label.text = objectDescription
        }
    }

    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        
        present(imagePicker, animated: true, completion: nil)
    }
    
}

