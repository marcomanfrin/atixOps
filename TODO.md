# TODO

## Working
- [ ] nella classe Work 'expectedOfficeHours' ed 'expectedPlantHours' devono diventare float -> di conseguenza tutta la catena fino al frontend
- [ ] Ricerca lavori (cerca principale nella pagina 'works') -> deve essere una ricerca effettiva lato backend, come per i filtri, deve cercare nome lavoro, cliente ed impianto

## UI/UX
- [ ] card lavoro: rendere più visibile il codice (e.g. '2026011') evidenziandolo con colore diverso e/o ingrandendolo
- [ ] rimuovere dalle pagine del lavoro (work_detail, create_work, edit_work...) il campo 'NAS-SubDirectory' Mantenerlo inalterato nel backend 
- [ ] nella pagina 'works' aggiungere un tab 'TUTTI'/'ALL' prima degli altri 3 (aperti, chiusi, non assegnati)
- [ ] nella vista desktop la preview dei pdf deve essere più larga: 90% dello schermo
- [ ] la preview dei pdf non è scrollabile su smartphone con touch screen
- [ ] identificare il limite di dimensione dei file caricabili e segnalarlo nella UI
- [ ] nella sezione 'allegati' la card che rappresenta un allegato deve avere i bottoni elimina e download agli angoli alti opposti: elimina alto sx, download alto sx
- [ ] aggiungere conferma prima di eliminare un file
- [ ] nella dashboard limitare la larghezza delle card lavoro e ticket al 95% della larghezza del dispositivo su smartphone per migliorare la responsiveness
- [ ] nella side bar aggiungere sopra alla sezione 'utente' il numero delle verisoni: versione front end, versione backend 

## Ordine Elementi
- [ ] nella pagina 'work_details' le righe del 'work_report' devoo essere mostrate in ordine per data dalla piu recente alla piu vecchia
- [ ] nella pagina 'plants' ordinare per data dal piu recente al meno recente

## Autorizzazioni
- [ ] utenti di tipo amministrativo possono editare 'workReport' e 'WorkReportEntry'

## Container
- [ ] aggiungere polycy di restart "unless stopped" a tutti i conntainer nel file @docker-compose.yml