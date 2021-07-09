//
//  DemoController.swift
//  CheckModel
//
//  Created by Rajesh on 08/07/21.
//  Copyright © 2021 Rajesh. All rights reserved.
//

import CoreML
import Vision
import UIKit

class DemoViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageChosen: UIImageView!
    @IBOutlet weak var resultlabel: UILabel!
    
    let imagePicker = UIImagePickerController()
    
    lazy var classificationRequest: VNCoreMLRequest = {
    do {
       let model = try VNCoreMLModel(for: ImageClassifier().model)
       let request = VNCoreMLRequest(model: model, completionHandler: {   [weak self] request, error in
             self?.processClassifications(for: request, error: error)
    })
       request.imageCropAndScaleOption = .centerCrop
       return request
    } catch {
       fatalError("Failed to load Vision ML model: \(error)")
    }}()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        imagePicker.delegate = self
    }


    @IBAction func chooseImage(_ sender: Any) {
        
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: - UIImagePickerControllerDelegate Methods
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageChosen.contentMode = .scaleAspectFit
            imageChosen.image = pickedImage
            createClassificationsRequest(for: pickedImage)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func createClassificationsRequest(for image: UIImage) {
        
        resultlabel.text = "Classifying..."
        let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue))!
        guard let ciImage = CIImage(image: image)
        else {
          fatalError("Unable to create \(CIImage.self) from \(image).")
        }
            
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
           do {
            try handler.perform([self.classificationRequest])
           }catch {
            print("Failed to perform \n\(error.localizedDescription)")
           }
        }
        
    }
    
    func processClassifications(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
           guard let results = request.results
            
           else {
             self.resultlabel.text = "Unable to classify image.\n\(error!.localizedDescription)"
             return
           }
            
           let classifications = results as! [VNClassificationObservation]
           if classifications.isEmpty {
             self.resultlabel.text = "Nothing recognized."
           } else {
             let topClassifications = classifications.prefix(2)
            let descriptions = topClassifications.map { classification in
                
                return classification.confidence == 1 ? String(format: "%@", classification.identifier) : String(format: "%@", "")
                
            }
            self.resultlabel.text = descriptions.joined(separator: "")
          }
        }
    
    }
}
