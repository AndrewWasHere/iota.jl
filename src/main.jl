using Dates
using HTTP
using JSON3
using Oxygen
import iota

const db_path = "iota.sqlite"

function api_response_fields(body::AbstractString; status::Integer = 200)
    header = ["Content-Type" => "application/json"]
    return status, header, JSON3.write(body)
end

###
# /

@get "/" function(req::HTTP.Request)
    body = open("web/app.html") do f
        read(f, String)
    end
    return body
end

###
# /things/{thing_id}

@get "/things/{thing_id}" function(req::HTTP.Request, thing_id::String)
    results = iota.iota_db(db_path) do db
        iota.get_things(db)
    end

    if thing_id ∈ results
        body = open("web/thing.html") do f
            read(f, String)
        end
        return body
    else
        status, header, body = api_response_fields(
            "Iota: No such thing: $thing_id", 
            status=404
        )
        return HTTP.Response(status, header, body)
    end
end

#############
# /api/things

@get "/api/things" function(req::HTTP.Request)
    result = iota.iota_db(db_path) do db
        iota.get_things(db)
    end
    return result
end

@post "/api/things" function(req::HTTP.Request)
    status = header = body = nothing
    try
        result = iota.iota_db(db_path) do db
            thing = JSON3.read(req.body)
            iota.add_thing!(db, thing)
        end
        status, header, body = result ? 
            api_response_fields("", status=201) : 
            api_response_fields("$thing does not exist.", status=400)
    catch e
        # Database error.
        println("*** Iota Error: $e")
        status, header, body = api_response_fields("You broke my database. 😢", status=500)
    end
    return HTTP.Response(status, header, body)
end

########################
# /api/things/{thing_id}

@get "/api/things/{thing_id}" function(req::HTTP.Request, thing_id::String)
    p = queryparams(req)
    k = keys(p)
    if :last ∈ k
        last = 0
        try
            last = parse(Integer, p[:last])
        catch
            status, header, body = api_response_fields("`last` query value must be an integer.", status=400)
            return HTTP.Response(status, header, body)
        end

        try
            result = iota.iota_db(db_path) do db
                iota.get_most_recent_thing_entries(db, thing_id, last)
            end
            return result
        catch e
            # Database error.
            println("*** Iota Error: $e")
            status, header, body = api_response_fields("You broke my database. 😢", status=500)
            return HTTP.Response(status, header, body)
        end
    elseif :from ∈ k || :to ∈ k
        if !(:from ∈ k && :to ∈ k)
            status, header, body = api_response_fields("`from` and `to` query parameters must both be present.", status=400)
            return HTTP.Response(status, header, body)
        end
        from = to = nothing
        try
            from = datetime2unix(DateTime(p[:from], dateformat"y-m-d"))
            to = datetime2unix(DateTime(p[:to], dateformat"y-m-d"))
        catch
            status, header, body = api_response_fields("`from` and `to` query values must be dates of the form y-m-d", status=400)
            return HTTP.Response(status, header, body)
        end

        try
            results = iota.iota_db(db_path) do db
                iota.get_thing_entries(db, thing_id, from, to)
            end
            return results
        catch e
            # Database error.
            println("*** Iota Error: $e")
            status, header, body = api_response_fields("You broke my database. 😢", status=500)
            return HTTP.Response(status, header, body)
        end
    else
        try
            results = iota.iota_db(db_path) do db
                iota.get_latest_thing_entry(db, thing_id)
            end
            return results
        catch e
            # Database error.
            println("*** Iota Error: $e")
            status, header, body = api_response_fields("You broke my database. 😢", status=500)
            return HTTP.Response(status, header, body)
        end
    end
    return HTTP.Response(status, header, body)
end

@put "/api/things/{thing_id}" function(req::HTTP.Request, thing_id::String)
    try
        result = iota.iota_db(db_path) do db
            iota.get_things(db)
        end
        if thing_id ∉ result
            status, header, body = api_response_fields("$thing_id not found", status=400)
            return HTTP.Response(status, header, body)
        end

        datapoint = JSON3.read(req.body)
        iota.iota_db(db_path) do db
            iota.add_to_thing(db, thing_id, datapoint)        
        end
    catch e
        println("*** Iota Error: $e")
        status, header, body = api_response_fields("You broke my database. 😢", status=500)
        return HTTP.Response(status, header, body)
    end
    return HTTP.Response(204, "")
end

iota.iota_db(db_path) do db
    iota.initialize!(db)
end
dynamicfiles("assets", "assets")
serve(host="0.0.0.0", port=8000)
