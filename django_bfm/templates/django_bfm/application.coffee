#TODO: Sorting
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
        touch_file: () ->
            $.ajax
                url: @url
                data:
                    action: 'touch'
                    file: @get('filename')
                    directory: @get('rel_dir')
        url: 'file/'
        parseDate: () ->
            d = @get("date")
            "#{d.getFullYear()}-#{d.getMonth()}-#{d.getDate()}"
        parseSize: () ->
            readable_size(@get('size'))



    BFMFiles = Backbone.Collection.extend
        url: 'list_files/'
        initialize: (attrs) ->
            @bind('reset', @added)
        comparator: (model) ->
            date = model.get('date')
            dt = date.getFullYear()*10000+date.getMonth()*100+date.getDate()
            dh = date.getHours()*100+date.getMinutes()
            -(dt+dh*0.0001)
        comparators:
            date:
                desc: (model) ->
                    date = model.get('date')
                    dt = date.getFullYear()*10000+date.getMonth()*100+date.getDate()
                    dh = date.getHours()*100+date.getMinutes()
                    -(dt+dh*0.0001)
                asc: (model) ->
                    date = model.get('date')
                    dt = date.getFullYear()*10000+date.getMonth()*100+date.getDate()
                    dh = date.getHours()*100+date.getMinutes()
                    (dt+dh*0.0001)
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
        events: {'click th': 'resort_date'}
        resort_date: (e) ->
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
            e.stopImmediatePropagation();
            Route.goto(@model.rel_dir)
            Dirs.el.find('.selected').removeClass('selected')
            @el.children('a').addClass('selected')
        initialize: (attrs) ->
            @model = attrs.model
            @el = $ @el
        render: () ->
            Dirs.append @srender()
        srender: () ->
            @el.html "<a class='directory'>#{@model.name}</a>"
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
        events:
            "click .delete": 'delete'
            "click .touch": 'touch'
        delete: (e)->
            @model.delete_file()
            @remove()
        touch: (e) ->
            @model.touch_file()
        className: ->
            Table.get_row_class()
        initialize: (attrs) ->
            @table = Table
            @attrs = attrs.model.attributes
            @model = attrs.model
        render: () ->
            elm = $(this.el).html($('#fileBrowseTemplate').tmpl(@attrs))
            if @attrs.mimetype.substring(0, 5) == "image"
                elm.find('.icons .resize').css('display', 'block')
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
            Files.fetch()
        goto: (path) ->
            @navigate "#{path||@path}", true

    Table = new BFMFileTableView()
    Dirs = new BFMDirectoriesView()
    Files = new BFMFiles()
    D = new BFMDirectories
    D.fetch()
    Route = new BFMUrls()
    Backbone.history.start()