class Directory extends Backbone.Model
    url: 'directory/'

    initialize: ()->
        @id = @get('rel_dir')
        @is_child = @get('rel_dir').indexOf('/') != -1

    new_directory: (data)->
        additional_data = {'action': 'new', 'directory': @get('rel_dir')}
        $.ajax({
            'url': @url,
            'data': _.extend(data, additional_data),
            'success': ()-> DirectoryBrowser.directories.fetch()
        })

    rename: (data)->
        additional_data = {'action': 'rename', 'directory': @get('rel_dir')}
        $.ajax({
            'url': @url,
            'data': $.extend(data, additional_data),
            'success': ()-> DirectoryBrowser.directories.fetch()
        })

    delete: (data)->
        $.ajax({
            url: @url,
            data: {'action': 'delete', 'directory': @get('rel_dir')},
            success: ()-> DirectoryBrowser.directories.fetch()
        })


class DirectoryCollection extends Backbone.Collection
    url: 'list_directories/'
    model: Directory

    initialize: ()->
        @on('reset', @added)
        @root = new Directory({name: '', rel_dir: ''})

    added: ()->
        @view.clear()
        _.forEach(@models, (model)=>
            if !model.is_child
                @view.add_directory(model)
        )
        @view.set_active_by_path(DirectoryBrowser.path)


class DirectoriesView extends Backbone.View
    el: '#changelist-filter'
    subviews: {}

    initialize: (@directories)->
        # Root directory has some unusual rules, so it has different view and
        # model.
        @root_id = @directories.root.id
        @subviews[@root_id] = new RootDirectoryView(null, @directories.root, @)
        # Explain collection who's in control now.
        @directories.view = @
        @child_el = @$el.find('.directory-list')

    clear: ()->
        for key, view of @subviews
            if key != @root_id
                view.remove()
        [old_subviews, @subviews] = [@subviews, {}]
        @subviews[@root_id] = old_subviews[@root_id]
        @active_view = null

    add_directory: (model, to = @child_el)->
        view = new DirectoryView(null, model, @)
        @subviews[model.id] = view
        view.render(to)
        _.forEach(model.get('children'), (model_id)=>
            @add_directory(@directories.get(model_id), view.child_el)
        )

    set_active: (view)->
        if view != @active_view
            @active_view?.deactivate()
            @active_view = view

    set_active_by_path: (path)->
        if path == @root_id
            view = @subviews[@root_id]
        else
            view = @subviews[@directories.get(path).id]
        view.activate()


class DirectoryView extends Backbone.View
    tagName: 'li'
    events: {
        'click .directory': 'activate',
        'contextmenu .directory': 'context_menu'
    }
    context_template: '#directory_actions_tpl'

    initialize: (filler, @model, @supervisor)->
        @context_callbacks = [
            (()=>@new_directory()),
            (()=>@rename()),
            (()=>@delete())
        ]

    render: (to)->
        link = $(@make('a', {'class': 'directory'}, @model.get('name')))
        @$el.append(link, (@child_el = @make('ul')))
        $(to).append(@$el)

    activate: (e)->
        e?.stopImmediatePropagation()
        @$el.children('a').addClass('selected')
        @supervisor.set_active(@)
        DirectoryBrowser.open_path(@model.get('rel_dir'), true)

    deactivate: ()->
        @$el.children('a').removeClass('selected')

    context_menu: (e)->
        e.stopImmediatePropagation()
        e.preventDefault()
        if not @context_items
            @context_items = $(_.template($(@context_template).html(), {}))
        menu = new ContextMenu()
        menu.add_entries(@context_items, @context_callbacks)
        menu.render(e)

    new_directory: ()->
        new Dialog({
            'model': @model,
            'template': '#new_directory_tpl',
            'callback': (data)=> @model.new_directory(data)
        }).render()

    rename: ()->
        dialog = new Dialog({
            'model': @model,
            'template': '#rename_directory_tpl',
            'callback': (data)=> @model.rename(data)
        })
        dialog.render()

    delete: ()->
        dialog = new Dialog({
            'model': @model,
            'template': '#delete_directory_tpl',
            'callback': (data)=> @model.delete(data)
        })
        dialog.render()


class RootDirectoryView extends DirectoryView
    events: {
        'click': 'activate',
        'contextmenu': 'context_menu'
    }
    context_template: '#rootdirectory_actions_tpl'
    el: '#root-dir'

    initialize: (filler, @model, @supervisor)->
        @context_callbacks = [()=> @new_directory()]

    activate: (e)->
        e?.stopImmediatePropagation()
        @$el.addClass('selected')
        @supervisor.set_active(@)
        DirectoryBrowser.open_path(@model.get('rel_dir'), true)

    deactivate: ()->
        @$el.removeClass('selected')


DirectoryBrowser =
    first: true
    router: null

    do_browse: (path)->
        @path = path
        if @first
            @directories = new DirectoryCollection()
            @sidebar = new DirectoriesView(@directories)
            @directories.fetch()
            @first = false

    open_path: (path)->
        @router.navigate("path=#{path}^page=1", true)
