//
//  TableController.swift
//  3DMED
//
//  Created by Paolo Speziali and Marcelo Levano on 18/09/17.
//

import UIKit
import NVActivityIndicatorView
import Kingfisher

var firstTime = true // Se true allora è la prima volta che si arriva alla tableView
var devicesPrecedente = [Device]() // Array di Device utile all'allocazione dei dati ricavati dal JSON ottenuto dalla chiamata fatta con Alamofire

struct Device {
    var category: String = ""
    var model: String = ""
    var available: String = "" // Se il valore è '1' allora è disponibile, se '0' allora no
    var price: String = ""
    var description: String = ""
    var image: String = "http://i.imgur.com/fm6Z9OF.jpg"
    var imageX: ImageView = ImageView()
}

class TableController: UITableViewController, NVActivityIndicatorViewable {
    
    @IBOutlet var listaModelli: UITableView!
    let size = CGSize(width: 30, height: 30)
    var disp = ""
    var check = 0
    let modello = Networking()
    let dealer = CategoryDealer()
    let reach = Reachability()
    var categoria = "" // Categoria di dispositivi da elencare
    var devices = [Device]() // Array di struct che contenente tutti i modelli della categoria selezionata
    var testI = ImageView() // Variabile utile solo al uso del metodo kf.setImage e del suo completionHandler
    var url = "http://i.imgur.com/fm6Z9OF.jpg"
    
