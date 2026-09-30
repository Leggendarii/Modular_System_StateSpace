# Modular System State-Space

Questo progetto costruisce un modello dinamico modulare di un sistema elettrico e ne analizza la stabilità a piccoli segnali. Il flusso principale è descritto in [`main.m`](main.m): prima calcola il punto di funzionamento della rete, poi costruisce e linearizza i modelli dei componenti, li connette e analizza il sistema risultante.

## Requisiti

- MATLAB
- [MATPOWER](https://matpower.org/), installato separatamente e disponibile nel MATLAB path
- Symbolic Math Toolbox e Control System Toolbox di MATLAB

Per installare MATPOWER, seguire le [istruzioni ufficiali](https://matpower.org/about/get-started/). Il repository non specifica una versione minima.

## Flusso di calcolo

### 1. Caricamento dei parametri e calcolo del power flow

`main.m` aggiunge al MATLAB path le librerie contenute in `lib/` e carica i parametri statici con `loadParameters`. I valori nominali, i parametri del convertitore e i guadagni dei controllori sono definiti nel CSV dei parametri; alcune impostazioni aggiuntive, come il tipo di controllo (`PV` o `PQ`) e la potenza attiva e reattiva impostata, sono definite in `lib/Setup/loadParameters.m`.

La funzione [`powerflow.m`](powerflow.m) converte i parametri elettrici in per-unit e crea un caso MATPOWER a quattro bus:

- il bus 1 rappresenta il convertitore grid-following (GFL);
- il bus 4 rappresenta la rete equivalente, modellata come slack bus;
- il collegamento bus 1–2 è una sezione serie RL;
- il collegamento bus 2–3 è una linea a modello π, con resistenza e reattanza serie e capacità ripartita tra le due estremità;
- il collegamento bus 3–4 è l’equivalente RL della rete.

Con `Type = 'PV'`, il bus del convertitore regola la tensione e usa la potenza attiva impostata; con `Type = 'PQ'`, vengono specificate potenza attiva e reattiva. MATPOWER risolve il power flow e fornisce tensioni, angoli, potenze e flussi di ramo.

`PF_results` estrae da questi risultati i punti di funzionamento del convertitore, della linea π e della rete. Le funzioni `OP_Converters`, `OP_Line` e `OP_Grids` li trasformano nei valori iniziali usati dai rispettivi modelli dinamici.

### 2. Costruzione e linearizzazione dei componenti

In `main.m` vengono istanziati tre componenti modulari:

- `Converter_GFL`: convertitore grid-following, inclusi filtri e controlli;
- `Line`: linea con ramo serie e capacità shunt;
- `Grid`: equivalente dinamico RL della rete.

Per ogni componente, `build()` definisce le equazioni simboliche e calcola le matrici jacobiane. `evaluate()` sostituisce parametri e punto di funzionamento per ottenere il modello linearizzato in spazio di stato (`ss`) e calcola i residui di equilibrio. I modelli vengono quindi rinominati tramite i segnali di ingresso e uscita e collegati da MATLAB `connect()`, che abbina automaticamente i segnali con lo stesso nome.

Gli ingressi esterni del sistema connesso sono `Pref`, `Vdc_ref`, `Vpoc_ref`, `V0_d` e `V0_q`. Le uscite comprendono le correnti di convertitore e rete e le tensioni ai nodi di interfaccia. Infine `stability_analysis(SYS)` esegue l’analisi di stabilità del sistema assemblato.

## Esecuzione

Aprire MATLAB nella directory principale del repository e lanciare:

```matlab
main
```

Assicurarsi che MATPOWER sia disponibile nel MATLAB path. **Nota:** `main.m` cerca `parameters.csv` nella directory di lavoro corrente, mentre il CSV fornito si trova in `data/parameters.csv`; prima dell’esecuzione occorre rendere coerente questo percorso con la directory di lavoro o con la chiamata a `loadParameters`.

## Struttura utile

- `main.m`: orchestrazione del flusso e connessione dei modelli.
- `powerflow.m`: costruzione del caso MATPOWER e calcolo del power flow AC.
- `data/parameters.csv`: parametri numerici forniti come esempio.
- `lib/Setup/`: caricamento e derivazione dei parametri.
- `lib/PowerFlow/`: estrazione dei risultati e calcolo dei punti di funzionamento.
- `lib/State_Space/Classes/`: modelli dinamici dei componenti.
- `lib/State_Space/stability_analysis.m`: analisi di stabilità.

Il file [`power_flow_DC.m`](power_flow_DC.m) è uno script separato di esempio per un flusso di potenza DC seguito da tre power flow AC; non è invocato dal flusso principale di `main.m`.

## Licenza

Il progetto è distribuito con licenza MIT; vedere [LICENSE](LICENSE).
