class File extends Backbone.Model
    # Represents one file in server.

    url: 'file/'

    initialize: ()->
        @set({
            'date': new Date(@get('date')),
            'lowercase_filename': @get('filename').toLowerCase()
        })
        @set({
            'pdate': @parseDate(),
            'psize': @parseSize(),
            'searchable': count_letters(@get('lowercase_filename'))
        })

    parseDate: ()->
        # Parses Date into more readable and shorter YYYY-MM-DD date.
        d = @get("date")
        return "#{d.getFullYear()}-#{d.getMonth()+1}-#{d.getDate()}"

    parseSize: ()->
        # Parses file size into more readable value, like 23,4 KB.
        return format_size(@get('size'))


class FileCollection extends Backbone.Collection
    # It is collection of Files. This object is responsible for keeping order of
    # files too.
    url: 'list_files/'
    model: File

    comparators:
        date: (model)->
            return model.get('date').getTime()
        size: (model)->
            return model.get('size')
        filename: (model)->
            return model.get("filename")
        mime: (model)->
            return model.get('mimetype')

    sorting: {'by': 'date', 'reversed': true}

    sort: (options)->
        # Call original sorter with silent option.
        super(_.extend(_.clone(options), {'silent': true}))
        # Reverse collection if asked.
        if options.reversed
            @models.reverse()
        if not options.silent
            @trigger('reset', @, options)

    set_sorting: (_by, reversed)->
        @comparator = @comparators[_by]
        @sorting = {'by': _by, 'reversed': reversed}

    initialize: ()->
        @base_url = @url
        @comparator = @comparators.date
        @on('reset update', @updated)
        @action_queue = []

    update_directory: (path)->
        @url = "#{@base_url}?directory=#{path}"

    updated: (collection, options, view=FileBrowser.file_table)->
        # Sort files...
        @sort({'reversed': @sorting.reversed, 'silent': true})
        # Render most parental view, which will render everything else...
        view.render(@)

    execute_action: (action)->
        # Executes action to all files inside action_queue.
        if @action_queue.length == 0
            return
        files = {
            'files': _.map(@action_queue, (v)-> return v.model.get('filename')),
            'directory': @action_queue[0].model.get('rel_dir'),
            'action': action,
            'csrfmiddlewaretoken': $('input[name="csrfmiddlewaretoken"]').val()
        }
        $.post('action/', files, (data)=>
            @action_queue = []
            @fetch()
        )

    search: (query)->
        query = query.toLowerCase()
        if query == ""
            return @
        query_letters = count_letters(query)

        tester = (model)->
            # First we make sure, that query contains less identical letters
            # than filename itself.
            searchable = model.get('searchable')
            for letter, count of query_letters
                if (searchable[letter] or 0) < count
                    return false
            return true

        second_tester = (model)->
            # This one has to make sure, that query letters matches
            # order of appearance in filename.
            # It IS slower, but it should have to work on smaller sets of
            # models as there's first filter.
            whitespace = /\s/
            filename = model.get('lowercase_filename')
            checked = 0
            length = filename.length

            for letter in query
                if whitespace.test(letter) then continue

                for filename_letter in filename.substring(checked, length)
                    # Advance filename until next non-whitespace character
                    if whitespace.test(filename[checked])
                        checked += 1
                        continue

                    checked += 1
                    if filename_letter == letter and checked <= length
                        break
                    else if checked > length
                        return false

            return true

        # Actual search by filtering models trough two testers defined above.
        filtered = @filter(tester)
        if query.length > 1
            filtered = _.filter(filtered, second_tester)

        # Put filtered results into a new collection and return it.
        new_collection = new FileCollection()
        new_collection.add(filtered, {'silent': true})
        new_collection.set_sorting(@sorting.by, @sorting.reversed)
        return new_collection


class FileTableControlsView extends Backbone.View
    # Base class for FileTableView

    control_events: {
        # Paginator events
        'click .paginator a': 'change_page',
        # Table events
        'click #result_list th.sortable': 'resort_files',
        'change #action-toggle': 'toggle_selections'
    }

    initialize: ()->
        @setElement($('#changelist-form'))
        @paginator = @$el.find('.paginator')
        @table = @$el.find('#result_list')
        # Load in search bar and bind events to it.
        @search = $('#searchbar')
        @search.val('')
        @search.on('change keyup', (e)=> @queue_search(e))
        # Load in actions and bind events to it.
        @actions = $('#changelist .actions')
        @actions.find('button').on('click', (e)=> @execute_actions(e))
        # We use these templates a lot, so why not parse them beforehand?
        @templates = {
            'pagin': {
                'page': _.template($('#pgn_page_tpl').html()),
                'current':  _.template($('#pgn_current_page_tpl').html())
            },
            'thead': _.template($('#browse_head_tpl').html()),
        }
        @page = 1


    render: (collection)->
        # Render pagination and sorting controls.
        # -- Pagination
        page_count = @count_pages(collection.length)
        @paginator.html('')
        if page_count <= 1
            @paginator.append(@templates.pagin.current({'page': 1}))
        else
            @paginator.append(@templates.pagin.current({'page': @page}))
            # Add 5 pages forward and backward.
            for offset in [1..4]
                if @page - offset > 0
                    pg = @page - offset
                    @paginator.prepend(@templates.pagin.page({'page': pg}))
                if @page + offset <= page_count
                    pg = @page + offset
                    @paginator.append(@templates.pagin.page({'page': pg}))
            # Add first page if needed
            if @page - 4 > 1
                pg = $(@templates.pagin.page({'page': 1}))
                @paginator.prepend(pg.addClass('end'))
            # Add last page if needed
            if @page + 4 < page_count
                pg = $(@templates.pagin.page({'page': page_count}))
                @paginator.append(pg.addClass('end'))
        @delegateEvents(@control_events)
        # -- THead
        # Clear table
        @table.html('')
        # Render
        context = {'filename': '', 'size': '', 'date': '', 'mime': ''}
        sort = if @collection.sorting.reversed then 'descending' else 'ascending'
        context[@collection.sorting.by] = "#{sort} sorted"
        @table.append(@templates.thead(context))

    count_pages: (items)->
        ~~(items / BFMOptions['files_per_page'])

    change_page: (page, collection)->
        parse_event = (e)->
            e.preventDefault()
            return parseInt(e.currentTarget.innerText)
        @page = if typeof(page) == 'number' then page else parse_event(page)

        FileBrowser.open_page(@page)
        @render(collection)

    queue_search: (e)->
        if @searchtimeout?
            clearTimeout(@searchtimeout)
        @searchtimeout = setTimeout((()=> @filter_files(e)), 100)

    next_row_class: ()->
        @current_row = (@current_row + 1) % 2
        return "row#{@current_row+1}"


