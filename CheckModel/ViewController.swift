//
//  ViewController.swift
//  CheckModel
//
//  Created by Rajesh on 08/07/21.
//  Copyright © 2021 Rajesh. All rights reserved.
//

import CoreML
import Vision
import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageChosen: UIImageView!
    @IBOutlet weak var resultlabel: UILabel!
    
    let imagePicker = UIImagePickerController()
    
  
    // 1
    private lazy var classificationRequest: VNCoreMLRequest = {
      do {
        // 2
        let model = try VNCoreMLModel(for: ImageClassifier().model)
        // 3        
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let self = self else {
              return
          }
          self.processClassifications(for: request, error: error)
        }
        
        // 4
        request.imageCropAndScaleOption = .centerCrop
        return request
      } catch {
        // 5
        fatalError("Failed to load Vision ML model: \(error)")
      }
    }()
    
    
    func classifyImage(_ image: UIImage) {
      // 1
      guard let orientation = CGImagePropertyOrientation(
        rawValue: UInt32(image.imageOrientation.rawValue)) else {
        return
      }
      guard let ciImage = CIImage(image: image) else {
        fatalError("Unable to create \(CIImage.self) from \(image).")
      }
      // 2
      DispatchQueue.global(qos: .userInitiated).async {
        let handler =
          VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
        do {
          try handler.perform([self.classificationRequest])
        } catch {
          print("Failed to perform classification.\n\(error.localizedDescription)")
        }
      }
    }
    
    
    func processClassifications(for request: VNRequest, error: Error?) {
      DispatchQueue.main.async {
        // 1
        if let classifications =
          request.results as? [VNClassificationObservation] {
          if classifications.isEmpty {
             self.resultlabel.text = "Nothing recognized."
           } else {
             let topClassifications = classifications.prefix(2)
            let descriptions = topClassifications.map { classification in
                
                return classification.confidence == 1 ? String(format: "%@", classification.identifier) : String(format: "%@", "")
                
            }
            
            
            print(classifications)
            
            self.resultlabel.text = descriptions.joined(separator: "")
            
            if(self.resultlabel.text == "") {
                self.resultlabel.text = "Not able to recognize"
            }
            
          }
            
          
        }
      }
    }


    

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
            classifyImage(pickedImage)
            self.resultlabel.text = "Classifying..."
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }

    
 
}
