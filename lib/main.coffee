{CompositeDisposable} = require 'atom'
path = require 'path'
promiseHelper = require './promise-helper'

module.exports =

  config:
    enabled:
      title: 'Enabled live reload [Only on Developer Mode]'
      type: 'boolean'
      default: false
      order: 1
    grammarsPackageName:
      title: 'Name of the package to grammars reload [Only on Developer Mode]'
      description: 'ex: `language-git`'
      type: 'string'
      default: ''
      order: 2

  subscriptions: null
  liveReloadSubscriptions: null
  debug: false

  activate: (state) ->
    return unless atom.inDevMode() and not atom.inSpecMode()

    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.config.observe 'grammar-live-reload.enabled', (newValue) =>
      if newValue
        @liveReloadSubscriptions = new CompositeDisposable
        @startliveReload()
      else
        @liveReloadSubscriptions?.dispose()

  startliveReload: ->
    if atom.inDevMode() and not atom.inSpecMode() and atom.config.get 'grammar-live-reload.enabled'
      @liveReloadSubscriptions.add atom.workspace.observeTextEditors (editor) =>
        if editor.getTitle()?.endsWith '.cson'
          editor.buffer.onDidSave =>
            @reload()

  reload: ->
    return unless atom.config.get('grammar-live-reload.enabled')

    grammarsPackageName = atom.config.get 'grammar-live-reload.grammarsPackageName'
    return unless grammarsPackageName?

    promises = atom.project.rootDirectories.map (rootDir) =>
      packageJsonPath = path.join rootDir.path, 'package.json'

      promiseHelper.fileExists(packageJsonPath)
        .then (filepath) =>
          promiseHelper.readCsonFile(filepath)
            .then (projectPackage) =>
              if projectPackage.name is grammarsPackageName
                promiseHelper.getDirectoryEntries path.join rootDir.path, 'grammars'
                  .then (entries) ->
                    # Gets project grammars
                    Promise.all(
                      entries.filter (entry) -> entry.isFile() and path.extname(entry.getBaseName()) is '.cson'
                        .map (entry) -> promiseHelper.readCsonFile(entry.path)
                    )
                  .then (grammars) ->
                    # Remove grammars
                    grammars.map (grammar) ->
                      {scopeName} = grammar
                      atom.grammars.removeGrammarForScopeName scopeName
                  .then ->
                    # Remove loaded package (Hack force reload)
                    delete atom.packages.loadedPackages[grammarsPackageName]

                    # Load package
                    # (use `loadGrammarsSync` instead of `loadGrammars` because `loadGrammars` doesn't work properly)
                    atom.packages.loadPackage(grammarsPackageName).loadGrammarsSync()
                  .then =>
                    # Reload grammars for each editor
                    atom.workspace.getTextEditors().forEach (editor) =>
                      if editor.getGrammar().packageName is grammarsPackageName
                        if @debug then console.log editor.getTitle()
                        atomVersion = parseFloat(atom.getVersion())
                        if atomVersion < 1.11
                          editor.reloadGrammar()
                        else
                          # Workaround because:
                          # - `reloadGrammar` is buggy before 1.11 (https://github.com/atom/atom/issues/13022)
                          # - `maintainGrammar` change this behavior and don't reload existing grammar.
                          #   - https://github.com/atom/atom/pull/12125
                          #   - https://github.com/atom/atom/blob/c844d0f099e6ed95c52f0b94e1f141759926aeb8/src/text-editor-registry.js#L201
                          atom.textEditors.setGrammarOverride(editor, 'text.plain')
                          atom.textEditors.clearGrammarOverride(editor)
                    Promise.resolve 'success'
              else
                Promise.resolve projectPackage.name + ' is not the right package.'
        .catch (error) =>
          if @debug then console.error error
          Promise.resolve packageJsonPath + " doesn't exists."

    Promise.all(promises)
      .then (msg) =>
        console.log 'Grammars reloaded.'
        if @debug then console.log msg
      .catch (error) ->
        console.log 'Grammars failed to reload.'
        console.error error

    deactivate: ->
      @subscriptions?.dispose()
      @liveReloadSubscriptions?.dispose()
