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


	BFMDirectoriesView = Backbone.View.extend
		el: $ 'directory-list'



	BFMUrls = Backbone.Router.extend
		initialize: (attrs) ->
			@path = ""
			@path = attrs.path if attrs? and attrs.path?
			@action = ""
			@action = attrs.action if attrs? and attrs.action?
		routes:
			'*path': 'do_browse'
		do_browse: (path) ->
			Table.clear()
			Table.draw_head('#fileBrowseHeadTemplate')
			Files = new BFMFiles()
			Files.fetch()
		goto: (action, path) ->
			@navigate "#{@path||path}", true



	Table = new BFMFileTableView()
	Route = new BFMUrls()
	Backbone.history.start()