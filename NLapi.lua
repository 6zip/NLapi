--[[

    welcome to the NLapi
    written by nologic, 2023

    this is an example API
    system made entirely
    with lua.

    requirements:
    lua 5.1
    luarocks
    >socket library (luasocket)
    >json library (dkjson)


    it is recommended to run this on a VPS
    and proxy it with nginx. there are other
    methods to this, but this is how it's
    normally done.


    have fun!
     
]]--

--configuration
local conf = { port = 5522 }

os.execute("clear")print([[

   ::::    ::::
   :+:+:   :++:
   :+:+:+  +::+
   +#+ +:+ +##+
   +#+ +#+ +#+#
   #+#   #+#++#
   ###    ############

   NLapi
        made by nologic
]])

print("started at "..os.date("%Y-%m-%d %H:%M:%S")..'\n\n')

--make log function
local function log(str)
    print("("..tostring(os.date("%Y-%m-%d %H:%M:%S"))..") [NLapi]: " .. str)
end

local socket = require("socket") log("imported "..socket._VERSION)--import socket
local json = require("dkjson") log("imported "..json.version)--import json

--server stuff
local server = socket.tcp()log("starting server..")
server:setoption("reuseaddr", true)--enable reusing the address
server:bind("127.0.0.1", conf.port)log("server started at 127.0.0.1:"..conf.port)
server:listen()log("server listening")

log("making endpoints")

--[[
             !ENDPOINT MANAGEMENT!
    this is where you will make your endpoints
    basically:
    *You make a function for the endpoint.
    *you use the addRoute function.
     >specify the endpoint function and the endpoint URL here
    
    that's literally it. there's better ways of implimentation
    but i wanted this to be kind of dynamic, and also only use lua.

    hope you like it!
]]--

local routes = {}--table to store routes


--function to register a route
local function addRoute(path, handler)
    routes[path] = handler log("made endpoint "..path)
end

--web formatter, to make this simple
local function webFormat(type, data)
    return "HTTP/1.1 200 OK\r\nContent-Type: "..type.."\r\n\r\n"..data.."\r\n"
end

--endpoint / (root)
local function root(client)
    --get all endpoints on request
    local endpointData = {}
    for path, _ in pairs(routes) do
        if path ~= "/" then
            table.insert(endpointData, path)
        end
    end

    --define what will be on the json response
    local responseData = {
        message = {
            "Hello, world!",
            "This is the root endpoint for the NLapi.",
            "You can add more endpoints in the code.",
            "You can also change this root page to your hearts content!"
        },

        sincerely = {
            '::::    ::::',
            ':+:+:   :++:',
            ':+:+:+  +::+',
            '+#+ +:+ +##+',
            '+#+ +#+ +#+#',
            '#+#   #+#++#',
            '###    ############'
        },

        endpoints = endpointData
    }
    --format the json response data that we provided into a web response
    local response = webFormat('application/json', json.encode(responseData))
    --send the response to the client and close the connection
    client:send(response) client:close()
end

--register all endpoints
addRoute("/", root)

log('all endpoints registered')

--handle the requests
local function handleRequest(client)
    local requestLine = client:receive()
    local _, _, method, path = requestLine:find("(%u+)%s+(/%S*)")
    local handler = routes[path]
    log('request recieved for "'..path..'"  with method '..method)
    if handler then
        handler(client)
        log("request was handled.")
    else--will be sent on a 404.
        log("request was unhandled. sent 404")
        local a404s = {"couldn't find that page","that page doesn't exist","what are you trying to find?","that's not an endpoint","this isn't real. nothing is real."}
        local responseData = {code="404 - "..a404s[math.random(1,#a404s)]}
        local response = webFormat('application/json', json.encode(responseData))
        client:send(response)
        client:close()
        end
end


log("started requestLog")
while true do
    local client = server:accept()--accept all connections
    client:settimeout(10)--set timeout to prevent connection from hanging forever

    local co = coroutine.create(function()
        local success, err = pcall(handleRequest, client)
        if not success then
            log("error handling request!  ("..tostring(err)..")")
        end
        client:close()--close connection after handling request
    end)
    coroutine.resume(co)
end
