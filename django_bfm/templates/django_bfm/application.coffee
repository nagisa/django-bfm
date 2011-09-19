#TODO: Sorting
#TODO: Pagination
#TODO: Uploading
#TODO: File Actions (Delete, Touch, Rename)
#TODO: Admin Applet
$ ->
	BFMFile = Backbone.Model.extend
		url: 'file/'


	BFMFiles = Backbone.Collection.extend
		url: 'list_files/'
		initialize: (attrs) ->
			@bind('reset', @added)
		model: BFMFile
		added: () ->
			_.forEach(@models, (model) ->
				new BFMFileView('model': model.attributes).render())


	BFMDirectories = Backbone.Collection.extend
		url: 'list_directories/'
		initialize: (attrs) ->
			@bind('reset', @added)
		added: () ->
			_.forEach(@models, (model) ->
				new BFMDirectoryView({'model': model.attributes}).render()
				)

	BFMFileTableView = Backbone.View.extend
		el: $ '#result_list'
		current_row: 1
		clear: () ->
			@current_row = 1
			@el.html ''
			@append($('<thead/>').append($('<tr/>')))
		append: (element) ->
			@el.append element
		prepend: (element) ->
			@el.prepend element
		draw_head: (template) ->
			@el.find('tr:first').append($('#fileBrowseHeadTemplate').tmpl())
		get_row_class: () ->
			@current_row = ((@current_row+1)%2)
			return "row#{@current_row+1}"


	BFMDirectoriesView = Backbone.View.extend
		el: $ '.directory-list'
		append: (elm) ->
			@el.append(elm)


	BFMDirectoryView = Backbone.View.extend
		tagName: 'li'
		initialize: (attrs) ->
			@model = attrs.model
			@el = $ @el
		render: () ->
			Dirs.append @srender()
		srender: () ->
			@el.html "<a>#{@model.name}</a>"
			if @model.childs?
				child = new BFMChildDirectoriesView({'childs': @model.childs, 'parent': @})
				child.render()
			return @el
		append: (element) ->
			@el.append element


	BFMChildDirectoriesView = Backbone.View.extend
		tagName: 'ul'
		initialize: (attrs) ->
			@el = $ @el
			@childs = attrs.childs
			@parent = attrs.parent
		render: () ->
			callback = (child) ->
				directory = new BFMDirectoryView({'model': child})
				@parent.append(@el.append(directory.srender()))
			_.forEach(@childs, callback, @)


	BFMFileView = Backbone.View.extend
		tagName: 'tr'
		className: ->
			Table.get_row_class()
		initialize: (attrs) ->
			@table = Table
			@model = attrs.model
		render: () ->
			elm = $(this.el).html($('#fileBrowseTemplate').tmpl(@model))
			@table.append elm


	BFMUrls = Backbone.Router.extend
		initialize: (attrs) ->
			@path = ""
			@path = attrs.path if attrs? and attrs.path?
		routes:
			'*path': 'do_browse'
		do_browse: (path) ->
			# Drawing filetable
			Table.clear()
			Table.draw_head('#fileBrowseHeadTemplate')
			Files = new BFMFiles()
			Files.fetch()
			# Drawing directories here
			D = new BFMDirectories
			D.fetch()
		goto: (action, path) ->
			@navigate "#{@path||path}", true


	Table = new BFMFileTableView()
	Dirs = new BFMDirectoriesView()
	Route = new BFMUrls()
	Backbone.history.start()