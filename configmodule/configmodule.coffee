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
    try 
        readInstallDigest()
        readWebhookConfig()
    catch err
        log "could not read {"+digestPath+" or "+webhookConfigPath+"}!"
        log err
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
configmodule.commanderSocketPath = "/run/commander.sk"
#endregion

############################################################
configmodule.writeInstallDigest = ->
    log "configmodule.writeInstallDigest"
    # console.log JSON.stringify(configmodule.installDigest, null, 2)
    digestString = JSON.stringify(configmodule.installDigest, null, 2)
    fs.writeFileSync(digestPath, digestString)
    return

export default configmodule
