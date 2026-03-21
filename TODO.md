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
- [ ] new: rivedere lo stile delle card lavoro e ticket nella dashboard: le voglio bianche con un bordino ([idea](card_style.png)) 

## Ordine Elementi
- [ ] nella pagina 'work_details' le righe del 'work_report' devoo essere mostrate in ordine per data dalla piu vecchia alla piu recente
- [ ] nella pagina 'plants' ordinare per data dal piu recente al meno recente

## Autorizzazioni
- [ ] utenti di tipo amministrativo possono editare 'workReport' e 'WorkReportEntry'

## Container
- [ ] aggiungere polycy di restart "unless stopped" a tutti i conntainer nel file @docker-compose.yml

# Bug
- [ ] Quando in aggiungi riferimento di cantiere selezioni ALTRO non ti permette di inserire il nominativo
        | Timestamp | Type | Category | Level | Message | Data |
        |-----------|------|----------|-------|---------|------|
        | 2026-03-20T20:42:58.036Z | http | fetch | info |  | {"__span":"84ca8e5155f34bf6","method":"POST","request_body_size":644,"status_code":200,"url":"/api/graphql"} |
        | 2026-03-20T20:42:58.045Z | http | fetch | info |  | {"__span":"a0e0c01a631fe07a","method":"GET","status_code":200,"url":"/api/works?technicianId=ce5e5aaa-4e4d-4a42-9187-a8ebd9476e6c&status=IN_PROGRESS&page=0&size=100&sort=createdAt%2Cdesc"} |
        | 2026-03-20T20:42:59.058Z | transaction | sentry.transaction | info | e567298206d54807946df5603695ab45 |  |
        | 2026-03-20T20:44:09.461Z | ui | ui.click | info | header.flex.h-16.shrink-0.items-center.gap-2.border-b.bg-card.px-4 |  |
        | 2026-03-20T20:44:10.593Z | ui | ui.click | info | button.inline-flex.items-center.justify-center.gap-2.whitespace-nowrap.rounded-md.text-sm.font-medium.ring-offset-background.transition-colors.focus-visible:outline-none.focus-visible:ring-2.focus-visible:ring-ring.focus-visible:ring-offset-2.disabled:pointer-events-none.disabled:opacity-50.[&_svg]:pointer-events-none.[&_svg]:size-4.[&_svg]:shrink-0.hover:bg-accent.hover:text-accent-foreground.h-7.w-7.-ml-1 |  |
        | 2026-03-20T20:44:10.637Z | debug | console | error | `DialogContent` requires a `DialogTitle` for the component to be accessible for screen reader users.  If you want to hide the `DialogTitle`, you can wrap it with our VisuallyHidden component.  For more information, see https://radix-ui.com/primitives/docs/components/dialog | {"arguments":["`DialogContent` requires a `DialogTitle` for the component to be accessible for screen reader users.\\n\\nIf you want to hide the `DialogTitle`, you can wrap it with our VisuallyHidden component.\\n\\nFor more information, see https://radix-ui.com/primitives/docs/components/dialog"],"logger":"console"} |
        | 2026-03-20T20:44:10.637Z | debug | console | warning | Warning: Missing `Description` or `aria-describedby={undefined}` for {DialogContent}. | {"arguments":["Warning: Missing `Description` or `aria-describedby={undefined}` for {DialogContent}."],"logger":"console"} |
        | 2026-03-20T20:44:12.145Z | ui | ui.click | info | span |  |
        | 2026-03-20T20:44:12.148Z | navigation | navigation | info |  | {"from":"/","to":"/works"} |
        | 2026-03-20T20:44:12.302Z | http | fetch | info |  | {"__span":"93c64130f3be3ec1","method":"GET","status_code":200,"url":"/api/works?page=0&size=10&sort=createdAt%2Cdesc&statuses=IN_PROGRESS"} |
        | 2026-03-20T20:44:12.304Z | http | fetch | info |  | {"__span":"9162912e5d6e2162","method":"GET","status_code":200,"url":"/api/works?page=0&size=1&statuses=SCHEDULED"} |
        | 2026-03-20T20:44:12.304Z | http | fetch | info |  | {"__span":"af8b6f206ff5aee0","method":"GET","status_code":200,"url":"/api/clients?page=0&size=100&sort=name,asc"} |
        | 2026-03-20T20:44:12.326Z | http | fetch | info |  | {"__span":"8a873c054ce1ff82","method":"GET","status_code":200,"url":"/api/plants?page=0&size=100"} |
        | 2026-03-20T20:44:12.327Z | http | fetch | info |  | {"__span":"9506de18ee1315c7","method":"GET","status_code":200,"url":"/api/works?page=0&size=1&statuses=IN_PROGRESS"} |
        | 2026-03-20T20:44:12.327Z | http | fetch | info |  | {"__span":"a2f4acb8b1dd3bd2","method":"GET","status_code":200,"url":"/api/works?page=0&size=1&statuses=CLOSED&statuses=INVOICED"} |
        | 2026-03-20T20:44:12.327Z | http | fetch | info |  | {"__span":"ad69feeec98af2e2","method":"GET","status_code":200,"url":"/api/users/type/TECHNICIAN"} |
        | 2026-03-20T20:44:12.327Z | http | fetch | info |  | {"__span":"a222dd49ee878fbc","method":"GET","status_code":200,"url":"/api/users/type/SELLER"} |
        | 2026-03-20T20:44:12.327Z | http | fetch | info |  | {"__span":"a90bb799505964d8","method":"GET","status_code":200,"url":"/api/tickets?"} |
        | 2026-03-20T20:44:12.743Z | ui | ui.click | info | div.fixed.inset-0.z-50.bg-black/80.data-[state=open]:animate-in.data-[state=closed]:animate-out.data-[state=closed]:fade-out-0.data-[state=open]:fade-in-0 |  |
        | 2026-03-20T20:44:15.314Z | ui | ui.click | info | div.flex.flex-col.lg:flex-row.lg:items-center.gap-4 > div.flex.gap-4.lg:gap-6 |  |
        | 2026-03-20T20:44:15.315Z | navigation | navigation | info |  | {"from":"/works","to":"/works/ca563e10-d049-4009-835d-92548650b7c1"} |
        | 2026-03-20T20:44:15.447Z | http | fetch | info |  | {"__span":"87bef0133fd65d2d","method":"GET","status_code":200,"url":"/api/users/type/TECHNICIAN"} |
        | 2026-03-20T20:44:15.448Z | http | fetch | info |  | {"__span":"94285f990cf23582","method":"GET","status_code":200,"url":"/api/worksite-references"} |
        | 2026-03-20T20:44:15.451Z | http | fetch | info |  | {"__span":"b42d70f619b524fb","method":"GET","status_code":200,"url":"/api/plants?page=0&size=100"} |
        | 2026-03-20T20:44:15.452Z | http | fetch | info |  | {"__span":"9b48ea51703f140e","method":"GET","status_code":200,"url":"/api/works/ca563e10-d049-4009-835d-92548650b7c1"} |
        | 2026-03-20T20:44:15.452Z | http | fetch | info |  | {"__span":"a3ec227318e4c36c","method":"GET","status_code":200,"url":"/api/users/type/SELLER"} |
        | 2026-03-20T20:44:15.477Z | http | fetch | info |  | {"__span":"a5ae07c33f562833","method":"GET","status_code":200,"url":"/api/work-reports/entries/work/ca563e10-d049-4009-835d-92548650b7c1"} |
        | 2026-03-20T20:44:15.477Z | http | fetch | info |  | {"__span":"bdf9a99219a01b1a","method":"GET","status_code":200,"url":"/api/clients?page=0&size=100&sort=name,asc"} |
        | 2026-03-20T20:44:15.488Z | http | fetch | info |  | {"__span":"b612a86131b249b5","method":"GET","status_code":200,"url":"/api/attachments/WORK/ca563e10-d049-4009-835d-92548650b7c1"} |
        | 2026-03-20T20:44:19.171Z | ui | ui.click | info | button.inline-flex.items-center.justify-center.gap-2.whitespace-nowrap.rounded-md.text-sm.font-medium.ring-offset-background.transition-colors.focus-visible:outline-none.focus-visible:ring-2.focus-visible:ring-ring.focus-visible:ring-offset-2.disabled:pointer-events-none.disabled:opacity-50.[&_svg]:pointer-events-none.[&_svg]:size-4.[&_svg]:shrink-0.border.border-input.bg-background.hover:bg-accent.hover:text-accent-foreground.h-10.px-4.py-2.w-full[type="button"] |  |
        | 2026-03-20T20:44:20.406Z | ui | ui.click | info | button#reference.flex.h-10.w-full.items-center.justify-between.rounded-md.border.border-input.bg-background.px-3.py-2.text-sm.ring-offset-background.placeholder:text-muted-foreground.focus:outline-none.focus:ring-2.focus:ring-ring.focus:ring-offset-2.disabled:cursor-not-allowed.disabled:opacity-50.[&>span]:line-clamp-1[type="button"] |  |
        | 2026-03-20T20:44:21.142Z | ui | ui.click | info | div.relative.flex.w-full.cursor-default.select-none.items-center.rounded-sm.py-1.5.pl-8.pr-2.text-sm.outline-none.data-[disabled]:pointer-events-none.data-[disabled]:opacity-50.focus:bg-accent.focus:text-accent-foreground |  |
        | 2026-03-20T20:44:21.621Z | ui | ui.click | info | button#role.flex.h-10.w-full.items-center.justify-between.rounded-md.border.border-input.bg-background.px-3.py-2.text-sm.ring-offset-background.placeholder:text-muted-foreground.focus:outline-none.focus:ring-2.focus:ring-ring.focus:ring-offset-2.disabled:cursor-not-allowed.disabled:opacity-50.[&>span]:line-clamp-1[type="button"] |  |
        | 2026-03-20T20:44:22.541Z | ui | ui.click | info | div.relative.flex.w-full.cursor-default.select-none.items-center.rounded-sm.py-1.5.pl-8.pr-2.text-sm.outline-none.data-[disabled]:pointer-events-none.data-[disabled]:opacity-50.focus:bg-accent.focus:text-accent-foreground |  |
        | 2026-03-20T20:44:29.007Z | ui | ui.click | info | svg |  |
        | 2026-03-20T20:44:42.530Z | ui | ui.click | info | button.inline-flex.items-center.justify-center.gap-2.whitespace-nowrap.rounded-md.text-sm.font-medium.ring-offset-background.transition-colors.focus-visible:outline-none.focus-visible:ring-2.focus-visible:ring-ring.focus-visible:ring-offset-2.disabled:pointer-events-none.disabled:opacity-50.[&_svg]:pointer-events-none.[&_svg]:size-4.[&_svg]:shrink-0.border.border-input.bg-background.hover:bg-accent.hover:text-accent-foreground.h-10.px-4.py-2.w-full[type="button"] |  |
        | 2026-03-20T20:44:43.311Z | ui | ui.click | info | button#reference.flex.h-10.w-full.items-center.justify-between.rounded-md.border.border-input.bg-background.px-3.py-2.text-sm.ring-offset-background.placeholder:text-muted-foreground.focus:outline-none.focus:ring-2.focus:ring-ring.focus:ring-offset-2.disabled:cursor-not-allowed.disabled:opacity-50.[&>span]:line-clamp-1[type="button"] |  |
        | 2026-03-20T20:44:44.064Z | ui | ui.click | info | div.relative.flex.w-full.cursor-default.select-none.items-center.rounded-sm.py-1.5.pl-8.pr-2.text-sm.outline-none.data-[disabled]:pointer-events-none.data-[disabled]:opacity-50.focus:bg-accent.focus:text-accent-foreground |  |
        | 2026-03-20T20:44:45.009Z | ui | ui.click | info | button#reference.flex.h-10.w-full.items-center.justify-between.rounded-md.border.border-input.bg-background.px-3.py-2.text-sm.ring-offset-background.placeholder:text-muted-foreground.focus:outline-none.focus:ring-2.focus:ring-ring.focus:ring-offset-2.disabled:cursor-not-allowed.disabled:opacity-50.[&>span]:line-clamp-1[type="button"] |  |
        | 2026-03-20T20:44:48.429Z | ui | ui.click | info | div.fixed.inset-0.z-50.bg-black/80.data-[state=open]:animate-in.data-[state=closed]:animate-out.data-[state=closed]:fade-out-0.data-[state=open]:fade-in-0 |  |
        | 2026-03-20T20:44:48.827Z | ui | ui.click | info | button.inline-flex.items-center.justify-center.gap-2.whitespace-nowrap.text-sm.font-medium.ring-offset-background.transition-colors.focus-visible:outline-none.focus-visible:ring-2.focus-visible:ring-ring.focus-visible:ring-offset-2.disabled:pointer-events-none.disabled:opacity-50.[&_svg]:pointer-events-none.[&_svg]:size-4.[&_svg]:shrink-0.border.border-input.bg-background.hover:bg-accent.hover:text-accent-foreground.h-9.rounded-md.px-3[type="button"] |  |
        | 2026-03-20T20:44:49.782Z | ui | ui.click | info | input#newReferenceName.flex.h-10.w-full.rounded-md.border.border-input.bg-background.px-3.py-2.text-base.ring-offset-background.file:border-0.file:bg-transparent.file:text-sm.file:font-medium.file:text-foreground.placeholder:text-muted-foreground.focus-visible:outline-none.focus-visible:ring-2.focus-visible:ring-ring.focus-visible:ring-offset-2.disabled:cursor-not-allowed.disabled:opacity-50.md:text-sm |  |
        | 2026-03-20T20:44:50.791Z | ui | ui.input | info | input#newReferenceName.flex.h-10.w-full.rounded-md.border.border-input.bg-background.px-3.py-2.text-base.ring-offset-background.file:border-0.file:bg-transparent.file:text-sm.file:font-medium.file:text-foreground.placeholder:text-muted-foreground.focus-visible:outline-none.focus-visible:ring-2.focus-visible:ring-ring.focus-visible:ring-offset-2.disabled:cursor-not-allowed.disabled:opacity-50.md:text-sm |  |
        | 2026-03-20T20:44:52.695Z | ui | ui.click | info | input#newReferencePhone.flex.h-10.w-full.rounded-md.border.border-input.bg-background.px-3.py-2.text-base.ring-offset-background.file:border-0.file:bg-transparent.file:text-sm.file:font-medium.file:text-foreground.placeholder:text-muted-foreground.focus-visible:outline-none.focus-visible:ring-2.focus-visible:ring-ring.focus-visible:ring-offset-2.disabled:cursor-not-allowed.disabled:opacity-50.md:text-sm[type="tel"] |  |
        | 2026-03-20T20:44:55.622Z | ui | ui.input | info | input#newReferencePhone.flex.h-10.w-full.rounded-md.border.border-input.bg-background.px-3.py-2.text-base.ring-offset-background.file:border-0.file:bg-transparent.file:text-sm.file:font-medium.file:text-foreground.placeholder:text-muted-foreground.focus-visible:outline-none.focus-visible:ring-2.focus-visible:ring-ring.focus-visible:ring-offset-2.disabled:cursor-not-allowed.disabled:opacity-50.md:text-sm[type="tel"] |  |
        | 2026-03-20T20:44:56.442Z | ui | ui.click | info | textarea#newReferenceNotes.flex.min-h-[80px].w-full.rounded-md.border.border-input.bg-background.px-3.py-2.text-sm.ring-offset-background.placeholder:text-muted-foreground.focus-visible:outline-none.focus-visible:ring-2.focus-visible:ring-ring.focus-visible:ring-offset-2.disabled:cursor-not-allowed.disabled:opacity-50 |  |
        | 2026-03-20T20:44:58.198Z | ui | ui.click | info | button#role.flex.h-10.w-full.items-center.justify-between.rounded-md.border.border-input.bg-background.px-3.py-2.text-sm.ring-offset-background.placeholder:text-muted-foreground.focus:outline-none.focus:ring-2.focus:ring-ring.focus:ring-offset-2.disabled:cursor-not-allowed.disabled:opacity-50.[&>span]:line-clamp-1[type="button"] |  |
        | 2026-03-20T20:44:59.069Z | ui | ui.click | info | div.relative.flex.w-full.cursor-default.select-none.items-center.rounded-sm.py-1.5.pl-8.pr-2.text-sm.outline-none.data-[disabled]:pointer-events-none.data-[disabled]:opacity-50.focus:bg-accent.focus:text-accent-foreground |  |
        | 2026-03-20T20:44:59.649Z | ui | ui.click | info | button.inline-flex.items-center.justify-center.gap-2.whitespace-nowrap.rounded-md.text-sm.font-medium.ring-offset-background.transition-colors.focus-visible:outline-none.focus-visible:ring-2.focus-visible:ring-ring.focus-visible:ring-offset-2.disabled:pointer-events-none.disabled:opacity-50.[&_svg]:pointer-events-none.[&_svg]:size-4.[&_svg]:shrink-0.bg-primary.text-primary-foreground.hover:bg-primary/90.h-10.px-4.py-2 |  |
        | 2026-03-20T20:44:59.802Z | http | fetch | info |  | {"__span":"960af70bc73cef17","method":"POST","request_body_size":34,"status_code":201,"url":"/api/worksite-references"} |
        | 2026-03-20T20:44:59.818Z | http | fetch | info |  | {"__span":"b8795adfbd024417","method":"GET","status_code":200,"url":"/api/worksite-references"} |
        | 2026-03-20T20:44:59.848Z | http | fetch | warning |  | {"__span":"868d1db3b6229a23","method":"POST","request_body_size":77,"status_code":409,"url":"/api/works/ca563e10-d049-4009-835d-92548650b7c1/add-reference"} |
        | 2026-03-20T20:44:59.851Z | error | exception | error |  | {"type":"Error","value":"API Error: Conflitto di dati. Aggiorna e riprova."} |