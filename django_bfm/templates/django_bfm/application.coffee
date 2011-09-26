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
    File = Backbone.Model.extend
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
            dialog = new Dialog
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



    Files = Backbone.Collection.extend
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

        model: File
        added: () ->
            _.forEach(@models, (model) ->
                new FileView('model': model).render())


    Directories = Backbone.Collection.extend
        url: 'list_directories/'
        initialize: (attrs) ->
            @bind('reset', @added)
        added: () ->
            _.forEach(@models, (model) ->
                new DirectoryView({'model': model.attributes}).render()
                )

    FileTableView = Backbone.View.extend
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
            c[@ord[0]] = "#{if @ord[1] then 'descending' else 'ascending'} sorted"
            @el.find('tr:first').append($('#fileBrowseHeadTemplate').tmpl(c))
        get_row_class: () ->
            @current_row = ((@current_row+1)%2)
            return "row#{@current_row+1}"


    DirectoriesView = Backbone.View.extend
        el: $ '.directory-list'
        append: (elm) ->
            @el.append(elm)


    DirectoryView = Backbone.View.extend
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
                child = new ChildDirectoriesView({'childs': @model.childs, 'parent': @})
                child.render()
            @el
        append: (element) ->
            @el.append element


    ChildDirectoriesView = Backbone.View.extend
        tagName: 'ul'
        initialize: (attrs) ->
            @el = $ @el
            @childs = attrs.childs
            @parent = attrs.parent
        render: () ->
            callback = (child) ->
                directory = new DirectoryView({'model': child})
                @parent.append(@el.append(directory.srender()))
            _.forEach(@childs, callback, @)


    Dialog = Backbone.View.extend
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

    FileView = Backbone.View.extend
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


    FileUploadView = Backbone.View.extend
        initialize: (file, parent) ->
            @file = file
            @parent = parent
            @directory = Route.path
        events:
            'click a': 'abort'
        renders: () ->
            @el = $('#UploadableTemplate').tmpl({'filename': @file.fileName})
            @delegateEvents @events
            @el
        abort: () ->
            @xhr.abort()
            @el.find('.progress').css('background', '#FF6600')
            @upload_complete()
        fail: () ->
            @el.find('.progress').css('background', '#CC0000')
            @parent.report_errors()
            @upload_complete()
        do_upload: () ->
            @xhr = xhr = new XMLHttpRequest()
            form = new FormData()
            csrf_token = $('input[name=csrfmiddlewaretoken]').val()
            form.append "file", @file;
            xhr.upload.addEventListener "progress", ((e) => @report_progress(e)), false
            xhr.addEventListener "load", ((e) => @upload_complete(e)), false
            xhr.addEventListener "error", (() => @fail()), false
            @stats =
                start: new Date()
                last_report: new Date()
                last_loaded: 0
            xhr.open "POST", "upfile/?directory="+@directory
            xhr.setRequestHeader "X-CSRFToken", csrf_token
            xhr.send(form)
        report_progress: (e) ->
            last_report = @stats.last_report
            last_loaded = @stats.last_loaded
            time_difference = new Date() - last_report
            size_difference = e.loaded - last_loaded
            percentage = (e.loaded*100/@file.size).toFixed(1)
            speed = ~~((size_difference*1000/time_difference)+0.5)
            @parent.report_speed(speed)
            if percentage > 100
                percentage = 100
            @el.find('.progress').stop(true).animate({
                width: "#{percentage}%"
                }, Math.min(1000/(speed/1048576), 1000))
            if time_difference > 3000
                @stats.last_report = new Date()
                @stats.last_loaded = e.loaded
        upload_complete: (e) ->
            @parent.upload_next()
            @el.find('.stop').remove()


    UploaderView = Backbone.View.extend
        initialize: () ->
            @uploadlist = []
            @errors = false
        el: $ '.uploader'
        events:
            'change form input': 'selected'
        uploadingevents:
            'click .minimize': 'minimize'
            'click .maximize': 'maximize'
            'click .refresh': 'karakiri'
        minimize: (e) ->
            @el.addClass('minimized')
            $(e.currentTarget).removeClass('minimize').addClass('maximize')
        maximize: (e) ->
            @el.removeClass('minimized')
            $(e.currentTarget).removeClass('maximize').addClass('minimize')
        karakiri: (e) ->
            Uploader = new UploaderView()
            Uploader.render(@el)
        render: (elm) ->
            @el.html $('#startUploadTemplate').tmpl()
            if elm?
                elm.replaceWith(@el)
        selected: (e) ->
            tmpl = $('#UploadablesTemplate').tmpl()
            @el.replaceWith tmpl
            @el = tmpl
            @delegateEvents @uploadingevents
            table = tmpl.find('table')
            selected_files = e.currentTarget.files
            for file in selected_files
                @uploadlist.push(new FileUploadView file, @)
            for uploadable in @uploadlist
                table.append uploadable.renders()
            @uploadlist.reverse()
            @uploadlist.pop().do_upload()
        upload_next: () ->
            if @uploadlist and @uploadlist.length > 0
                @uploadlist.pop().do_upload()
            else
                text = "Upload was completed #{if not @errors then 'successfully.' else ', but with errors.'}"
                @el.find('.status').text(text)
                @el.filter('.uploadinghead').find('.icon').removeClass('minimize maximize').addClass('refresh')
                Route.do_browse(Route.path)
        report_speed: (speed) ->
            @el.find('.status .speed').text("#{readable_size(speed)}/s")
        report_errors: () ->
            @errors = true

    Urls = Backbone.Router.extend
        routes:
            '*path': 'do_browse'
        do_browse: (path) ->
            @path = path
            Dirs.el.find('.selected').removeClass('selected')
            Table.clear()
            Files.set_directory(path)
            Files.fetch()
        goto: (path) ->
            @navigate "#{path}", true

    Table = new FileTableView()
    Dirs = new DirectoriesView()
    Uploader = new UploaderView()
    Files = new Files()
    D = new Directories
    Route = new Urls()
    D.fetch()
    Uploader.render()
    Backbone.history.start()