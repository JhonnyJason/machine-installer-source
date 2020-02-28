###################################################################
# the Script
###################################################################
import Modules from "./modules.js"

global.allModules = Modules

for name, module of Modules
    module.initialize() 

Modules.startupmodule.appStartup()
    



