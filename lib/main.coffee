{readCsonFile} = require './promise-helper'
path = require 'path'

grammarRE = /\/language-[^\/]+\/(grammars|settings)\/[^\/]+\.(?:c|j)son$/

toUnix = (path) -> path.replace /\\/g, '/'

module.exports =

  config:
    enabled:
      title: 'Enable live reload (only in dev mode)'
      type: 'boolean'
      default: true
      order: 1

    blacklist:
      title: 'Disable live reload for specific grammars'
      description: 'eg: "language-git, language-swift"'
      type: 'string'
      default: ''
      order: 2

  configSub: null
  editorSub: null
  watching: Object.create null
  debug: false

  activate: (state) ->
    return if atom.inSpecMode() or not atom.inDevMode()

    @configSub = atom.config.observe 'grammar-live-reload.enabled', (enabled) =>
      return @editorSub?.dispose() unless enabled

      reload = @reload.bind this
      @editorSub = atom.workspace.observeTextEditors (editor) =>
        if grammarRE.test toUnix filePath = editor.getPath()

          # See if the file's package is blacklisted.
          if blacklist = atom.config.get 'grammar-live-reload.blacklist'

            # Assume the package directory name equals "name" in package.json
            packName = path.basename path.resolve filePath, '../..'

            # Support both comma-separated and space-separated names.
            for name in blacklist.split /(?:,\s*)|\s+/g
              if name is packName
                debug and console.log 'Package reload was prevented: ' + packName
                return

          # Avoid watching the same file twice.
          unless @watching[filePath]
            @debug and console.log 'Watching file for changes: ' + filePath
            @watching[filePath] = true
            editor.onDidSave reload
            editor.onDidDestroy =>
              delete @watching[filePath]

  reload: (event) ->
    {debug} = this

    packName = path.basename path.resolve event.path, '../..'
    unless pack = atom.packages.loadedPackages[packName]
      debug and console.log 'Package does not exist: ' + packName
      return

    # Unload the grammar package.
    debug and console.log 'Deactivating package: ' + packName
    atom.packages.deactivatePackage packName
    .then -> atom.packages.unloadPackage packName

    # Load the grammar package.
    .then ->
      debug and console.log 'Activating package: ' + packName
      atom.packages.activatePackage packName

    # Every grammar scope in the package has been reloaded,
    # so we need to update every editor that uses one of them.
    .then (pack) ->
      grammars = {}
      for grammar in pack.grammars
        grammars[grammar.scopeName] = grammar

      atom.workspace.getTextEditors().forEach (editor) ->
        grammar = editor.getGrammar()
        if grammar.packageName is packName
          debug and console.log 'Updating grammar for editor: ', editor
          editor.setGrammar grammars[grammar.scopeName]

    # Report any errors.
    .catch console.error

  deactivate: ->
    @configSub?.dispose()
    @editorSub?.dispose()
