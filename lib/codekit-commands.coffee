applescript = require('../inc/node-applescript/applescript');
$ = require('../inc/jquery-2.1.4.min.js');
{Disposable, CompositeDisposable} = require 'atom'

module.exports =
	config:
		autoPause:
			title: 'Auto Pause Codekit Filewatching'
			description: 'Auto pause/unpause Codekit file watching when Atom window is/isn\'t in focus'
			type: 'boolean'
			default: true
		autoStart:
			title: 'Auto Start Codekit'
			description: 'Auto start Codekit when Atom window is opened'
			type: 'boolean'
			default: true
		autoQuit:
			title: 'Auto Quit Codekit'
			description: 'Auto quit Codekit when Atom window is closed'
			type: 'boolean'
			default: true
		autoSwitch:
			title: 'Auto Switch Codekit Project'
			description: 'Auto switch Codekit project on file change'
			type: 'boolean'
			default: true

	subscriptions: null

	activate: ->
		@subscriptions = new CompositeDisposable
		@subscriptions.add atom.commands.add 'atom-workspace', 'codekit-commands:previewProject': => @previewProject()
		@subscriptions.add atom.commands.add 'atom-workspace', 'codekit-commands:refreshProject': => @refreshProject()
		@subscriptions.add atom.commands.add '.project-root > .header', 'codekit-commands:addProject': => @addProject()
		@subscriptions.add atom.workspace.onDidChangeActivePaneItem (callback) => @autoSwitchProject(callback)
		$(window).on 'load', @startCodekit
		$(window).on 'unload', @quitCodekit
		$(window).on 'blur', @pauseProject
		$(window).on 'focus', @unpauseProject

		@startCodekit()

	startCodekit: ->
		if atom.config.get('codekit-commands.autoStart')
			@switchProject(atom.workspace.getActivePaneItem())
			script = 'tell application "CodeKit" to launch'
			applescript.execString(script)

	quitCodekit: ->
		if atom.config.get('codekit-commands.autoQuit')
			script = 'tell application "CodeKit" to quit'
			applescript.execString(script)

	previewProject: ->
		@switchProject(atom.workspace.getActivePaneItem())
		script = 'tell application \"CodeKit\" to preview in browser'
		applescript.execString(script)

	refreshProject: ->
		@switchProject(atom.workspace.getActivePaneItem())
		script = 'tell application \"CodeKit\" to refresh browsers'
		applescript.execString(script)

	addProject: ->
		treeView = atom.packages.getLoadedPackage('tree-view');
		treeView = require(treeView.mainModulePath);
		packageObj = treeView.serialize();
		script = "tell application \"CodeKit\" to add project at path \"#{packageObj.selectedPath}\""
		applescript.execString(script)

	switchProject: (newPanel) ->
		if newPanel
			if newPanel.buffer
				if newPanel.buffer.file
					script = "tell application \"CodeKit\" to select project containing path \"#{newPanel.buffer.file.path}\""
					applescript.execString(script)

	autoSwitchProject: (newPanel) ->
		if atom.config.get('codekit-commands.autoSwitch')
			@switchProject(newPanel)

	pauseProject: ->
		if atom.config.get('codekit-commands.autoPause')
			script = "tell application \"CodeKit\" to pause file watching"
			applescript.execString(script)

	unpauseProject: ->
		if atom.config.get('codekit-commands.autoPause')
			script = "tell application \"CodeKit\" to unpause file watching"
			applescript.execString(script)

	deactivate: ->
		@subscriptions.dispose()
		$(window).off 'load', @startCodekit
		$(window).off 'unload', @quitCodekit
		$(window).off 'blur', @pauseProject
		$(window).off 'focus', @unpauseProject