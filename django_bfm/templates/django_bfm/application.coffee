#TODO: Pagination
#TODO: Uploading
#TODO: File Actions (Delete, Touch, Rename)
#TODO: Admin Applet
$ ->
    readable_size = (size) ->
        table = [['B', 1024, 0],['KB', 1048576, 0],['MB', 1073741824, 1],
                 ['GB', 1099511627776, 2], ['TB', 1125899906842624, 3]]
        for s in table
            if size < s[1]
                return "#{(size/(s[1]/1024)).toFixed(s[2])} #{s[0]}"
    BFMFile = Backbone.Model.extend
        initialize: () ->
            @set
                'date': new Date(@get('date'))
            @set
                'pdate': @parseDate()
                'psize': @parseSize()
        delete_file: () ->
            $.ajax
                url: @url
                data:
                    action: 'delete'
                    file: @get('filename')
                    directory: @get('rel_dir')
        rename_file: () ->
            dialog = new BFMDialog
                url: @url
                model: @
                template: '#fileRenameTemplate'
                callback: @rename_file_callback
            dialog.render()
        rename_file_callback: (dialog_data) ->
            $.ajax
                url: @url
                data: "#{dialog_data}&action=rename"
            Route.do_browse(Route.path)
        touch_file: () ->
            $.ajax
                url: @url
                data:
                    action: 'touch'
                    file: @get('filename')
                    directory: @get('rel_dir')
            Route.do_browse(Route.path)
        url: 'file/'
        parseDate: () ->
            d = @get("date")
            "#{d.getFullYear()}-#{d.getMonth()}-#{d.getDate()}"
        parseSize: () ->
            readable_size(@get('size'))



    BFMFiles = Backbone.Collection.extend
        url: 'list_files/'
        initialize: (attrs) ->
            @base_url = @url
            @bind('reset', @added)
            if attrs? and attrs.directory?
                @url = @url+'?directory='+attrs.directory
        set_directory: (directory) ->
            @url = @base_url+'?directory='+directory
        comparator: (model) ->
            date = model.get('date')
            dt = date.getFullYear()*10000+date.getMonth()*100+date.getDate()
            dh = date.getHours()*100+date.getMinutes()
            -(dt+dh*0.0001)
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

        model: BFMFile
        added: () ->
            _.forEach(@models, (model) ->
                new BFMFileView('model': model).render())


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
        ord: ['date', true]
        events: {'click th': 'resort_data'}
        resort_data: (e) ->
            name = e.currentTarget.getAttribute('data-name')
            if not Files.comparators[name]
                return false
            if @ord[0] == name
                @ord[1] = not @ord[1]
            else
                @ord = [name, true]
            @clear()
            if @ord[1]
                Files.comparator = Files.comparators[name].desc
            else
                Files.comparator = Files.comparators[name].asc
            Files.sort()
        clear: () ->
            @current_row = 1
            @el.html ''
            @append($('<thead/>').append($('<tr/>')))
            @draw_head()
        append: (element) ->
            @el.append element
        prepend: (element) ->
            @el.prepend element
        draw_head: () ->
            c = {}
            cl = 'descending'
            cl = 'ascending' if not @ord[1]
            c[@ord[0]] = cl+' sorted'
            @el.find('tr:first').append($('#fileBrowseHeadTemplate').tmpl(c))
        get_row_class: () ->
            @current_row = ((@current_row+1)%2)
            return "row#{@current_row+1}"


    BFMDirectoriesView = Backbone.View.extend
        el: $ '.directory-list'
        append: (elm) ->
            @el.append(elm)


    BFMDirectoryView = Backbone.View.extend
        tagName: 'li'
        events:
            "click .directory": "load_directory"
        load_directory: (e) ->
            e.stopImmediatePropagation()
            Route.goto(@model.rel_dir)
            @el.children('a').addClass('selected')
        initialize: (attrs) ->
            @model = attrs.model
            @el = $ @el
        render: () ->
            Dirs.append @srender()
        srender: () ->
            @el.html "<a class='directory#{if Route.path == @model.rel_dir then " selected" else ""}'>#{@model.name}</a>"
            if @model.childs?
                child = new BFMChildDirectoriesView({'childs': @model.childs, 'parent': @})
                child.render()
            @el
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


    BFMDialog = Backbone.View.extend
        tagName: 'form'
        className: 'dialog'
        events:
            "click .submit": 'call_callback'
            "click .cancel": 'cancel'
        tear_down: () ->
            $(@el).fadeOut(200, => @remove())
            $('.block').css('display', 'none')
        cancel: (e) ->
            @tear_down()
            e.preventDefault()
        call_callback: (e) ->
            @tear_down()
            e.preventDefault()
            @callback($(@el).serialize())
        initialize: (attrs) ->
            @url = attrs.url
            @model = attrs.model
            @template = attrs.template
            @callback = attrs.callback
        render: () ->
            element = $(@el).html($(@template).tmpl(@model.attributes))
            $('body').append(element.fadeIn(200))
            $('.block').css('display', 'block')

    BFMFileView = Backbone.View.extend
        tagName: 'tr'
        events:
            "click .delete": 'delete'
            "click .touch": 'touch'
            "click .rename": 'rename'
        delete: (e)->
            @model.delete_file()
            @remove()
        touch: (e) ->
            @model.touch_file()
        rename: (e) ->
            @model.rename_file()
        className: ->
            Table.get_row_class()
        initialize: (attrs) ->
            @table = Table
            @attrs = attrs.model.attributes
            @model = attrs.model
        render: () ->
            elm = $(@el).html($('#fileBrowseTemplate').tmpl(@attrs))
            if @attrs.mimetype.substring(0, 5) == "image"
                elm.find('.icons .resize').css('display', 'block')
            @table.append elm


    BFMUrls = Backbone.Router.extend
        routes:
            '*path': 'do_browse'
        do_browse: (path) ->
            @path = path
            Dirs.el.find('.selected').removeClass('selected')
            # Drawing filetable
            Table.clear()
            Files.set_directory(path)
            Files.fetch()
        goto: (path) ->
            @navigate "#{path}", true

    Table = new BFMFileTableView()
    Dirs = new BFMDirectoriesView()
    Files = new BFMFiles()
    D = new BFMDirectories
    D.fetch()
    Route = new BFMUrls()
    Backbone.history.start()