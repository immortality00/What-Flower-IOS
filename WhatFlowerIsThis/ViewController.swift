//
//  ViewController.swift
//  WhatFlowerIsThis
//
//  Created by Hussain Radhi on 8/9/18.
//  Copyright © 2018 Hussain Radhi. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var lable: UILabel!
    @IBOutlet weak var background: UIImageView!
    
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .camera
        background.isHidden = false
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            guard let convertedCIImage = CIImage(image: userPickedImage) else {fatalError("cannot convert to CIImage")}
            detect(image: convertedCIImage)
            
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(image: CIImage){
        guard let model = try? VNCoreMLModel(for: flowerCLassifier().model) else {fatalError("Cannot import model")}
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let classification = request.results?.first as? VNClassificationObservation else {fatalError("Could not classify the image")}
            self.navigationItem.title = classification.identifier.capitalized
            self.requestInfo(flowerName: classification.identifier)
        }
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
        
    }
    
    func requestInfo(flowerName: String) {
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
            ]
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
                print("Got the wikipedia info")
                print(response)
                
                let flowerJSON : JSON = JSON(response.result.value!)
                let pageID = flowerJSON["query"]["pageids"][0].stringValue
                let flowerDescription = flowerJSON["query"]["pages"][pageID]["extract"].stringValue
                let flowerImageURL = flowerJSON["query"]["pages"][pageID]["thumbnail"]["source"].stringValue
                
                self.lable.text = flowerDescription
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
                
            }
        }
    }

    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        background.isHidden = true
        present(imagePicker, animated: true, completion: nil)
        
    }
    
}

