deploymentusermodule = {name: "deploymentusermodule", uimodule: false}
############################################################
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["deploymentusermodule"]?  then console.log "[deploymentusermodule]: " + arg
    return

############################################################
#region localModules
utl = null
githubRemote = null
hasher = null

#endregion

############################################################
deploymentusermodule.initialize = () ->
    log "deploymentusermodule.initialize"
    utl = allModules.utilmodule
    hasher = allModules.hashermodule
    githubRemote = allModules.githubremotemodule
    return

############################################################
#region exposedFunctions
deploymentusermodule.removeUser = (thingy) ->
    log "deploymentusermodule.removeUser"
    script = "scripts/remove-deployment-user.pl"
    username = thingy.homeUser        
    return await utl.executePerl(script, username)
    
deploymentusermodule.stopRemoveService = (thingy) ->
    log "deploymentusermodule.stopRemoveService"
    script = "scripts/stop-and-remove-service.pl"
    username = thingy.homeUser    
    
    if thingy.socket then result = await utl.executePerl(script, username, thingy.socket)
    else result = await utl.executePerl(script, username)
    return result

############################################################
deploymentusermodule.generateServiceFilesDigest = (thingy) ->
    log "deploymentusermodule.generateServiceFileDigest"
    allFiles = 
        nginxConfig:
            path: "nginx-files/" + thingy.homeUser
        privateKey:
            path:  "keys/" + thingy.repository
        serviceFile:
            path: "service-files/" + thingy.homeUser + ".service"
    
    if thingy.socket
        allFiles.socketFile = 
            path: "service-files/" + thingy.homeUser + ".socket"
    
    return await hasher.hashAllFiles(allFiles)

deploymentusermodule.generateWebsiteFilesDigest = (thingy) ->
    log "deploymentusermodule.generateDigestForCopiedFiles"
    allFiles = 
        nginxConfig:
            path: "nginx-files/" + thingy.homeUser
        privateKey:
            path:  "keys/" + thingy.repository
    return await hasher.hashAllFiles(allFiles)

############################################################
#region installFunctions
deploymentusermodule.setUpUser = (thingy) ->
    log "deploymentusermodule.setUpUser"
    script = "scripts/create-deployment-user.pl"
    username = thingy.homeUser
    reponame = thingy.repository 
    branch = thingy.branch
    remoteObject = githubRemote.createRemote("JhonnyJason", reponame)
    remoteurl = remoteObject.getSSH()

    result = await utl.executePerl(script, username, reponame, remoteurl, branch)
    return

deploymentusermodule.createSymlinkForNginx = (thingy) ->
    log "deploymentusermodule.setUpUser"
    script = "scripts/create-symlink-for-nginx.pl"
    username = thingy.homeUser
    reponame = thingy.repository 

    result = await utl.executePerl(script, username, reponame)

deploymentusermodule.copyNginxConfig = (thingy) ->
    log "deploymentusermodule.copyNginxConfig"
    script = "scripts/copy-server-config.pl"
    username = thingy.homeUser
    return await utl.executePerl(script, username)

deploymentusermodule.setUpSystemd = (thingy) ->
    log "deploymentusermodule.setUpSystemd"
    script = "scripts/copy-and-run-service.pl"
    username = thingy.homeUser    
    
    if thingy.socket then result = await utl.executePerl(script, username, thingy.socket)
    else result = await utl.executePerl(script, username)
    return result

deploymentusermodule.copyKeys = (thingy) ->
    log "deploymentusermodule.copyKeys"
    script = "scripts/copy-keys.pl"
    username = thingy.homeUser
    reponame = thingy.repository

    result = await utl.executePerl(script, username, reponame)

#endregion

#endregion exposed functions

export default deploymentusermodule