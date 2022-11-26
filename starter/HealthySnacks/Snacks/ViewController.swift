import UIKit
import Vision

class ViewController: UIViewController {
  
  @IBOutlet var imageView: UIImageView!
  @IBOutlet var cameraButton: UIButton!
  @IBOutlet var photoLibraryButton: UIButton!
  @IBOutlet var resultsView: UIView!
  @IBOutlet var resultsLabel: UILabel!
  @IBOutlet var resultsConstraint: NSLayoutConstraint!

  var firstTime = true

  //TODO: define a VNCoreMLRequest
    lazy var classificationRequest_1: VNCoreMLRequest = {
            do{
                let classifier = healthy()
                let model = try VNCoreMLModel(for: classifier.model)
                let request = VNCoreMLRequest(model: model, completionHandler: {
                    [weak self] request,error in
                    self?.processObservations(for: request, error: error)
                })
                request.imageCropAndScaleOption = .centerCrop
                return request
            } catch {
                fatalError("Failed to create request")
            }
        }()
    
    lazy var classificationRequest_2: VNCoreMLRequest = {
            do{
                //let classifier = snacks()
                print("flag1")
                let classifier = my_net_2()
                print("flag2")
                let model = try VNCoreMLModel(for: classifier.model)
                print("flag3")
                let request = VNCoreMLRequest(model: model, completionHandler: {
                    [weak self] request,error in
                    self?.processObservations(for: request, error: error)
                })
                request.imageCropAndScaleOption = .centerCrop
                return request
            } catch {
                fatalError("Failed to create request,ERROR: \(error)")
            }
        }()
    
  override func viewDidLoad() {
    super.viewDidLoad()
    cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
      resultsView.alpha = 0
    resultsLabel.text = "choose or take a photo"
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    // Show the "choose or take a photo" hint when the app is opened.
    if firstTime {
      showResultsView(delay: 0.5)
      firstTime = false
    }
  }
  
  @IBAction func takePicture() {
    presentPhotoPicker(sourceType: .camera)
  }

  @IBAction func choosePhoto() {
    presentPhotoPicker(sourceType: .photoLibrary)
  }

  func presentPhotoPicker(sourceType: UIImagePickerController.SourceType) {
    let picker = UIImagePickerController()
    picker.delegate = self
    picker.sourceType = sourceType
    present(picker, animated: true)
    hideResultsView()
  }

  func showResultsView(delay: TimeInterval = 0.1) {
    resultsConstraint.constant = 100
    view.layoutIfNeeded()//Use this method to force the view to update its layout immediately.

    UIView.animate(withDuration: 0.5,
                   delay: delay,
                   usingSpringWithDamping: 0.6,
                   initialSpringVelocity: 0.6,
                   options: .beginFromCurrentState,
                   animations: {
      self.resultsView.alpha = 1
      self.resultsConstraint.constant = -10
      self.view.layoutIfNeeded()
    },
    completion: nil)
  }

  func hideResultsView() {
    UIView.animate(withDuration: 0.3) {
      self.resultsView.alpha = 0
    }
      resultsLabel.text?.removeAll()
  }

  func classify(image: UIImage) {
      //TODO: use VNImageRequestHandler to perform a classification request
      guard let ciimage = CIImage(image: image) else{
          print("cant create CIImage!")
          return
      }
      let orientation = CGImagePropertyOrientation(image.imageOrientation)
      DispatchQueue.global(qos: .userInitiated).async {
          let handler = VNImageRequestHandler(ciImage: ciimage, orientation: orientation)
          do{
              try handler.perform([self.classificationRequest_1])
              try handler.perform([self.classificationRequest_2])
          } catch{
              print("failed to perform classification: \(error)")
          }
      }
  }

  //TODO: define a function like func processObservations(for request: VNRequest, error: Error?)  to process the results from the classification model
func processObservations(for request: VNRequest, error: Error?) {
    DispatchQueue.main.async {
        if let results = request.results as? [VNClassificationObservation] {
            if results.isEmpty {
                self.resultsLabel.text?.append("Nothing found\n")
            } else if results[0].confidence < 0.6{
                if results[0].identifier == "healthy" || results[0].identifier == "unhealthy"{
                    self.resultsLabel.text?.append("healthy?  ")
                }
                else{
                    self.resultsLabel.text?.append("category?  ")
                }
                self.resultsLabel.text?.append("not sure\n")
            } else {
                if results[0].identifier == "healthy" || results[0].identifier == "unhealthy"{
                    self.resultsLabel.text?.append("healthy?  ")
                }
                else{
                    self.resultsLabel.text?.append("category?  ")
                }
                self.resultsLabel.text?.append(String(format: "%@ %.1f%%", results[0].identifier, results[0].confidence * 100)+"\n")
            }
            } else if let error = error {
                self.resultsLabel.text?.append("Error: \(error.localizedDescription)\n")
            }
        self.showResultsView()
    }
}
}


extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    picker.dismiss(animated: true)

	let image = info[.originalImage] as! UIImage
    imageView.image = image

    classify(image: image)
  }
}

