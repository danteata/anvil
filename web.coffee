builder  = require("builder")
coffee   = require("coffee-script")
crypto   = require("crypto")
express  = require("express")
fs       = require("fs")
manifest = require("manifest")
storage  = require("storage").init()
util     = require("util")

app = express.createServer(
  express.logger(),
  express.bodyParser())

app.get "/", (req, res) ->
  res.send "ok"

app.post "/build", (req, res) ->
  builder.init().build_request req, res

app.get "/cache/:id.tgz", (req, res) ->
  storage.get "/cache/#{req.params.id}.tgz", (err, get) ->
    get.on "data", (chunk) -> res.write chunk
    get.on "end",          -> res.end()

app.put "/cache/:id.tgz", (req, res) ->
  storage.create_stream "/cache/#{req.params.id}.tgz", fs.createReadStream(req.files.data.path), (err) ->
    res.send("ok")

app.get "/file/:hash", (req, res) ->
  storage.get "/hash/#{req.params.hash}", (err, get) ->
    res.writeHead get.statusCode,
      "Content-Length": get.headers["content-length"]
    get.on "data", (chunk) -> res.write chunk
    get.on "end",          -> res.end()

app.post "/file/:hash", (req, res) ->
  storage.verify_hash req.files.data.path, req.params.hash, (err) ->
    return res.send(err, 403) if err
    storage.create_stream "/hash/#{req.params.hash}", fs.createReadStream(req.files.data.path), (err) ->
      res.send "ok"

app.post "/manifest", (req, res) ->
  manifest.init(JSON.parse(req.body.manifest)).save (err, manifest_url) ->
    res.header "Location", manifest_url
    res.send "ok"

app.post "/manifest/build", (req, res) ->
  manifest.init(JSON.parse(req.body.manifest)).save (err, manifest_url) ->
    delete req.body.manifest
    req.body.source = manifest_url
    builder.init().build_request req, res

app.post "/manifest/diff", (req, res) ->
  manifest.init(JSON.parse(req.body.manifest)).missing_hashes (hashes) ->
    res.contentType "application/json"
    res.send JSON.stringify(hashes)

app.get "/manifest/:id.json", (req, res) ->
  storage.get "/manifest/#{req.params.id}.json", (err, get) =>
    get.on "data", (chunk) -> res.write chunk
    get.on "end",          -> res.end()

app.get "/slugs/:id.img", (req, res) ->
  storage.get "/slug/#{req.params.id}.img", (err, get) ->
    get.on "data", (chunk) -> res.write chunk
    get.on "end",          -> res.end()

app.get "/slugs/:id.tgz", (req, res) ->
  storage.get "/slug/#{req.params.id}.tgz", (err, get) ->
    get.on "data", (chunk) -> res.write chunk
    get.on "end",          -> res.end()

port = process.env.PORT || 5000

app.listen port, ->
  console.log "listening on port #{port}"
