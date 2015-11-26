# Elixir-Couch

Elixir-Couch is my attempt at a feature-complete [Apache CouchDB](http://couchdb.apache.org) client, written in [Elixir](http://elixir-lang.org).
It is modelled tightly after [Benoit's couchbeam library](https://github.com/benoitc/couchbeam). 
It is also a learning  experience for me, so don't expect too much for now. 
On the other hand, I _do_ plan to integrate it into some larger real-word application 
and actually use it.

The whole thing is only partially usable since only a handful server-related api calls
are implemented. Don't go away to see the project evolve (or me fail).

License: MIT

## API parts most probably working:

* Couch.server_connection
* Couch.server_info
* Couch.get_uuid
* Couch.replicate
* Couch.all_dbs
* Couch.db_exists
* Couch.create_db
* Couch.delete_db
* Couch.open_db
* Couch.open_or_create_db
* Couch.db_info
* Couch.doc_exists
* Couch.open_doc
* Couch.save_doc
* Couch.delete_doc
* Couch.save_docs
* Couch.delete_docs
* Couch.copy_doc
* Couch.lookup_doc_ref