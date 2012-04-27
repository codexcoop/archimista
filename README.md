## Archimista

Archimista è un'applicazione web open source per la descrizione di archivi storici. È disponibile in due versioni: standalone e server.

## Requisiti

Archimista funziona sui sistemi operativi GNU/Linux, Mac OS X, Windows XP e superiori.

* Ruby 1.8.7
* Rails 2.3.14
* Varie gemme Ruby dichiarate nel file config/environment.rb
* Gemma rubyzip
* ImageMagick (opzionale, per la gestione di oggetti digitali)
* Database: MySQL o PostgreSQL o SQLite
* Webserver configurato per applicazioni Rails

## Installazione

Per Windows, versione standalone, è disponibile un pacchetto di installazione, scaricabile dal sito ufficiale: [http://www.archimista.it](http://www.archimista.it) .

Per la versione server:

1. Predisporre il proprio computer con il software indicato nei Requisiti
2. Creare un file di configurazione per il database: config/database.yml. Per maggiori informazioni leggi: [http://guides.rubyonrails.org/v2.3.11/getting_started.html#configuring-a-database](http://guides.rubyonrails.org/v2.3.11/getting_started.html#configuring-a-database)
3. Eseguire il task rake gems:install
4. Eseguire il task RAILS_ENV=production rake db:setup
5. Avviare il webserver

L'utente per il primo login è:
user admin_archimista
pass admin_archimista

## Crediti

Archimista è un progetto promosso da:

* Direzione Generale per gli Archivi
* Regione Lombardia, Direzione Generale Istruzione, Formazione e Cultura
* Regione Piemonte, Direzione Cultura, Turismo e Sport
* Università degli Studi di Pavia

## Autori

Codex Società Cooperativa, Pavia

* [http://www.codexcoop.it](http://www.codexcoop.it)

## Licenza

Archimista è rilasciato sotto licenza GNU General Public License v2.0 o successive.
