DirectoryCollection = Backbone.Collection.extend
    # Collection responsible for all directory models.
    #
    # Methods:
    #
    # added - event callback, called everytime directory list changes.
    url: 'list_directories/'

    initialize: (attrs)->
        @bind('reset', @added)

    added: ()->
        _.forEach(@models, (model)=>
            DirectoryBrowser.sidebar.append_directory(model)
        )
        DirectoryBrowser.sidebar.set_active DirectoryBrowser.path


DirectoriesView = Backbone.View.extend
    # View responsible for whole sidebar of directories.
    #
    # Methods:
    #
    # append_directory - adds directory with all it's children to sidebar.
    # append_children - creates child directory tree.
    # set_active - makes directory responsible for some path to display it's
    #              activation.
    dirs: {}
    active_dir: null

    initialize: ()->
        @el = $ '.directory-list'

    append_directory: (model)->
        attr = model.attributes
        view = new DirectoryView('model': attr)
        @dirs[attr.rel_dir] = view
        @el.append view.srender()
        _.forEach(attr.children, (child)=>
            @append_children(child, view)
        )

    append_children: (model, parent_view)->
        attr = model
        view = new DirectoryView('model': attr)
        @dirs[attr.rel_dir] = view
        parent_view.append_child view.srender()
        _.forEach(attr.children, (child)=>
            @append_children(child, view)
        )

    set_active: (path)->
        if path
            if @active_dir
                @active_dir.deactivate()
            @active_dir = @dirs[path]
            @active_dir.activate()
        else if @active_dir
            @active_dir.deactivate()


DirectoryView = Backbone.View.extend
    # View responsible for one directory node.
    #
    # Methods:
    #
    # load_directory - event callback, called when user clicks on directory node
    # srender - renders directory node into element.
    # activate - changes directory node state from not active to active.
    # deactivate - changes directory node state from active to not active.
    # append_child - adds child node as descendent. Imitates tree structure.
    tagName: 'li'
    events:
        "click .directory": "load_directory"
    children_el: false

    initialize: (attrs)->
        @model = attrs.model
        @el = $ @el

    load_directory: (e)->
        e.stopImmediatePropagation()
        DirectoryBrowser.open_path @model.rel_dir, true

    srender: ()->
        @el.html "<a class='directory'>#{@model.name}</a>"

    activate: ()->
        @el.children('a').addClass('selected')

    deactivate: ()->
        @el.children('a').removeClass('selected')

    append_child: (child)->
        if !@children_el
            @children_el = $ '<ul />'
            @el.append @children_el
        @children_el.append child



DirectoryBrowser =
    first: true
    router: null

    do_browse: (path)->
        @path = path
        if @first
            @directories = new DirectoryCollection()
            @sidebar = new DirectoriesView()
            @directories.fetch()
            @first = false
        else
            @sidebar.set_active path

    open_path: (path) ->
        @router.navigate "path=#{path}^page=1", true