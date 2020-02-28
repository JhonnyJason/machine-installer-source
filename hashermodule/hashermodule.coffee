hashermodule = {name: "hashermodule"}

#region node_modules
fs = require "fs"
crypto = require "crypto"
#endregion

#log Switch
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["hashermodule"]?  then console.log "[hashermodule]: " + arg
    return

##initialization function  -> is automatically being called!  ONLY RELY ON DOM AND VARIABLES!! NO PLUGINS NO OHTER INITIALIZATIONS!!
hashermodule.initialize = () ->
    log "hashermodule.initialize"

#region internal functions
hashFile = (path) ->
    log "hashFile"
    log "path: " + path
    hash = crypto.createHash("sha1")
    hash.setEncoding("hex")
    fileStream = fs.createReadStream(path)

    return new Promise (resolve, reject) ->
        terminateHash = ->
            hash.end()
            resolve(hash.read())
        fileStream.on("end", terminateHash)
        fileStream.on("error", ((error) -> reject(error)))
        fileStream.pipe(hash)

#endregion

#region exposed functions
hashermodule.hashAllFiles = (files) ->
    log "hashermodule.hashAllFiles"
    for key, obj of files
        obj.hash = await hashFile(obj.path)
    # console.log JSON.stringify(files, null, 2)
    return files

hashermodule.hashObject = (target) ->
    log "hashermodule.hashObject"
    objectString = JSON.stringify(target)
    hash = crypto.createHash("sha1")
    hash.setEncoding("hex")
    hash.write(objectString)
    hash.end()
    return hash.read()
#endregion exposed functions

export default hashermodule