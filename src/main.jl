using HTTP
using JSON3
using Oxygen

function api_response_fields(body::AbstractString)
    status = 200
    header = ["Content-Type" => "application/json"]
    return status, header, JSON3.write(body)
end

###
# /
@get "/" function(req::HTTP.Request)
    body = "<html><body>Iota goes here.</body></html>"
    return body
end

#############
# /api/things

@get "/api/things" function(req::HTTP.Request)
    status, header, body = api_response_fields("GET /api/things")
    return HTTP.Response(status, header, body)
end

@post "/api/things" function(req::HTTP.Request)
    status, header, body = api_response_fields("POST /api/things")
    return HTTP.Response(status, header, body)
end

########################
# /api/things/{thing_id}

@get "/api/things/{thing_id}" function(req::HTTP.Request, thing_id::String)
    status, header, body = api_response_fields("GET /api/things/$thing_id")
    return HTTP.Response(status, header, body)
end

@put "/api/things/{thing_id}" function(req::HTTP.Request, thing_id::String)
    status, header, body = api_response_fields("PUT /api/things/$thing_id")
    return HTTP.Response(status, header, body)
end

serve()

end  # module iota
