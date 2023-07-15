# Iota.jl

Intranet of Things Administrator. In Julia!

A relatively lightweight REST-based API for collecting Internet of Things data 
and simple data visualization with no consideration to security whatsoever.

```mermaid
C4Context
    title Iota Context

    Person(user, "Human", "Description")
    System_Boundary(system, "") {
        Container(api, "REST API")
        ContainerDb(db, "Database", "Holds all thing data")
    }
    Container(thing1, "Thermometer")
    Container(thing2, "Thermometer")

    Rel(user, api, "Uses", "HTTP")
    Rel(api, db, "Stores and accesses data")
    Rel(thing1, api, "Sends data", "HTTP")
    Rel(thing2, api, "Sends data", "HTTP")
```

## User Endpoints

### GET /
Main web browser landing point. Lists all registered things and displays their
latest values.

### GET /things/{thing_id}
Browser landing point for individual thing data visualization.

## API Endpoints

### GET /api/things
Returns a list of things registered with Iota.

### POST /api/things
Register a new thing to Iota.

Request:
```http
POST /api/things
{
    id: <thing_id>,
    <field>: <type>,
    ...
}
```

Response when <thing_id> created:
```http
201 Created
```

Response when <thing_id> already exists, or request has errors in it:
```http
400 Bad Request
```

### GET /api/things/{thing_id}
Retrieve data for `thing_id`.

Query parameters:
* `last=N` -- return `N` most recent entries.
* `from=<primary key value>`, `to=<primary key value>` -- return range of entries

### PUT /api/things/{thing_id}
Update `thing_id` data.

## Database Schema

### Things Table
* `thing_id`: integer (primary key)
* `name`: text

### Thing Table
Thing table columns are determined at table creation time.

## Dependencies

* Julia 1.8
* Oxygen.jl
* SQLite.jl

## License

MIT License. See LICENSE.txt for more information.
