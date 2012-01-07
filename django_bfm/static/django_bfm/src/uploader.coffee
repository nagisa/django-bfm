FileUploadView = Backbone.View.extend
    # View responsible for one uploaded file.
    #
    # Methods:
    #
    # srender - renders view to element and returns it instead of drawing it
    #           to DOM.
    # do_upload - start uploading file.
    # report_progress - callback called when XHR reports progress of upload.
    # upload_complete - callback called when upload finishes successfully.
    # upload_abort - callback called when upload is aborted by user.
    # upload_error - callback called when upload is aborted by server.
    # abort - callback called when user clicks on cross near uploaded file.
    #         Cancels current upload.
    # update_status_bar - animates file upload progress bar.

    events: {'click .abort': 'abort'}

    initialize: (file)->
        @file = file
        @directory = FileUploader.path

    srender: ()->
        filename = if @file.name? then @file.name else @file.fileName
        @el = $(_.template($('#file_upload_tpl').html(), {filename: filename}))
        @status = @el.find('.status')
        @indicators = {
            'percent': @el.find('.indicators .percent'),
            'speed': @el.find('.indicators .speed')
        }
        @delegateEvents @events
        return @el

    do_upload:()->
        # Check if file isn't aborted yet.
        if @aborted?
            return false
        csrf_token = $('input[name=csrfmiddlewaretoken]').val()
        url = "upfile/?directory=#{@directory}"
        if BFMAdminOptions?
            directory = BFMAdminOptions.upload_rel_dir
            url = "#{BFMAdminOptions.upload}?directory=#{directory}"
        @xhr = $.ajax_upload(@file, {
            'url': url,
            'headers': {"X-CSRFToken": csrf_token}
            'progress': (e, stats)=> @report_progress(e, stats)
            'complete': (e, data)=> @upload_complete(e, data)
            'error': (e)=> @upload_error(e)
            'abort': (e)=> @upload_abort(e)
        })
        @el.addClass('current')
        return true

    report_progress: (e, stats)->
        @update_status_bar(stats.completion, stats.last_call)
        @indicators.percent.text(~~(stats.completion*1000+0.5)/10)
        @indicators.speed.text("#{readable_size(stats.speed)}/s")

    upload_complete: (e, data)->
        @el.removeClass('current')
        @el.find('.abort').hide()
        link = $('<a />', {'class': 'filename', 'href': data.url})
        link.text(data.filename)
        @el.find('.filename').replaceWith(link)
        @update_status_bar(1, 100)
        #Reload file browser!
        if(!(BFMAdminOptions?) and @directory == FileBrowser.path)
            _.defer(()=>
                FileBrowser.files.add(data)
                FileBrowser.files.sort()
            )
        #Report finished...
        FileUploader.uploader.report_finished(@)

    upload_abort: (e)->
        @el.removeClass('current')
        @status.css('background', '#FF9F00')
        @el.find('.indicators').hide()
        @el.find('.aborted').show()
        @el.find('.abort').hide()
        FileUploader.uploader.report_finished(@)

    upload_error: (e)->
        @el.removeClass('current')
        @status.css('background', '#DD4032')
        @el.find('.indicators').hide()
        @el.find('.failed').show()
        @el.find('.abort').hide()
        FileUploader.uploader.report_finished(@)

    abort: (e)->
        if @xhr?
            @xhr.abort()
        else
            @aborted = true
            @el.find('.abort').hide()
            @el.find('.indicators').hide()
            @el.find('.aborted').show()
            FileUploader.uploader.finished_uploads.push(@)

    update_status_bar: (percent, duration)->
        css = {'width': "#{percent*100}%"}
        animation_options = {'duration': duration, 'easing': 'linear'}
        @status.stop(true).animate(css, animation_options)


UploaderView = Backbone.View.extend
    # View responsible for rendering whole uploader applet.
    #
    # Methods:
    #
    # render - renders upload applet into DOM.
    # toggle_visibility - resize button event callback. Makes uploader
    #                     applet either minimized or maximized.
    # add_files - callback called when user selects files.
    # add_file - helper function for add_files.
    # upload_next - starts uploading next file, in case, there's available
    #               spots.
    # report_finished - function, which is called when FileUploadView
    #                   finishes (by either failing, aborting or completing)
    #                   uploading.
    # clear_finished - removes all finished FileUploadViews from uploader.
    # remove_queue - removes all FileUploadViews, that are not yet finished.
    to_upload: []
    started_uploads: []
    finished_uploads: []
    visible: false
    uploads_at_once: window.BFMOptions.uploads_at_once
    active_uploads: 0
    events: {
        'click .uploader-head>.control': 'toggle_visibility',
        'dblclick .uploader-head': 'toggle_visibility',
        'change input[type="file"]': 'add_files',
        'click .finished': 'clear_finished',
        'click .rqueued': 'remove_queue'
    }

    initialize: ()->
        @el = $('<div />', {'class': 'uploader'})

    render: ()->
        @el.append(_.template($('#uploader_tpl').html()))
        @el.appendTo($('body'))
        @height = @el.height()
        @width = @el.width()
        if directory_upload_support()
            @el.find('.selector.directory').css('display', 'inline-block')
        @delegateEvents(@events)

    toggle_visibility: (e)->
        button = @el.find('.uploader-head>.control')
        button.toggleClass('fullscreen exit-fullscreen')
        button.attr = {
            'title': button.attr('data-alttitle'),
            'data-alttitle': button.attr('title')
        }
        options = 'duration': 400, 'queue': false
        css = {
            'width': if !@visible then '50%' else "#{@width}",
            'height': if !@visible then '50%' else "#{@height}px"
        }
        @el.animate(css, options)
        @el.children(':not(.uploader-head)').show()
        @visible = !@visible

    add_files: (e)->
        _.forEach(e.currentTarget.files, (file)=>
            _.defer(()=>@add_file(file))
        )

    add_file: (file)->
        if (if file.name? then file.name else file.fileName) == "."
            return
        view = new FileUploadView(file)
        @to_upload.unshift(view)
        @el.find('.uploader-table').append(view.srender())
        _.defer(()=>@upload_next())

    upload_next: ()->
        for i in [0...@uploads_at_once-@active_uploads]
            # We'll loop until at least one file will start.
            while @to_upload.length > 0 and not started
                upl = @to_upload.pop()
                started = upl.do_upload()
                if started
                    @started_uploads.push(upl)
                    @active_uploads += 1

        # Add/remove exit confirmation
        if window.onbeforeunload != @unloading and @active_uploads>0
            window.onbeforeunload = @unloading
        else
            window.onbeforeunload = null

    report_finished: (who)->
        @finished_uploads.push(who)
        @active_uploads -= 1
        _.defer(()=>@upload_next())

    clear_finished: (e)->
        e.preventDefault()
        for i in [0...@finished_uploads.length]
            _.defer(()=>@finished_uploads.pop().remove())

    remove_queue: (e)->
        e.preventDefault()
        for i in [0...@to_upload.length]
            # Can't use _.defer due to race condition with currently uploading
            # files...
            @to_upload.pop().remove()

    unloading: ()->
        return $.trim($('#upload_cancel_tpl').text())


FileUploader =
    init: ()->
        @uploader = new UploaderView()
        @uploader.render()

    do_browse: (path)->
        @path = path