File = Backbone.Model.extend
    # Represents one file in server.
    #
    # Methods:
    # parseDate - parses ISO date into more readable and shorter YYYY-MM-DD
    #             format.
    # parseSize - parses bytes into more readable format with multiplier.
    # delete_file - asks server to remove file.
    # rename_file - renders file rename/move dialog.
    # rename_file_callback - asks server to rename/move file. It is Dialog
    #                        callback.
    # touch_file - asks server to change file modification date to now.
    # resize_image - renders dialog for image resizing and asks server to
    #                resize it.
    url: 'file/'

    initialize: () ->
        @set
            'date': new Date(@get('date'))
        @set
            'pdate': @parseDate()
            'psize': @parseSize()

    parseDate: () ->
        d = @get("date")
        "#{d.getFullYear()}-#{d.getMonth()}-#{d.getDate()}"

    parseSize: () ->
        readable_size(@get('size'))

    delete_file: () ->
        $.ajax
            url: @url
            data:
                action: 'delete'
                file: @get('filename')
                directory: @get('rel_dir')
            success: ()=>
                FileBrowser.files.remove(@)

    rename_file: ()->
        dialog = new Dialog
            url: @url
            model: @
            template: '#file_rename_tpl'
            callback: (data)=> @rename_file_callback(data)
        dialog.render()

    rename_file_callback: (dialog_data)->
        $.ajax
            url: @url
            data: "#{dialog_data}&action=rename"
            success: (data)=>
                @set(JSON.parse(data))
                @initialize()
                FileBrowser.files.sort()

    touch_file: ()->
        $.ajax
            url: @url
            data:
                action: 'touch'
                file: @get('filename')
                directory: @get('rel_dir')
            success: (data)=>
                @set(JSON.parse(data))
                @initialize()
                FileBrowser.files.sort()

    resize_image: () ->
        dialog = new Dialog
            url: 'image/'
            model: @
            template: '#image_resize_tpl'
            callback: (dialog_data) ->
                $.ajax
                    url: 'image/'
                    data: "#{dialog_data}&action=resize"
                    success: (data)=>
                        FileBrowser.files.add(JSON.parse(data))
                        FileBrowser.files.sort()
            hook: (dialog) ->
                $.ajax
                    url: 'image/'
                    dataType: 'json'
                    data:
                        action: 'info'
                        file: dialog.model.get('filename')
                        directory: dialog.model.get('rel_dir')
                    success: (data) ->
                        $(dialog.el).find('input[name="new_h"]').val(data.height)
                        $(dialog.el).find('input[name="new_w"]').val(data.width)
                        $(dialog.el).data 'ratio', data.height/data.width
                $(dialog.el).find('input[name="new_h"]').keyup ()->
                    if $(dialog.el).find('input[name="keepratio"]').is(':checked')
                        ratio = $(dialog.el).data 'ratio'
                        h = $(dialog.el).find('input[name="new_h"]').val()
                        $(dialog.el).find('input[name="new_w"]').val ~~(h/ratio+0.5)
                $(dialog.el).find('input[name="new_w"]').keyup ()->
                    if $(dialog.el).find('input[name="keepratio"]').is(':checked')
                        ratio = $(dialog.el).data 'ratio'
                        w = $(dialog.el).find('input[name="new_w"]').val()
                        $(dialog.el).find('input[name="new_h"]').val ~~(w*ratio+0.5)
        dialog.render()


FileCollection = Backbone.Collection.extend
    # It is collection of File. This object is responsible for keeping order of
    # files too.
    #
    # Methods:
    # update_directory - changes url, from which collection gets list of
    #                    files in server.
    # updated - callback, to call when collection is changed. Either by
    #           sorting it or retrieving new file list.
    url: 'list_files/'
    model: File
    comparators:
        date:
            desc: (model) ->
                0 - model.get('date')
            asc: (model) ->
                model.get('date') - 0
        size:
            desc: (model) ->
                -model.get('size')
            asc: (model) ->
                model.get('size')
        filename:
            desc: (model) ->
                str = model.get("filename")
                str = str.toLowerCase().split("")
                _.map str, (letter) ->
                    return String.fromCharCode(-(letter.charCodeAt(0)));
            asc: (model) ->
                model.get("filename")
        mime:
            desc: (model) ->
                str = model.get("mimetype")
                str = str.toLowerCase().split("")
                _.map str, (letter) ->
                    return String.fromCharCode(-(letter.charCodeAt(0)));
            asc: (model) ->
                model.get('mimetype')

    initialize: ()->
        @base_url = @url
        @comparator = @comparators.date.desc
        @bind 'reset', @updated
        @bind 'remove', @updated

    update_directory: ()->
        @url = "#{@base_url}?directory=#{FileBrowser.path}"

    updated: ()->
        # Render most parental view, which will render everything else...
        FileBrowser.paginator.render()


