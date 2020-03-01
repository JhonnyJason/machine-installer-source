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
        executorScript:
            path: "executor.pl"
        webhookConfig:
            path: "webhook-config.json"
        privateKey:
            path:  "keys/" + thingy.repository
        executorSocketFile:
            path: "service-files/executor.socket"
        executorServiceFile:
            path: "service-files/executor.service"
        installerServiceFile:
            path: "service-files/installer.service"
    return await hasher.hashAllFiles(allFiles)

############################################################
installerhandlermodule.copyKeys = (thingy) ->
    log "installerhandler.copyKeys"
    ##copy key
    privateKey = "keys/" + thingy.repository
    destPath = "/root/.ssh/id_git_rsa"
    await utl.executeCP(privateKey, destPath)    
    return

installerhandlermodule.copyFiles = ->
    log "installerhandler.copyFiles"
    ##copy executor
    executorFile = "executor.pl"
    destPath = "/root/executor.pl"
    p1 = utl.executeCP(executorFile, destPath)
    ##copy webhook-config
    configFile = "webhook-config.json"
    destPath = "/home/webhook-handler/webhook-config.json"
    p2 = utl.executeCP(configFile, destPath)

    await Promise.all([p1, p2])
    return

############################################################
installerhandlermodule.removeFiles = ->
    log "installerhandler.removeFiles"
    ##copy executor
    executorFile = "/root/executor.pl"
    p1 = utl.executeRM(executorFile)
    ##copy webhook-config
    configFile = "/home/webhook-handler/webhook-config.json"
    p2 = utl.executeRM(configFile)
    
    try await Promise.all([p1, p2])
    catch err then return
    return

installerhandlermodule.prepareInstallerUser = (thingy) ->
    log "installerhandlermodule.prepareInstallerUser"
    script = "scripts/prepare-installer-user.pl" 

    reponame = thingy.repository 
    remoteObject = githubRemote.createRemote("JhonnyJason", reponame)
    remoteurl = remoteObject.getSSH()

    result = await utl.executePerl(script, reponame, remoteurl)
    return

installerhandlermodule.setUpSystemd = ->
    log "installerhandlermodule.setUpSystemd"
    script = "scripts/copy-and-run-service.pl" 
    p1 = utl.executePerl(script, "executor", "socket")
    p2 = utl.executePerl(script, "installer", "norun")
    await Promise.all([p1, p2])
    return

installerhandlermodule.stopRemoveService = ->
    log "installerhandlermodule.stopRemoveService"
    script = "scripts/stop-and-remove-service.pl"
    p1 = utl.executePerl(script, "executor", "socket")
    p2 = utl.executePerl(script, "installer", "norun")
    await Promise.all([p1, p2])
    return

#endregion exposed functions

export default installerhandlermodule