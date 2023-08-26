import Dates
import JSON3
import SQLite

const things_table = "things"

"""
Opens iota database, applies the function to it, then closes the database.
"""
function iota_db(f::Function, path::String)
    db = SQLite.DB(path)
    try
        f(db)
    finally
        SQLite.close(db)
    end
end

"""
Initialize iota database nondestructively.
If tables already exist, do not overwrite them.
"""
function initialize!(db::SQLite.DB)
    cmd = "CREATE TABLE IF NOT EXISTS $things_table (name TEXT)"
    SQLite.execute(db, cmd)
end

"""
Get things in iota.
"""
function get_things(db::SQLite.DB)
    cmd = "SELECT name FROM $things_table"
    cursor = SQLite.DBInterface.execute(db, cmd)
    things = [first(NamedTuple(c)) for c in cursor]
    sort(things)
end

"""
Add thing to iota.
"""
function add_thing!(db::SQLite.DB, descriptor::JSON3.Object)
    # Add thing to thing table.
    new_thing = descriptor.id
    if new_thing in get_things(db)
        # error
        return false
    end

    cmd = """INSERT INTO $things_table VALUES ("$new_thing")"""
    SQLite.execute(db, cmd)

    # Create table for thing.
    columns = sort([k for k in keys(descriptor) if k != :id])
    cmd = "CREATE TABLE $new_thing (timestamp INTEGER, "
    cmd *= join(["$k $(descriptor[k])" for k in columns], ", ")
    cmd *= ")"
    println("SQL: $cmd")
    SQLite.execute(db, cmd)

    return true
end

"""
Get most recent thing entry.
"""
function get_latest_thing_entry(db::SQLite.DB, thing::AbstractString)
    cmd = "SELECT * FROM $thing WHERE ROWID IN (SELECT max(ROWID) FROM $thing)"
    println("SQL: $cmd")
    cursor = SQLite.DBInterface.execute(db, cmd)
    result = [NamedTuple(c) for c in cursor]
    return length(result) > 0 ? result[end] : NamedTuple()
end

"""
Get `n` most recent thing data entries.
"""
function get_most_recent_thing_entries(db::SQLite.DB, thing::AbstractString, n::Integer)
    cmd = "SELECT * from $thing WHERE ROWID > (SELECT max(ROWID) FROM $thing) - $n"
    println("SQL: $cmd")
    cursor = SQLite.DBInterface.execute(db, cmd)
    [NamedTuple(c) for c in cursor]
end

"""
Get range of thing data entries based on timestamp.
"""
function get_thing_entries(
    db::SQLite.DB, 
    thing::AbstractString, 
    from::AbstractString, 
    to::AbstractString
)
    key = "timestamp"
    from_date = Dates.DateTime(from, Dates.dateformat"y-m-d")
    to_date = Dates.DateTime(to, Dates.dateformat"y-m-d")
    cmd = "SELECT * from $thing 
        WHERE $key >= $(Dates.datetime2unix(from_date)) 
        AND $key <= $(Dates.datetime2unix(to_date))"
    println("SQL: $cmd")
    cursor = SQLite.DBInterface.execute(db, cmd)
    [NamedTuple(c) for c in cursor]
end

"""
Add datapoint to thing.
"""
function add_to_thing(db::SQLite.DB, thing::AbstractString, datapoint::JSON3.Object)
    timestamp = Dates.datetime2unix(Dates.now())

    columns = sort([k for k in keys(datapoint) if k != :id])
    cmd = "INSERT INTO $thing VALUES ($timestamp, "
    cmd *= join([datapoint[k] for k in columns], ", ")
    cmd *= ")"
    println("SQL: $cmd")
    SQLite.execute(db, cmd)
end
