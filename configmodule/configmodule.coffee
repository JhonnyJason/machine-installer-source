configmodule = {name: "configmodule", uimodule: false}
############################################################
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["configmodule"]?  then console.log "[configmodule]: " + arg
    return

############################################################
fs = require("fs")
machineConfig  = require("../../../sources/machine-config")

############################################################
digestPath = "install-digest.json"

############################################################
configmodule.initialize = () ->
    log "configmodule.initialize"
    try readInstallDigest()
    catch err
        log "could not read install Digest!"
        log err
    return

############################################################
readInstallDigest = ->
    log "readInstallDigest"
    digestString = String(fs.readFileSync(digestPath))
    configmodule.installDigest = JSON.parse(digestString)
    return

############################################################
#region exposedVariables
configmodule.thingies = machineConfig.thingies
configmodule.installDigest = {}
#endregion

############################################################
configmodule.writeInstallDigest = ->
    log "configmodule.writeInstallDigest"
    # console.log JSON.stringify(configmodule.installDigest, null, 2)
    digestString = JSON.stringify(configmodule.installDigest, null, 2)
    fs.writeFileSync(digestPath, digestString)
    return

export default configmodule