FileTableView = Backbone.View.extend
    # View responsible for showing table of files, including table head.
    #
    # Methods:
    #
    # resort_data - event callback. Called when user clicks on header.
    # render - renders table of files with given set of File models.
    # new_row_class - gives CSS class name for next row.
    ord: ['date', true]
    events:
        'click th': 'resort_data'

    initialize: ()->
        @el = $ 'table#result_list'
        @delegateEvents(@events)

    resort_data: (e) ->
        files = FileBrowser.files
        name = e.currentTarget.getAttribute('data-name')
        if not files.comparators[name]
            return false
        if @ord[0] == name
            @ord[1] = not @ord[1]
        else
            @ord = [name, true]
        if @ord[1]
            files.comparator = files.comparators[name].desc
        else
            files.comparator = files.comparators[name].asc
        files.sort()

    render: (models)->
        # Clear previous table
        @current_row = 1
        @el.html ''
        # Draw head
        @el.append($('<thead/>').append($('<tr/>')))
        c = {filename: '', size: '', date: '', mime: ''}
        c[@ord[0]]="#{if @ord[1] then 'descending' else 'ascending'} sorted"
        tpl = _.template($('#browse_head_tpl').html(), c)
        @el.find('tr:first').append(tpl)
        # Add files...
        _.forEach(models, (model) =>
            file = new FileView('model': model)
            @el.append file.srender()
        )
        @delegateEvents(@events)

    new_row_class: () ->
        @current_row = ((@current_row+1)%2)
        return "row#{@current_row+1}"


FileView = Backbone.View.extend
    # View responsible for one file row.
    #
    # Methods:
    #
    # srender - returns element with rendered row for FileTableView
    # delete - event callback. Called when user clicks on trash icon for
    #          that file. Then it asks for model to delete file, for which
    #          this view is responsible.
    # touch - same as delete, just that asks to update modify time for file.
    # rename - same as delete, just asks to rename file.
    # resize - same as delete, just asks to resize image.
    tagName: 'tr'
    events:
        "click .delete": 'delete'
        "click .touch": 'touch'
        "click .rename": 'rename'
        "click .resize": 'resize'

    initialize: (attrs)->
        @table = FileBrowser.table
        @attrs = attrs.model.attributes
        @model = attrs.model

    srender: ()->
        tpl = _.template($('#browse_file_tpl').html(), @attrs)
        elm = $(@el).html(tpl)
        elm.addClass(@table.new_row_class())
        resizable_mimetypes = ['image/png', 'image/jpeg', 'image/bmp',
                                'image/gif']
        if !(@attrs.mimetype in resizable_mimetypes) or !BFMOptions.pil
            elm.find('.icons .resize').css('display', 'none')
        return elm

    delete: (e)->
        @model.delete_file()

    touch: (e) ->
        @model.touch_file()

    rename: (e) ->
        @model.rename_file()

    resize: (e) ->
        @model.resize_image()


FilePaginatorView = Backbone.View.extend
    # View responsible for breaking up list of files into smaller pieces and
    # showing page list.
    #
    # Methods:
    #
    # get_page_models - returns list of specific models for current page.
    # count_pages - returns number of pages.
    # render - renders file table and paginator.
    # page_click - event callback. Called when user clicks on page in
    #              paginator.
    # first_page - same as page_click, just that it is called when user
    #              clicks on "First Page" button.
    # last_page - same as page_click, just that it is called when user
    #             clicks on "Last Page" button.
    events:
        'click a': 'page_click'
        'click .firstpage': 'first_page'
        'click .lastpage': 'last_page'

    initialize: ()->
        @el = $ 'p.paginator'
        @last_page_count = -1

    get_page_models: ()->
        per_page = BFMOptions.files_in_page
        page = FileBrowser.page
        files = FileBrowser.files
        start = per_page*(page-1)
        files.models[start...start+per_page]

    count_pages: ()->
        ~~(FileBrowser.files.models.length/BFMOptions.files_in_page+0.99)

    render: ()->
        # Render table
        FileBrowser.table.render @get_page_models()
        # Render paginator itself
        pages = @count_pages()
        # Clear paginator for rerender
        @el.empty()
        # Add "Go to first" button
        if pages > 5 and FileBrowser.page > 6
            @el.append _.template($('#pgn_first_page_tpl').html())()
        # Add "Page X" buttons
        for page in [FileBrowser.page-5..FileBrowser.page+5]
            if page < 1 or page > pages
                continue
            if page == FileBrowser.page
                rn = _.template($('#pgn_current_page_tpl').html(),
                                                            {page: page})
            else
                rn = _.template($('#pgn_page_tpl').html(), {page: page})
            @el.append rn
        # Add "Go to last" button
        if pages > 5 and FileBrowser.page < pages - 5
            @el.append _.template($('#pgn_last_page_tpl').html())()
        # Events...
        @delegateEvents(@events)

    page_click: (e)->
        page = parseInt($(e.currentTarget).text())
        if not isNaN page
            FileBrowser.open_page(page)
        e.preventDefault()

    first_page: (e)->
        e.preventDefault()
        FileBrowser.open_page(1)

    last_page: (e)->
        e.preventDefault()
        FileBrowser.open_page(@count_pages())


FileBrowser =
    # Object that glues FileCollection, FileTableView and FilePaginatorView.
    # Also it is responsible for passing out events which occurs because of
    # URL change.
    #
    # Methods:
    #
    # do_browse - pass URL change events to FileCollection, FileTableView
    #             and FilePaginatorView. Also initiate them, if they doesn't
    #             yet exist.
    # open_page - changes URL to URL with another page as argument.
    first: true
    path: null
    page: null
    router: null

    do_browse: (path, page) ->
        if @first
            @files = new FileCollection()
            @table = new FileTableView()
            @paginator = new FilePaginatorView()
            @first = false
        [@path, path] = [path, @path]
        [@page, page] = [parseInt(page), @page]
        if @path != path
            @files.update_directory()
            @files.fetch()
        else if @page != page
            @paginator.render()

    open_page: (page) ->
        @router.navigate "path=#{@path}^page=#{page}", true
