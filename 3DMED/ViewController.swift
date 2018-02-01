//
//  ViewController.swift
//  3DMED
//
//  Created by Paolo Speziali and Marcelo Levano on 18/09/17.
//

import UIKit
import SceneKit
import ARKit
import Vision

class ViewController: UIViewController, ARSCNViewDelegate {
    
    //Prepariamo la scena
    @IBOutlet var imgScope: UIImageView!
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var buttClean: UIButton!
    @IBAction func buttCleanAction(_ sender: UIButton) {
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) -> Void in
            node.removeFromParentNode()
        }
    }
    @IBOutlet var buttShow: UIButton!
    @IBAction func buttShow(_ sender: UIButton) {
        if (passaggio=="") {
            let alertController = UIAlertController(title: "Error!", message:
                "No object has been identified!", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "OK  ", style: UIAlertActionStyle.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
        else{
            performSegue(withIdentifier: "toTable", sender: nil)
        }
    }
    
    let bubbleDepth : Float = 0.01 // Profondità del testo 3D
    var latestPrediction : String = "…" // Ultima predizione del CoreML
    var passaggio : String = "" // Stringa che andrà passata al secondo ViewController
    
    // Prepariamo il CoreML
    var visionRequests = [VNRequest]() // Step 1 di Vision: creazione di una Vision Request
    let dispatchQueueML = DispatchQueue(label: "com.hw.dispatchqueueml") // A Serial Queue
    @IBOutlet weak var debugTextView: UITextView!
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination as? TableController
        destination?.categoria = passaggio
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set button borders
        buttShow.backgroundColor = .clear
        buttShow.layer.cornerRadius = 5
        buttShow.layer.borderWidth = 1
        buttShow.layer.borderColor = UIColor.orange.cgColor
        buttClean.backgroundColor = .clear
        buttClean.layer.cornerRadius = 5
        buttClean.layer.borderWidth = 1
        buttClean.layer.borderColor = UIColor.orange.cgColor
        
        // Set the view's delegate - Default
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information - Default
        sceneView.showsStatistics = true
        
        // Create a new scene - Default
        let scene = SCNScene()
        
        // Set the scene to the view - Default
        sceneView.scene = scene
        
        // Attiva l'illuminazione di default, rendendo il testo 3D di aspetto migliore (da considerare)
        sceneView.autoenablesDefaultLighting = true
        
        // Creazione HUD
        let image = UIImage(named: "scope.png")!
        imgScope = UIImageView(image: image)
        
        // Riconoscimento del tocco dello schermo
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(gestureRecognize:)))
        view.addGestureRecognizer(tapGesture)
        
        
        // Inizializzazione modello Vision
        guard let devices = try? VNCoreMLModel(for: devices().model) else {
            fatalError("Could not load model")
        }
        
        // Inizializzazione della richiesta Vision-CoreML
        let classificationRequest = VNCoreMLRequest(model: devices, completionHandler: classificationCompleteHandler)
        classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop // Taglia l'immagine dal centro dello schermo e la ridimensiona appropriatamente
        visionRequests = [classificationRequest]
        
        // Chiamata del metodo per il loop delle richieste a CoreML
        loopCoreMLUpdate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration - Default
        let configuration = ARWorldTrackingConfiguration()
        
        // Attivazione riconoscimento delle superfici piane
        configuration.planeDetection = .horizontal
        
        // Run the view's session - Default
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session - Default
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use - Default
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            // Do any desired updates to SceneKit here - Default
        }
    }
    
    // MARK: - Status Bar: Hide
    override var prefersStatusBarHidden : Bool {
        return false
    }
    
    // MARK: - Interaction
    
    @objc func handleTap(gestureRecognize: UITapGestureRecognizer) {
        // HIT TEST : REAL WORLD - ovvero la ricerca da parte di ARKit di oggetti nell'immagine
        // Prende il centro dello schermo
        let screenCentre : CGPoint = CGPoint(x: self.sceneView.bounds.midX, y: self.sceneView.bounds.midY)
        // Esegue l'HitTest
        let arHitTestResults : [ARHitTestResult] = sceneView.hitTest(screenCentre, types: [.featurePoint])
        
        if let closestResult = arHitTestResults.first {
            // Prendi le coordinate dell'HitTest
            let transform : matrix_float4x4 = closestResult.worldTransform
            let worldCoord : SCNVector3 = SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            
            // Crea il testo 3D
            let node : SCNNode = createNewBubbleParentNode(latestPrediction)
            self.passaggio = latestPrediction
            sceneView.scene.rootNode.addChildNode(node)
            node.position = worldCoord
        }
    }
    
    // Questi parametri sono in merito alla creazione del testo 3D, il settaggio è già stato eseguito in maniera da evitare quanti più crash dell'applicazione possibili
    func createNewBubbleParentNode(_ text : String) -> SCNNode {
        // Warning: Creating 3D Text is susceptible to crashing. To reduce chances of crashing; reduce number of polygons, letters, smoothness, etc.
        
        // TEXT BILLBOARD CONSTRAINT
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        
        // BUBBLE-TEXT
        let bubble = SCNText(string: text, extrusionDepth: CGFloat(bubbleDepth))
        var font = UIFont(name: "Futura", size: 0.15)
        font = font?.withTraits(traits: .traitBold)
        bubble.font = font
        bubble.alignmentMode = kCAAlignmentCenter
        bubble.firstMaterial?.diffuse.contents = UIColor.orange
        bubble.firstMaterial?.specular.contents = UIColor.white
        bubble.firstMaterial?.isDoubleSided = true
        // bubble.flatness // setting this too low can cause crashes.
        bubble.chamferRadius = CGFloat(bubbleDepth)
        
        // BUBBLE NODE
        let (minBound, maxBound) = bubble.boundingBox
        let bubbleNode = SCNNode(geometry: bubble)
        // Centre Node - to Centre-Bottom point
        bubbleNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2, minBound.y, bubbleDepth/2)
        // Reduce default text size
        bubbleNode.scale = SCNVector3Make(0.1, 0.1, 0.1)
        
        // CENTRE POINT NODE
        let sphere = SCNSphere(radius: 0.005)
        sphere.firstMaterial?.diffuse.contents = UIColor.cyan
        let sphereNode = SCNNode(geometry: sphere)
        
        // BUBBLE PARENT NODE
        let bubbleNodeParent = SCNNode()
        bubbleNodeParent.addChildNode(bubbleNode)
        bubbleNodeParent.addChildNode(sphereNode)
        bubbleNodeParent.constraints = [billboardConstraint]
        
        return bubbleNodeParent
    }
    
    // MARK: - Gestione del CoreML
    
    func loopCoreMLUpdate() {
        // Esegue continuamente CoreML non appena è pronto. (Preventing 'hiccups' in Frame Rate)
        
        dispatchQueueML.async {
            // 1. Aggiorna
            self.updateCoreML()
            
            // 2. La funzione richiama se stessa
            self.loopCoreMLUpdate()
        }
        
    }
    
    func classificationCompleteHandler(request: VNRequest, error: Error?) { //Metodo per ricevere risultati dal modello dopo aver eseguito la richiesta
        // Catch Errors
        if error != nil {
            print("Error: " + (error?.localizedDescription)!)
            return
        }
        guard let observations = request.results else {
            print("No results")
            return
        }
        
        // Get Classifications
        let classifications = observations[0...1] // top 2 results
            .flatMap({ $0 as? VNClassificationObservation })
            .map({ "\($0.identifier) \(String(format:"- %.2f", $0.confidence))" })
            .joined(separator: "\n")
        
        
        DispatchQueue.main.async {
            // Print Classifications
            print(classifications)
            print("--")
            
            // Display Debug Text on screen
            var debugText:String = ""
            debugText += classifications
            //self.debugTextView.text = debugText
            
            // Store the latest prediction
            var objectName:String = "…"
            objectName = classifications.components(separatedBy: "-")[0]
            objectName = objectName.components(separatedBy: ",")[0]
            self.latestPrediction = objectName
            
        }
    }
    
    func updateCoreML() {
        ///////////////////////////
        // Prendi l'immagine in camera come RGB
        let pixbuff : CVPixelBuffer? = (sceneView.session.currentFrame?.capturedImage)
        if pixbuff == nil { return }
        let ciImage = CIImage(cvPixelBuffer: pixbuff!)
        // Potrebbe essere necessario ruotare il PixelBuffer
        
        ///////////////////////////
        // Step 2 di Vision: creazione di un Image Request Handler
        let imageRequestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        // let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage!, orientation: myOrientation, options: [:])
        
        ///////////////////////////
        // Step 3 di Vision: assegnazione immagine all'Image Request Handler
        do {
            try imageRequestHandler.perform(self.visionRequests)
        } catch {
            print(error)
        }
        
    }
    
    ///////////////////////////////////GESTIONE ERRORI///////////////////////////////////
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    
}

extension UIFont {
    // Based on: https://stackoverflow.com/questions/4713236/how-do-i-set-bold-and-italic-on-uilabel-of-iphone-ipad
    func withTraits(traits:UIFontDescriptorSymbolicTraits...) -> UIFont {
        let descriptor = self.fontDescriptor.withSymbolicTraits(UIFontDescriptorSymbolicTraits(traits))
        return UIFont(descriptor: descriptor!, size: 0)
    }
}