class FileTableView extends FileTableControlsView
    # Any methods that requires direct access to collection or list of
    # FileViews should go here.

    render: (@collection, update=true)->
        @current_row = 1
        @file_views = []
        @selected_files = []
        # Render controls.
        super(collection)
        # Now render file list.
        _.forEach(@page_models(@page), (model)=>
            file = new FileView({'model': model, 'table': @})
            @file_views.push(file)
            @table.append(file.render_el(@next_row_class()))
        )
        @delegateEvents(@events)

    change_page: (page, collection)->
        super(page, (if collection? then collection else @collection))

    page_models: (page)->
        if @collection.length < 1
            return []
        per_page = BFMOptions['files_per_page']
        start = per_page*(@page-1)
        @collection.models[start...start+per_page]

    resort_files: (e)->
        sort = @collection.sorting

        if e?
            _by = e.currentTarget.getAttribute('data-name')

            if sort.by == _by
                @collection.set_sorting(sort.by, not sort.reversed)
            else
                @collection.set_sorting(_by, sort.reversed)
            # Tell it to do things.
            @collection.updated()

    filter_files: (e)->
        # Rework it to a full text, case-insensitive search
        # And make it work quickly!
        query = e.currentTarget.value.trim()
        if query == @last_query
            return
        @last_query = query

        if not @original_collection?
            @original_collection = @collection

        @original_collection.search(query).updated()

        if query == ""
            delete(@original_collection)

    toggle_selections: (e)->
        activate = e.currentTarget.checked
        for file in @file_views
            file.select(activate)

    execute_actions: (e)->
        e.preventDefault()
        action = @actions.find('select[name="action"]').val()
        for file in @selected_files
            if file?
                @collection.action_queue.push(file)
        @selected_files = []
        if @collection.action_queue.length > 0
            templates = {'delete': '#file_delete_tpl'}
            dialog = new Dialog({
                'template': templates[action],
                'callback': ()=> @collection.execute_action(action)
            })
            dialog.render()


class FileView extends Backbone.View
    # View responsible for one file row.
    tagName: 'tr'
    events: {"change input[type='checkbox']": 'select_e'}

    initialize: ({@model, @table})->
        # resizable_mimetypes = ['image/png', 'image/jpeg', 'image/bmp',
        #                         'image/gif']
        # if !(@model.get('mimetype') in resizable_mimetypes) or !BFMOptions.pil
        #     @resizable = false
        # else
        #     @resizable = true

    render_el: (row_class)->
        tpl = _.template($('#browse_file_tpl').html(), @model.attributes)
        elm = @$el.html(tpl)
        elm.addClass(row_class)

        return elm

    select_e: (e)->
        @selected = if e.currentTarget?.checked? then \
                                                e.currentTarget.checked else e
        if @selected
            @$el.addClass('selected')
            @table.selected_files.push(@)
        else
            # "Unselect" file.
            @$el.removeClass('selected')
            delete(@table.selected_files[@table.selected_files.indexOf(@)])

    select: (val)->
        @select_e(val)
        @$el.find('input[type="checkbox"]').prop('checked', val)


FileBrowser =
    # Object that glues FileCollection and FileTableControlsView.
    # Also it is responsible for passing out events which occurs because of
    # URL change.

    first: true
    path: null
    page: null
    router: null
    last_xhr: {'readyState': 4, 'first_load': true} #Fake variable.

    do_browse: (path, page)->
        # Initialize some variables on first load.
        if @last_xhr.first_load?
            @files = new FileCollection()
            @file_table = new FileTableView()
            delete(@last_xhr.first_load)

        [@path, path] = [path, @path]
        [@page, page] = [parseInt(page), @page]

        if @path != path
            @files.update_directory(@path)
            if @last_xhr.readyState != 4
                @last_xhr.abort()
            @last_xhr = @files.fetch({
                'silent': false
            })
        @file_table.change_page(@page, @files)


    open_page: (page)->
        @router.navigate("path=#{@path}^page=#{page}")
