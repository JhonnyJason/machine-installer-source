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
webhookConfigPath = "webhook-config.json"

############################################################
configmodule.initialize = () ->
    log "configmodule.initialize"
    try readInstallDigest()
    catch err then log "could not read: " + digestPath + "!\n"+err
    try readWebhookConfig()
    catch err then log "could not read: "+webhookConfigPath+"!\n"+err
    return

############################################################
readInstallDigest = ->
    log "readInstallDigest"
    digestString = String(fs.readFileSync(digestPath))
    configmodule.installDigest = JSON.parse(digestString)
    return

readWebhookConfig = ->
    webhookConfigString = String(fs.readFileSync(webhookConfigPath))
    webhookConfig = JSON.parse(webhookConfigString)
    configmodule.commandMap = webhookConfig.commandMap
    if !configmodule.commandMap then throw "WebhookConfig had no commandMap!" 
    return

############################################################
#region exposedVariables
configmodule.thingies = machineConfig.thingies
configmodule.installDigest = {}
configmodule.executorSocketPath = "/run/executor.sk"
#endregion

############################################################
configmodule.writeInstallDigest = ->
    log "configmodule.writeInstallDigest"
    # console.log JSON.stringify(configmodule.installDigest, null, 2)
    digestString = JSON.stringify(configmodule.installDigest, null, 2)
    fs.writeFileSync(digestPath, digestString)
    return

export default configmodule
