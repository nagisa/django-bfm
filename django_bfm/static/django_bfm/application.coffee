#TODO: Admin Applet
#TODO: Directory Actions
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
            Route.do_reload = true
        rename_file: () ->
            dialog = new Dialog
                url: @url
                model: @
                template: '#file_rename_tpl'
                callback: @rename_file_callback
            dialog.render()
        rename_file_callback: (dialog_data) ->
            $.ajax
                url: @url
                data: "#{dialog_data}&action=rename"
                success: => Route.reload()
        touch_file: () ->
            $.ajax
                url: @url
                data:
                    action: 'touch'
                    file: @get('filename')
                    directory: @get('rel_dir')
                success: => Route.reload()
        url: 'file/'
        resize_image: () ->
            dialog = new Dialog
                url: 'image/'
                model: @
                template: '#image_resize_tpl'
                callback: (dialog_data) ->
                    $.ajax
                        url: 'image/'
                        data: "#{dialog_data}&action=resize"
                        success: => Route.reload()
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
            @url = "#{@base_url}?directory=#{directory}"
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
        models_in_page: BFMOptions.files_in_page
        get_page: (page)->
            page -= 1
            start = @models_in_page * page
            end = start + @models_in_page
            @models[start..end]
        page_count: ->
            ~~(@length/@models_in_page+1)
        added: () ->
            page = Route.page
            _.forEach(@get_page(page), (model) ->
                new FileView('model': model).render())
            Paginator.render()


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
            c = {filename: '', size: '', date: '', mime: ''}
            c[@ord[0]]="#{if @ord[1] then 'descending' else 'ascending'} sorted"
            tpl = _.template($('#browse_head_tpl').html(), c)
            @el.find('tr:first').append(tpl)
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
            $('.block').fadeOut(200)
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
            @hook = attrs.hook
        render: () ->
            tpl = _.template($(@template).html(), @model.attributes)
            element = $(@el).html(tpl)
            $('body').append(element.fadeIn(200))
            $('.block').fadeIn(300)
            if @hook?
                @hook @

    FileView = Backbone.View.extend
        tagName: 'tr'
        events:
            "click .delete": 'delete'
            "click .touch": 'touch'
            "click .rename": 'rename'
            "click .resize": 'resize'
        delete: (e)->
            @model.delete_file()
            @remove()
        touch: (e) ->
            @model.touch_file()
        rename: (e) ->
            @model.rename_file()
        resize: (e) ->
            @model.resize_image()
        className: ->
            Table.get_row_class()
        initialize: (attrs) ->
            @table = Table
            @attrs = attrs.model.attributes
            @model = attrs.model
        render: () ->
            tpl = _.template($('#browse_file_tpl').html(), @attrs)
            elm = $(@el).html(tpl)
            resizable_mimetypes = ['image/png', 'image/jpeg',
                                   'image/bmp', 'image/gif']
            if @attrs.mimetype in resizable_mimetypes and BFMOptions.pil
                elm.find('.icons .resize').css('display', 'inline-block')
            @table.append elm


    FileUploadView = Backbone.View.extend
        initialize: (file, parent) ->
            @file = file
            @parent = parent
            @directory = Route.path
        events:
            'click a': 'abort'
        renders: () ->
            filename = if @file.name? then @file.name else @file.fileName
            @el = $(_.template($('#file_upload_tpl').html(), {filename: filename}))
            @delegateEvents @events
            @el
        do_upload: () ->
            csrf_token = $('input[name=csrfmiddlewaretoken]').val()
            @xhr = $.ajax_upload @file, {
                url: "upfile/?directory=#{@directory}"
                headers:
                    "X-CSRFToken": csrf_token
                progress: ((e, stats) => @report_progress(e, stats))
                complete: ((e) => @upload_complete(e))
                error: ((e) => @upload_error(e))
                abort: ((e) => @upload_abort(e))
            }
        abort: (e) ->
            @xhr.abort()
        report_progress: (e, stats) ->
            @parent.report_speed(stats.speed)
            @el.find('.progress').stop(true).animate({
                width: "#{stats.completion*100}%"
                }, stats.last_call)
        upload_error: (e) ->
            @el.find('.progress').css('background', '#CC0000')
            @parent.report_errors()
            @upload_next()
        upload_abort: (e) ->
            @el.find('.progress').css('background', '#FF6600')
            @upload_next()
        upload_complete: (e) ->
            @el.find('.progress').stop(true).animate({
                width: "100%"
                }, 300)
            @upload_next()
        upload_next: () ->
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
            'click .refresh': 'rebirth'
        minimize: (e) ->
            @el.addClass('minimized')
            $(e.currentTarget).removeClass('minimize').addClass('maximize')
        maximize: (e) ->
            @el.removeClass('minimized')
            $(e.currentTarget).removeClass('maximize').addClass('minimize')
        rebirth: (e) ->
            Uploader = new UploaderView()
            Uploader.render(@el)
        render: (elm) ->
            @el.html _.template($('#uploader_start_tpl').html())()
            if elm?
                elm.replaceWith(@el)
        selected: (e) ->
            tmpl = $(_.template($('#uploader_uploading_tpl').html())())
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
            window.onbeforeunload = (e) ->
                $.trim($('#upload_cancel_tpl').text())
        upload_next: () ->
            if @uploadlist and @uploadlist.length > 0
                @uploadlist.pop().do_upload()
            else
                template = if not @errors then '#upload_success_tpl' else '#upload_fail_tpl'
                text = $.trim($(template).text())
                @el.find('.status').html(text)
                @el.filter('.uploadinghead').find('.icon').removeClass('minimize maximize').addClass('refresh')
                window.onbeforeunload = null
                Route.reload()
        report_speed: (speed) ->
            @el.find('.status .speed').text("#{readable_size(speed)}/s")
        report_errors: () ->
            @errors = true


    PaginatorView = Backbone.View.extend
        el: $ 'p.paginator'
        events:
            'click a': 'page_click'
            'click .firstpage': 'first_page'
            'click .lastpage': 'last_page'
        render: () ->
            @el.empty()
            pages = []
            page_count = Files.page_count()

            if page_count > 5
                if Route.page > 6
                    @el.append _.template($('#pgn_first_page_tpl').html())()

            for page in [Route.page-5..Route.page+5]
                if page < 1 or page > page_count
                    continue
                if parseInt(page) == parseInt(Route.page)
                    rn = _.template($('#pgn_current_page_tpl').html(), {page: page})
                else
                    rn = _.template($('#pgn_page_tpl').html(), {page: page})
                @el.append rn

            if page_count > 5
                if Route.page < page_count - 5
                    @el.append _.template($('#pgn_last_page_tpl').html())()
        page_click: (e) ->
            page = parseInt($(e.currentTarget).text())
            if not isNaN page
                Route.goto undefined, page
                e.preventDefault()
        first_page: (e) ->
            e.preventDefault()
            Route.goto undefined, 1
        last_page: (e) ->
            e.preventDefault()
            Route.goto undefined, Files.page_count()


    Urls = Backbone.Router.extend
        initialize: ->
            @do_reload = false
        routes:
            '*path/page-:page': 'do_browse'
            '*path': 'do_browse'
        do_browse: (path, page) ->
            @page = if page? then parseInt(page) else 1
            if @do_reload or path isnt @path
                @path = path
                if not @do_reload
                    Dirs.el.find('.selected').removeClass('selected')
                Table.clear()
                Files.set_directory(path)
                Files.fetch()
            else
                Table.clear()
                Files.added()
            @do_reload = false
        goto: (path, page) ->
            page = if page? then parseInt(page) else 1
            path = if path? then path else @path
            @navigate "#{path}/page-#{page}", true
        reload: () ->
            @do_reload = true
            @do_browse(@path, @page)

    Table = new FileTableView()
    Dirs = new DirectoriesView()
    Uploader = new UploaderView()
    Paginator = new PaginatorView()
    Files = new Files()
    D = new Directories
    Route = new Urls()
    D.fetch()
    Uploader.render()
    Backbone.history.start()