debugmodule = {name: "debugmodule", uimodule: false}

debugmodule.debugMode = false

##initialization function  -> is automatically being called!  ONLY RELY ON DOM AND VARIABLES!! NO PLUGINS NO OHTER INITIALIZATIONS!!
debugmodule.initialize = () ->
    # console.log "debugmodule.initialize - nothing to do"
    return
    
debugmodule.modulesToDebug = 
    unbreaker: true
    # configmodule: true
    # deploymentusermodule: true
    # githubremotemodule: true
    # hashermodule: true
    # installerhandlermodule: true
    installprocessmodule: true
    # servicefilesmodule: true
    # startupmodule: true
    utilmodule: true
    
#region exposed variables

export default debugmodule
