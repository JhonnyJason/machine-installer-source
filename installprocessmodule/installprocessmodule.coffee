installprocessmodule = {name: "installprocessmodule", uimodule: false}
############################################################
#region logPrintFunctions
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["installprocessmodule"]?  then console.log "[installprocessmodule]: " + arg
    return
print = console.log
#endregion

############################################################
fs = require "fs"

############################################################
#region localModules
cfg = null
utl = null
hasher = null
installer = null
deploymentUser = null
#endregion

############################################################
#region internalProperties
installerThingy = null
installerDigest = null
updateCodes = []
#endregion

############################################################
installprocessmodule.initialize = () ->
    log "installprocessmodule.initialize"
    utl = allModules.utilmodule
    cfg = allModules.configmodule
    hasher = allModules.hashermodule
    installer = allModules.installerhandlermodule
    deploymentUser = allModules.deploymentusermodule
    return

############################################################
#region internalFunctions
installProcess = ->
    log "installProcess"
    cfg.installDigest = {}
    promises = (installThingy(thingy) for thingy in cfg.thingies)
    olog cfg.thingies
    await Promise.all(promises)
    print "I was here !!! - - - - - - - - - - !!!"
    await installInstaller(installerThingy)
    print "I was here after !!! - - - - - - - - - - !!!"
    cfg.writeInstallDigest()
    return

updateProcess = ->
    log "updateProcess"
    oldDigest = cfg.installDigest
    cfg.installDigest = {}
    installedHomeUsers = Object.keys(oldDigest)
    promises = []

    #collect all promises on  update or install 
    for thingy in cfg.thingies
        if oldDigest[thingy.homeUser]
            promises.push(updateThingy(thingy, oldDigest[thingy.homeUser]))
            oldDigest[thingy.homeUser].updating = true
        else # just install what we did not have installed
            promises.push(installThingy(thingy))
    #collect all promises on remove
    for user in installedHomeUsers
        if !oldDigest[user].updating
            oldDigest[user].homeUser = user
            promises.push(removeThingyForDigest(oldDigest[user]))
        else delete oldDigest[user].updating

    await Promise.all(promises)
    await updateInstaller(installerThingy, installerDigest)
    cfg.writeInstallDigest()
    return

certSetup = ->
    log "certSetup"
    for thingy in cfg.thingies
        await certInstallFor(thingy)
    # appearently we cannot run certbot in parallel
    # promises = (certInstallFor(thingy) for thingy in cfg.thingies)
    # await Promise.all(promises)
    return

certInstallFor = (thingy) ->
    log "certInstallFor"
    return if thingy.type == "installer"
    return if thingy.plainHTTP
    return unless thingy.dnsNames
    domains = thingy.dnsNames.join()
    await utl.executeCertbot(thingy.homeUser, domains, thingy.outsidePort)
    return 

sendUpdateCodes = ->
    log "sendUpdateCodes"
    updateCodes = updateCodes.flat()
    writeCommand("0\n")
    writeCommand(""+code+"\n") for code in updateCodes
    writeCommand("-1\n")
    return

writeCommand = (command) ->
    log "writeCommand"
    log command
    try
        openSocket = fs.openSync cfg.executorSocketPath, 'a'
        fs.appendFileSync openSocket, command
    catch err
        print 'Command could not be written to socket!'
    return

addAllUpdateCodes = () ->
    log "addAllUpdateCodes"
    addUpdateCodeFor(thingy) for thingy in cfg.thingies
    return
    
addUpdateCodeFor = (thingy) ->
    log "addUpdateCodeFor"
    code = cfg.commandMap[thingy.repository]
    if updateCodes.includes(code) then return
    updateCodes.push(code)
    return

############################################################
#region installerFunctions
installThingy = (thingy) ->
    log "installThingy"
    switch(thingy.type)
        when "installer" then installerThingy = thingy
        when "website" then await installWebsite(thingy)
        when "service" then await installService(thingy)
        else log "We encountered a unknown type: " + thingy.type
    addUpdateCodeFor(thingy)
    return

############################################################
#region specificInstallerFunctions
installInstaller = (thingy) ->
    log "installInstaller"
    return unless (thingy and thingy.homeUser == "root")
    try
        cfg.installDigest[thingy.homeUser] = {type:"installer"}
        await installer.prepareInstallerUser(thingy)
        await installer.setUpSystemd()
        await installer.copyFiles()
        digest = await installer.generateInstallerFileDigest(thingy)
        Object.assign(cfg.installDigest[thingy.homeUser], digest)
        cfg.installDigest[thingy.homeUser].selfHash = hasher.hashObject(thingy)
        cfg.installDigest[thingy.homeUser].success = true
        print "successfull install: " + thingy.homeUser
    catch err
        print "could not install: " + thingy.homeUser
        print err
        cfg.installDigest[thingy.homeUser].success = false
    return

