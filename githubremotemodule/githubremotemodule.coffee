githubremotemodule = {name: "githubremotemodule"}

#log Switch
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["githubremotemodule"]?  then console.log "[githubremotemodule]: " + arg
    return

#region internal variables
minURLLength = 20
githubSSHBase = "git@github.com"
githubHTTPSBase = "https://github.com"
#endregion

#region exposed variables
#endregion


##initialization function  -> is automatically being called!  ONLY RELY ON DOM AND VARIABLES!! NO PLUGINS NO OHTER INITIALIZATIONS!!
githubremotemodule.initialize = () ->
    log "githubremotemodule.initialize"

#region classes
class githubRemoteObject
    constructor: (@owner, @repoName) ->
        @httpsURL = githubHTTPSBase + "/" + @owner + "/" + @repoName + ".git"
        @sshURL = githubSSHBase + ":" + @owner + "/" + @repoName + ".git"

    getOwner: -> @owner

    getRepo: -> @repoName

    getHTTPS: -> @httpsURL

    getSSH: -> @sshURL

#endregion

#region internal functions
extractRepoDataFromURL = (url) ->
    repo = {}
    if typeof url != "string"
        throw new Error("URL to Extract Repo from not a string!")
    if !url
        throw new Error("URL to Extract Repo from was an empty String!")
    if url.length < minURLLength 
        throw new Error("URL to Extract Repo was smaller than the minimum of " + minURLLength + " characters!")
    endPoint = url.lastIndexOf(".")
    if endPoint < 0
        throw new Error("Unexpectd URL for github repository: " + url)
    lastSlash = url.lastIndexOf("/")
    if lastSlash < 0
        throw new Error("Unexpectd URL for github repository: " + url)
    repo.repoName = url.substring(lastSlash + 1, endPoint)
    checker = url.substr(0,8)
    if checker == "https://"
        secondLastSlash = url.lastIndexOf("/", lastSlash - 1)
        if (secondLastSlash < 8)
            throw new Error("Unexpectd URL for github repository: " + url)
        repo.owner = url.substring(secondLastSlash + 1, lastSlash)
    else if checker == "git@gith"
        lastColon = url.lastIndexOf(":", lastSlash - 1)
        if lastColon < 14
            throw new Error("Unexpectd URL for github repository: " + url)
        repo.owner = url.substring(lastColon + 1, lastSlash)
    else
        throw new Error("Unexpectd URL for github repository: " + url)
    return repo
#endregion

#region exposed functions
githubremotemodule.createRemoteFromURL = (url) ->
    repo = extractRepoDataFromURL(url)
    return new githubRemoteObject(repo.owner, repo.repoName)

githubremotemodule.createRemote = (ownerOrURL, repoName) ->
    if repoName
        return new githubRemoteObject(ownerOrURL, repoName)
    else
        repo = extractRepoDataFromURL(ownerOrURL)
        return new githubRemoteObject(repo.owner, repo.repoName)    
#endregion

module.exports = githubremotemodule