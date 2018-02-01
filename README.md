# Progetto 3DMED

## *Attenzione!*
A causa delle grandi dimensioni del file .mlmodel (ovvero il file database che contiene le foto dei dispositivi Apple in modo che il riconoscimento possa funzionare) non è incluso all'interno della repository di GitHub. È possibile tuttavia [scaricarlo da qui](https://drive.google.com/open?id=1JeWn2qkHzpyoy6by9m9_ioAKusl7oo7K), sarà poi necessario inserirlo nella cartella "3DMED" (non quella di root, bensì la cartella con lo stesso nome al suo interno).

## Obiettivo
Attraverso l’utilizzo della realtà aumentata e del “machine learning”, che permette ai dispositivi di riconoscere, dato un modello che definisce tali, oggetti di ogni tipo l’applicazione permetterà, con l’ausilio della fotocamera esterna, di identificare la categoria di alcuni dispositivi in vendita in un Med Store, posizionare il testo 3D del nome della loro categoria al di sopra di essi e, successivamente, di selezionare il modello desiderato dalla categoria identificata e leggerne specifiche tecniche, prezzo, descrizione e se l’oggetto è disponibile o no.

## Tecnologie utilizzate
- Swift programmato su IDE Xcode 9.0 beta 6 (attualmente unica versione che supporta realtà aumentata e Machine Learning)
- PHP e MySQL su piattaforma Altervista (per la programmazione del database, delle chiamate al database e di ciò che viene restituito all’applicazione)
- ARKit (libreria/tecnologia di Apple per la realtà aumentata)
- CoreML (libreria/tecnologia di Apple per il machine learning)
- AlamoFire (libreria per gestire le chiamate HTML su Swift)
- Kingfisher (libreria per gestire il download di immagini da internet su Swift)
- NVActivityIndicatorView (libreria per gestire le schermate di caricamento su Swift)
- Amazon Web Service con Nvidia DIGITS (per il training e la creazione del modello che stabilisce le categorie a cui possono appartenere gli oggetti che andranno identificati)
- Phyton (per la conversione del modello con formato standard ad un modello supportato da CoreML)

## Codici Utilizzati
Per la realizzazione di alcune parti di codice abbiamo utilizzato codici trovati su internet o già prodotti in precedenza da noi, in particolare:
- [CoreML in Arkit di hanleyweng](https://github.com/hanleyweng/CoreML-in-ARKit)
- App “iDistastri” sviluppata nel corso dell’anno scolastico nei mesi di Aprile-Maggio 2017 da noi e i professori