installWebsite = (thingy) ->
    log "installWebsite"
    try
        cfg.installDigest[thingy.homeUser] = {type:"website"}
        await deploymentUser.setUpUser(thingy)
        await deploymentUser.createSymlinkForNginx(thingy)
        await deploymentUser.copyNginxConfig(thingy)
        digest = await deploymentUser.generateWebsiteFilesDigest(thingy)
        Object.assign(cfg.installDigest[thingy.homeUser], digest)
        cfg.installDigest[thingy.homeUser].selfHash = hasher.hashObject(thingy)
        cfg.installDigest[thingy.homeUser].success = true
        print "successfull install: " + thingy.homeUser
    catch err
        print "could not install: " + thingy.homeUser
        print err
        cfg.installDigest[thingy.homeUser].success = false
    return

installService = (thingy) ->
    log "installService"
    try
        cfg.installDigest[thingy.homeUser] = {type:"service"}
        await deploymentUser.setUpUser(thingy)
        await deploymentUser.setUpSystemd(thingy)
        await deploymentUser.copyNginxConfig(thingy)
        digest = await deploymentUser.generateServiceFilesDigest(thingy)
        Object.assign(cfg.installDigest[thingy.homeUser], digest)
        cfg.installDigest[thingy.homeUser].selfHash = hasher.hashObject(thingy)
        if thingy.socket then cfg.installDigest[thingy.homeUser].socket = true
        cfg.installDigest[thingy.homeUser].success = true
        print "successfull install: " + thingy.homeUser
    catch err
        print "could not install: " + thingy.homeUser
        print err
        cfg.installDigest[thingy.homeUser].success = false
    return

#endregion

#endregion

############################################################
#region removeFunctions 
removeThingy = (thingy) ->
    log "removeThingy"
    switch(thingy.type)
        when "installer" then await removeInstaller(thingy)
        when "website" then await removeWebsite(thingy)
        when "service" then await removeService(thingy)
        else log "We encountered a unknown type: " + thingy.type
    return

############################################################
#region specificRemoveFunctions
removeInstaller = (thingy) ->
    log "removeInstaller"
    try
        if thingy.homeUser != "root" then throw new Error("User of installer is not root!")
        await installer.stopRemoveService()
        await installer.removeFiles() 
        print "successfull remove: " + thingy.homeUser
    catch err
        print "could not remove: " + thingy.homeUser
        print err
    return

removeWebsite = (thingy) ->
    log "removeWebsite"
    try
        await deploymentUser.removeUser(thingy)
        print "successfull remove: " + thingy.homeUser
    catch err
        print "could not remove: " + thingy.homeUser
        print err
    return

removeService = (thingy) ->
    log "removeService"
    try
        await deploymentUser.stopRemoveService(thingy)
        await deploymentUser.removeUser(thingy)
        print "successfull remove: " + thingy.homeUser
    catch err
        print "could not remove: " + thingy.homeUser
        print err
    return

#endregion

#endregion

############################################################
#region updateFunctions
updateThingy = (thingy, digest) ->
    log "updatethingy"
    switch(thingy.type)
        when "installer"
            installerThingy = thingy
            installerDigest = digest 
        when "website" then await updateWebsite(thingy, digest)
        when "service" then await updateService(thingy, digest)
        else log "We encountered an unknown type: " + thingy.type
    return

removeThingyForDigest = (digest) ->
    log "removeThingyForDigest"
    fakeThingy = 
        type: digest.type
        homeUser: digest.homeUser
    if digest.socket then fakeThingy.socket = true
    await removeThingy(fakeThingy)

