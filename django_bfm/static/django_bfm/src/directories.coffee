Directory = Backbone.Model.extend
    url: 'directory/'
    initialize: ()->
        @id = @get('rel_dir')
        @is_child = if @get('rel_dir').indexOf('/') == -1 then false else true

    new_folder: (data)->
        $.ajax
            url: @url
            data: $.extend(data, {action: 'new', directory: @get('rel_dir')})
            success: ()->
                DirectoryBrowser.directories.fetch()

    rename: (data)->
        $.ajax
            url: @url
            data: $.extend(data, {action: 'rename', directory: @get('rel_dir')})
            success: ()->
                DirectoryBrowser.directories.fetch()

    delete: (data)->
        $.ajax
            url: @url
            data: {action: 'delete', directory: @get('rel_dir')}
            success: ()->
                DirectoryBrowser.directories.fetch()


DirectoryCollection = Backbone.Collection.extend
    # Collection responsible for all directory models.
    #
    # Methods:
    #
    # added - event callback, called everytime directory list changes.
    url: 'list_directories/'
    model: Directory

    initialize: (attrs)->
        @bind('reset', @added)
        # Root directory is exception to all possible rules...
        @root = new Directory(name: '', rel_dir: '')

    added: ()->
        DirectoryBrowser.sidebar.clear()
        _.forEach(@models, (model)=>
            if !model.is_child
                DirectoryBrowser.sidebar.append_directory(model)
        )
        DirectoryBrowser.sidebar.set_active(DirectoryBrowser.path)


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
        @el = $('.directory-list')
        # Root directory is exception to all possible rules...
        new RootDirectoryView()

    append_directory: (model)->
        view = new DirectoryView('model': model)
        @dirs[model.id] = view
        @el.append(view.srender())
        _.forEach(model.get('children'), (child)=>
            @append_children(child, view)
        )

    append_children: (id, parent_view)->
        model = DirectoryBrowser.directories.get(id)
        view = new DirectoryView('model': model)
        @dirs[model.id] = view
        parent_view.append_child(view.srender())
        _.forEach(model.get('children'), (child)=>
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

    clear: ()->
        dirs = {}
        active_dir = null
        @el.children().remove()


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
        "contextmenu": "actions_menu"
    children_el: false
    context_template: '#directory_actions_tpl'

    initialize: (attrs)->
        @model = attrs.model
        @el = $ @el
        @context_callbacks = [
            (()=>@new_folder()),
            (()=>@rename()),
            (()=>@delete())]

    load_directory: (e)->
        e.stopImmediatePropagation()
        e.preventDefault()
        DirectoryBrowser.open_path @model.get('rel_dir'), true

    srender: ()->
        @el.html("<a class='directory'>#{@model.get('name')}</a>")

    activate: ()->
        @el.children('a').addClass('selected')

    deactivate: ()->
        @el.children('a').removeClass('selected')

    append_child: (child)->
        if !@children_el
            @children_el = $ '<ul />'
            @el.append @children_el
        @children_el.append(child)

    actions_menu: (e)->
        e.stopImmediatePropagation()
        e.preventDefault()
        entries = $(_.template($(@context_template).html())())
        menu = new ContextMenu()
        menu.add_entries(entries, @context_callbacks)
        menu.render(e)

    new_folder: ()->
        dialog = new Dialog
            model: @model
            template: '#new_directory_tpl'
            callback: (data)=> @model.new_folder(data)
        dialog.render()

    rename: ()->
        dialog = new Dialog
            model: @model
            template: '#rename_directory_tpl'
            callback: (data)=> @model.rename(data)
        dialog.render()

    delete: ()->
        dialog = new Dialog
            model: @model
            template: '#delete_directory_tpl'
            callback: (data)=> @model.delete(data)
        dialog.render()




RootDirectoryView = DirectoryView.extend
    events:
        "click a": "load_directory"
        "contextmenu": "actions_menu"
    context_template: '#rootdirectory_actions_tpl'
    initialize: ()->
        @el = $('#changelist-filter>h2').first()
        @model = DirectoryBrowser.directories.root
        @context_callbacks = [(()=>@new_folder())]
        @delegateEvents()



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
            @sidebar.set_active(path)

    open_path: (path)->
        @router.navigate("path=#{path}^page=1", true)