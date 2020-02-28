startupmodule = {name: "startupmodule", uimodule: false}
############################################################
#region printLogFunctions
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["startupmodule"]?  then console.log "[startupmodule]: " + arg
    return
print = console.log
#endregion

############################################################
installProcess = null

############################################################
startupmodule.initialize = () ->
    log "startupmodule.initialize"
    installProcess = allModules.installprocessmodule
    return

############################################################
startupmodule.appStartup = ->
    log "startupmodule.appStartup"
    try
        update = process.argv[2]
        await installProcess.execute(update)
        print('All done!\n');
    catch err
        print('Error!');
        print(err)
        print("\n")

export default startupmodule