############################################################
#region specificUpdateFunctions
updateInstaller = (thingy, digest) ->
    log "updateInstaller"
    try
        cfg.installDigest[thingy.homeUser] = {type:"installer"}
        newFileDigest = await installer.generateInstallerFileDigest(thingy)
        newHash = hasher.hashObject(thingy)
        if digest.selfHash != newHash or digest.success == false
            await removeInstaller(thingy)
            await installInstaller(thingy)
            return
        
        if newFileDigest.executorScript.hash != digest.executorScript.hash or  newFileDigest.webhookConfig.hash != digest.webhookConfig.hash
            await installer.copyFiles()
            print "successfull file update: " + thingy.homeUser
        
        if newFileDigest.executorScript.hash != digest.executorScript.hash then addAllUpdateCodes()

        if newFileDigest.privateKey.hash != digest.privateKey.hash
            await installer.copyKeys(thingy)
            print "successfull key update: " + thingy.homeUser

        if newFileDigest.executorSocketFile.hash != digest.executorSocketFile.hash or newFileDigest.executorServiceFile.hash != digest.executorServiceFile.hash or newFileDigest.installerServiceFile.hash != digest.installerServiceFile.hash
            await installer.stopRemoveService()
            await installer.setUpSystemd()
            print "successfull systemd update: " + thingy.homeUser
    
        Object.assign(digest, newFileDigest)
        cfg.installDigest[thingy.homeUser] = digest

        cfg.installDigest[thingy.homeUser].success = true
    catch err
        print "could not install: " + thingy.homeUser
        print err
        cfg.installDigest[thingy.homeUser].success = false
    return

updateWebsite = (thingy, digest) ->
    log "updateWebsite"
    try
        cfg.installDigest[thingy.homeUser] = {type:"website"}
        newFileDigest = await deploymentUser.generateWebsiteFilesDigest(thingy)
        newHash = hasher.hashObject(thingy)
        if digest.selfHash != newHash or digest.success == false
            await removeWebsite(thingy)
            await installWebsite(thingy)
            addUpdateCodeFor(thingy)
            return
        
        if newFileDigest.nginxConfig.hash != digest.nginxConfig.hash
            await deploymentUser.copyNginxConfig(thingy)
            print "successfull nginx-config update: " + thingy.homeUser
        
        if newFileDigest.privateKey.hash != digest.privateKey.hash
            await deploymentUser.copyKeys(thingy) 
            print "successfull key update: " + thingy.homeUser

        Object.assign(digest, newFileDigest)
        cfg.installDigest[thingy.homeUser] = digest
        cfg.installDigest[thingy.homeUser].success = true
    catch err
        print "could not install: " + thingy.homeUser
        print err
        cfg.installDigest[thingy.homeUser].success = false
    return

updateService = (thingy, digest) ->
    log "updateService"
    try
        cfg.installDigest[thingy.homeUser] = {type:"service"}
        newFileDigest = await deploymentUser.generateServiceFilesDigest(thingy)
        newHash = hasher.hashObject(thingy)
        if digest.selfHash != newHash or digest.success == false
            await removeService(thingy)
            await installService(thingy)
            addUpdateCodeFor(thingy)
            return
        
        if newFileDigest.nginxConfig.hash != digest.nginxConfig.hash
            await deploymentUser.copyNginxConfig(thingy)
            print "successfull nginx-config update: " + thingy.homeUser

        if newFileDigest.privateKey.hash != digest.privateKey.hash
            await deploymentUser.copyKeys(thingy)
            print "successfull key update: " + thingy.homeUser

        if (newFileDigest.socketFile?  != digest.socketFile?) or (newFileDigest.socketFile? and (newFileDigest.socketFile.hash != digest.socketFile.hash)) or newFileDigest.serviceFile.hash != digest.serviceFile.hash
            await deploymentUser.stopRemoveService(thingy)
            await deploymentUser.setUpSystemd(thingy)
            print "successfull  systemd update: " + thingy.homeUser

        if digest.socket then delete digest.socket
        if thingy.socket then digest.socket = true

        Object.assign(digest, newFileDigest)
        cfg.installDigest[thingy.homeUser] = digest
        cfg.installDigest[thingy.homeUser].success = true
    catch err
        print "could not install: " + thingy.homeUser
        print err
        cfg.installDigest[thingy.homeUser].success = false
    return

#endregion

#endregion

#endregion

############################################################
installprocessmodule.execute = (update) ->
    log "installprocessmodule.execute"
    
    if update == "update"
        print "Execute Update Process"
        await updateProcess()
    else
        print "Execute Install Process"
        await installProcess()

    print "doing reload nginx..."
    await utl.executeNginxReload()
    print "doing systemd daemon-reload..."
    await utl.executeSystemDaemonReload()
    print "doing cert setup..."
    await certSetup()
    
    print "sending updateCodes... " + updateCodes
    sendUpdateCodes()

    return true
    
export default installprocessmodule