    // Settare il numero di right che avrà ogni sezione
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    // Formatta riga della tabella con i deti dell' i-esimo elemento dell'array contenente i dati
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "labelCell", for: indexPath)
        // Formatto la cella con i dati ottenuti dall'array di device
        cell.textLabel?.text = devices[indexPath.row].model
        cell.detailTextLabel?.text = "\(devices[indexPath.row].available) - Price: From \(devices[indexPath.row].price) €"
            
        // Adatta l'immagine del device all'imageView della cella da aggiungere
        cell.imageView?.contentMode = .scaleAspectFit
        // Copia immagine dall'array devices all'imageView della cella
        cell.imageView?.image = devices[indexPath.row].imageX.image
        return cell
    }
    
    // Formatta il nome della sezione con la categoria di dispositivi contenuti nell'array
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "\(categoria)"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Andiamo a togliere l'ulitmo carattere poiché Core ML aggiunge uno spazio alla fine e questo compromette l'uguaglianza tra la categoria predetta e le categorie presenti nel database
        if(categoria != ""){
            categoria.remove(at: categoria.index(before: categoria.endIndex))
        }
        // Controllo se non è disponibile
        if !((reach.manager?.isReachable)!) {
            print("Rete non disponibile!")
            // Creo e mostro un pop-up con lo scopo di indicare la mancanza di connessione ad internet
            let alertController = UIAlertController(title: "No Connection", message:
                "Try again and be sure to be connected!", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Go Back", style: UIAlertActionStyle.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
        else{
            // Inizio Animazione
            self.startAnimating(size, message: "Downloading Data...", type: NVActivityIndicatorType(rawValue: 26))
            //controlla se è la prima volta che entri, in questo caso inizializza la struct che ospita il device precedentemente scannerizzato, questa struct ci servirà nella if successiva a controllare che questo device non sia uguale al device precedente, dato che, in tal caso, non c'è bisogno di riscaricare alcuna informazione
            
            
            
            // Se è la prima volta che si carica questa view allora si aggiunge un elemento all'array di Device VUOTO, in quanto altrimenti il controllo su questo array causerebbe un crash dell'applicazione
            if (firstTime) {
                devicesPrecedente.append(Device())
                firstTime=false
            }
            
            /* CONVERSIONE DA CIBO A DISPOSITIVI APPLE ( SOLO PROVA )
            switch categoria {
            case "churros ":
                categoria="iMac"
            case "hot dog ":
                categoria="MacBook"
            case "sushi ":
                categoria="iPhone"
            case "spaghetti bolognese ":
                categoria="iPad"
            case "french fries ":
                categoria="Mac mini"
            case "donuts ":
                categoria="Mac Pro"
            default:
                categoria="Apple TV"
            }*/
            
            
            // Se la categoria selezionata non è uguale alla categoria precedente, procedere alla richiesta del JSON contenente le informazioni dei device
            if (categoria != devicesPrecedente[0].category) {
                controllaValidita()
            }
            else { // Altrimenti copiare l'array contenente i dati precedenti su quello che si userà per popolare la tableView
                self.devices = devicesPrecedente
                self.tableView.reloadData()
                self.stopAnimating()
            }
        }
    }
    
    func controllaValidita() {
        // Booleana di controllo che si attiva quando viene trovata la categoria a cui l'oggetto appartiene
        check = 0
        // Inizializzazione della struct devicePrecedente per poi ripopolarla con la struct del device attuale in seguito
        devicesPrecedente.removeAll()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        //
        dealer.request(){ (results) in
            var jsonResult : Dictionary<String, AnyObject>
            for i in results {
                jsonResult = i as! Dictionary<String, AnyObject>
                if(String(describing: jsonResult["category"]!)==self.categoria){
                    self.scaricaJson()
                    self.check=1
                }
                if(self.check==1){
                    break
                }
                
            }
            self.stopAnimating()
        }
    }
    
    func scaricaJson () {
        self.modello.request(prediction: self.categoria) { (results) in
            var jsonResult : Dictionary<String, AnyObject>
            var nImageDevice = 0 // Variabile che conta il numero del elemento dell'array al quale corrisponde l'immagine appena scaricata ( necessario in quanato il download dell'immagione è asincrono )
            var nModelli = results.count // Numero modelli che necessitano di cui è necessario scaricare l'immagine
            for i in results {
                self.tableView.reloadData()
                
                // Prendo l' i-esimo elemento del JSON
                jsonResult = i as! Dictionary<String, AnyObject>
                
                // popola la struct device aggiungi la struct device all'array di devices
                self.devices.append(self.creaStruct(jsonResult:jsonResult))
                self.url = String(describing: "\(jsonResult["image"]!)")
                
                // Scarica l'immagine tramite l'url preso dal JSON
                self.testI.kf.setImage(with: URL(string: self.url), completionHandler: { (image, error, cacheType, imageUrl) in
                    
                    
                    // aggiungi la struct device all'array di devices
                    self.devices[nImageDevice].imageX.image = image
                    
                    // CODICE UTILE SOLO PER IL CONTROLLO
                    nModelli = nModelli - 1
                    print("\naggiungo immagine del dispoditivo nr \(nImageDevice)")
                    print("\ncreastruct - elementi rimasti da scaricare: \(nModelli)")
                    
                    // Se gli elementi da caricare sono finiti ferma l'animazione di caricamento e ricarico la tableView
                    if(nModelli == 0) {
                        self.tableView.reloadData()
                        self.stopAnimating()
                    }
                    nImageDevice = nImageDevice + 1 // Incremento il contatore
                })
            }
            
            // Copio l'array di Devices all'array 'devicesPrecedente' per ri-usarlo in caso si richiedano dispositivi della stessa categoria
            devicesPrecedente=self.devices
        }
    }
    
    // ritorna struct contenete i dati del elemento JSON
    func creaStruct(jsonResult : Dictionary<String, AnyObject>) -> Device {
        var deviceStruct = Device()
        
        // Popolo la struct che la funzione dovrà ritornare con i dati del JSON
        deviceStruct.model = "\(jsonResult["model"]!)"
        deviceStruct.category = "\(jsonResult["category"]!)"
        if (String(describing: jsonResult["available"]!)=="1"){
            deviceStruct.available = "Available"
        }
        else {
            deviceStruct.available = "Unavailable"
        }
        deviceStruct.price = "\(jsonResult["price"]!)"
        deviceStruct.description = "\(jsonResult["description"]!)"
        deviceStruct.image = "\(jsonResult["image"]!)"
        
        return deviceStruct
    }
    
    
    override func prepare( for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination as? InfoController
        destination?.outputInfo = devices[(listaModelli.indexPathForSelectedRow?.row)!]
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}



