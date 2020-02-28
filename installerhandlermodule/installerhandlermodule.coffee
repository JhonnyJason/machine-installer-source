installerhandlermodule = {name: "installerhandlermodule"}
############################################################
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["installerhandlermodule"]?  then console.log "[installerhandlermodule]: " + arg
    return

############################################################
utl = null
hasher = null
githubRemote = null

############################################################
installerhandlermodule.initialize = () ->
    log "installerhandlermodule.initialize"
    utl = allModules.utilmodule
    hasher = allModules.hashermodule
    githubRemote = allModules.githubremotemodule
    return

############################################################
#region exposedFunctions
installerhandlermodule.generateInstallerFileDigest = (thingy) ->
    log "installerhandlermodule.generateDigestForCopiedFiles"
    allFiles = 
        commanderScript:
            path: "commander.pl"
        webhookConfig:
            path: "webhook-config.json"
        privateKey:
            path:  "keys/" + thingy.repository
        commanderSocketFile:
            path: "service-files/commander.socket"
        commanderServiceFile:
            path: "service-files/commander.service"
        installerServiceFile:
            path: "service-files/installer.service"
    return await hasher.hashAllFiles(allFiles)

############################################################
installerhandlermodule.copyKeys = (thingy) ->
    log "installerhandler.copyKeys"
    ##copy commander
    privateKey = "keys/" + thingy.repository
    destPath = "/root/.ssh/id_git_rsa"
    await utl.executeCP(commanderFile, destPath)    

installerhandlermodule.copyFiles = ->
    log "installerhandler.copyFiles"
    ##copy commander
    commanderFile = "commander.pl"
    destPath = "/root/commander.pl"
    p1 = utl.executeCP(commanderFile, destPath)
    ##copy webhook-config
    configFile = "webhook-config.json"
    destPath = "/home/webhook-handler/webhook-config.json"
    p2 = utl.executeCP(configFile, destPath)


    await Promise.all([p1, p2])

############################################################
installerhandlermodule.removeFiles = ->
    log "installerhandler.removeFiles"
    ##copy commander
    commanderFile = "/root/commander.pl"
    p1 = utl.executeRM(commanderFile)
    ##copy webhook-config
    configFile = "/home/webhook-handler/webhook-config.json"
    p2 = utl.executeRM(commanderFile)
    
    try await Promise.all([p1, p2])
    catch err then return

installerhandlermodule.prepareInstallerUser = (thingy) ->
    log "installerhandlermodule.prepareInstallerUser"
    script = "scripts/prepare-installer-user.pl" 

    reponame = thingy.repository 
    remoteObject = githubRemote.createRemote("JhonnyJason", reponame)
    remoteurl = remoteObject.getSSH()

    result = await utl.executePerl(script, reponame, remoteurl)

installerhandlermodule.setUpSystemd = ->
    log "installerhandlermodule.setUpSystemd"
    script = "scripts/copy-and-run-service.pl" 
    p1 = utl.executePerl(script, "commander", true)
    p2 = utl.executePerl(script, "installer")
    await Promise.all([p1, p2])
    return

installerhandlermodule.stopRemoveService = ->
    log "installerhandlermodule.stopRemoveService"
    script = "scripts/stop-and-remove-service.pl"
    p1 = utl.executePerl(script, "commander", true)
    p2 = utl.executePerl(script, "installer")
    await Promise.all([p1, p2])
    return

#endregion exposed functions

export default installerhandlermodule