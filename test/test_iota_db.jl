using Test, Dates, JSON3, SQLite, iota

@testset "Exercise database" begin
    db = SQLite.DB()

    # Initialization creates a things table.
    iota.initialize!(db)

    @test "things" ∈ [t.name for t in SQLite.tables(db)]

    # Add thing to iota.
    thing = "thing_1"
    d = JSON3.read("""{ "id": "$thing", "temperature": "FLOAT" }""")
    iota.add_thing!(db, d)

    @test thing ∈ iota.get_things(db)
    @test iota.get_latest_thing_entry(db, thing) == NamedTuple()

    # Add entry from thing.
    d = JSON3.read("""{ "temperature": 42.0 }""")
    iota.add_to_thing(db, thing, d)

    entry = iota.get_latest_thing_entry(db, thing)
    @test d.temperature == entry.temperature
    @test Dates.unix2datetime(entry.timestamp) >= Dates.today()

    entries = iota.get_most_recent_thing_entries(db, thing, 1)
    @test length(entries) == 1
    @test d.temperature ∈ [e.temperature for e in entries]

    entries = iota.get_most_recent_thing_entries(db, thing, 2)
    @test length(entries) == 1
    @test d.temperature ∈ [e.temperature for e in entries]

    missing_temp = d.temperature
    new_temps = [
        JSON3.read("""{ "temperature": 52.0 }"""), 
        JSON3.read("""{ "temperature": 62.0 }""")
    ]
    for d in new_temps
        iota.add_to_thing(db, thing, d)
    end

    entries = iota.get_most_recent_thing_entries(db, thing, 2)
    entry_temps = [e.temperature for e in entries]
    @test length(entries) == 2
    for d in new_temps
        @test d.temperature ∈ entry_temps
    end
    @test missing_temp ∉ entry_temps

    today = string(Dates.today())
    tomorrow = string(Dates.today() + Dates.Day(1))
    entries = iota.get_thing_entries(db, thing, today, tomorrow)
    entry_temps = [e.temperature for e in entries]
    @test length(entries) == 3
    for t in [[missing_temp]; [e.temperature for e in new_temps]]
        @test t ∈ entry_temps
    end

    SQLite.close(db)
end