FileUploadView = Backbone.View.extend
    # View responsible for one uploadable (uploaded file).

    events: {
        'click .abort': 'abort',
        'click .remove': 'remove_upload'
    }

    initialize: (file)->
        @file = file
        @complete = false
        @csrf_token = $('input[name=csrfmiddlewaretoken]').val()
        if BFMAdminOptions?
            dir = BFMAdminOptions.upload_rel_dir
            @url = "#{BFMAdminOptions.upload}?directory=#{dir}"
        else
            @url = "upfile/?directory=#{FileUploader.path}"

    render_el: ()->
        filename = if @file.name? then @file.name else @file.fileName
        @el = $(_.template($('#file_upload_tpl').html(), {filename: filename}))
        @progress = @el.find('.progress')
        @percent = @el.find('.percent')
        @delegateEvents(@events)
        return @el

    start_upload: ()->
        if not @xhr
            @el.addClass('active')
            @xhr = $.ajax_upload(@file, {
                'url': @url,
                'headers': {"X-CSRFToken": @csrf_token},
                'progress': (e, completion)=> @report_progress(e, completion),
                'complete': (e, data)=> @upload_complete(e, data),
                'error': (e)=> @upload_error(e),
                'abort': (e)=> @upload_abort(e)
            })

    report_progress: (e, completion)->
        percent = completion * 100
        @progress.css('width', "#{percent}%")
        @percent.text("#{percent.toFixed(1)}%")

    upload_complete: (e, data)->
        @complete = true
        @report_progress(100)
        @el.removeClass('active')
        @el.find('.filename').attr('href', data.url).text(data.filename)
        #TODO: Reload file browser!
        # if(!(BFMAdminOptions?) and @directory == FileBrowser.path)
        #     _.defer(()=>
        #         FileBrowser.files.add(data)
        #         FileBrowser.files.sort()
        #     )
        FileUploader.uploader.report_finished(@)

    upload_abort: (e)->
        @el.toggleClass('active aborted')
        FileUploader.uploader.report_finished(@)

    upload_error: (e)->
        @el.toggleClass('active failed')
        FileUploader.uploader.report_finished(@)

    abort: (e)->
        @xhr.abort()

    remove_upload: (e)->
        @remove()
        if not @complete
            FileUploader.uploader.remove_upload(@)


UploaderView = Backbone.View.extend
    # View responsible for rendering whole uploader applet.
    #
    # Methods:
    #
    # add_files - callback called when user selects files.
    # add_file - helper function for add_files.
    # upload_next - starts uploading next file, in case, there's available
    #               spots.
    # report_finished - function, which is called when FileUploadView
    #                   finishes (by either failing, aborting or completing)
    #                   uploading.
    # clear_finished - removes all finished FileUploadViews from uploader.
    # remove_queue - removes all FileUploadViews, that are not yet finished.
    events: {
        'click #toggle-uploader': 'toggle_visibility',
        'change input[type="file"]': 'add_files',
        'click .clear': 'clear_finished'
    }

    initialize: ()->
        @el = $('<div />', {'id': 'uploader'})
        @upload_queue = []
        @finished_uploads = []
        @upload_count = window.BFMOptions.uploads_at_once
        @active_uploads = 0

    render: ()->
        @el.appendTo($('body'))
        @el.append(_.template($('#uploader_tpl').html()))
        @file_table = @el.find('#uploader-table')
        if @can_upload_directory()
            @el.find('.upload-folder').parent().css('display', 'inline-block')

        @delegateEvents(@events)
        $('html').on('dragenter.uploaderdrag', (e)=> @show_droptarget(e))
        $('html').on('dragleave.uploaderdrag', (e)=> @hide_droptarget(e))
        @el.find('#uploader-droptarget').on('drop', (e)=> @drop(e))

    can_upload_directory: ()->
        # Checks for browser ability to select directory instead of files in
        # file selection dialog. It is way faster. WAAAAY FASTER.
        #
        # Currently known to work only in Chrome(-ium) daily builds.
        input = document.createElement('input')
        input.type = "file"
        return input.directory? or input.webkitdirectory? or input.mozdirectory?

    toggle_visibility: (e)->
        # Shows or hides uploader depending on its current status.
        @el.toggleClass('visible')

    add_files: (e)->
        # Adds all selected files to upload queue.
        _.forEach(e.currentTarget?.files || e.dataTransfer?.files, (file)=>
            _.defer(()=>@add_file(file))
        )

    add_file: (file)->
        # Adds one file to queue and renders it into uploader.
        if (if file.name? then file.name else file.fileName) == "."
            return
        view = new FileUploadView(file)
        @file_table.append(view.render_el())
        @upload_queue.push(view)
        @upload_files()

    upload_files: ()->
        # Try to start file upload.
        # We'll loop until at least one file will start.
        while @upload_count - @active_uploads > 0
            # We can't do anything if we have no files, right?
            if @upload_queue.length == 0
                break
            # Take file and start it.
            uploadable = @upload_queue.shift()
            if uploadable
                uploadable.start_upload()
                @active_uploads += 1
                break

        # Add/remove exit confirmation
        if @active_uploads>0
            window.onbeforeunload = @unload_message
        else
            window.onbeforeunload = null

    report_finished: (file)->
        @active_uploads -= 1
        @finished_uploads.push(file)
        @upload_files()

    remove_upload: (file)->
        # Remove upload from queue.
        index = @upload_queue.indexOf(file)
        if index != -1
            delete(@upload_queue[index])

    clear_finished: (e)->
        while @finished_uploads.length > 0
            @finished_uploads.pop().remove()

    unload_message: (e)->
        return (e.returnValue = $.trim($('#upload_cancel_tpl').text()))

    show_droptarget: (e)->
        if not @block?
            @block = $('<div />', {'class': 'blocker'})
            @block.appendTo($('body'))
            @el.addClass('dragging visible')

        @drag_count = if @drag_count? then @drag_count + 1 else 1

    hide_droptarget: (e)->
        if @drag_count - 1 == 0
            _.defer(()=> @el.removeClass('dragging'))
            if @block?
                @block.remove()
                delete(@block)
            delete(@drag_count)
        else
            @drag_count -= 1

    drop: (e)->
        e.stopPropagation()
        e.preventDefault()
        @hide_droptarget(e)
        console.log(e)
        @add_files(e.originalEvent)


    # render_droptarget: ()->
    #     if not @drop_target
    #         @drop_target = _.template($('#uploader_droptarget').html())
    #         @el.find('.uploader-table-container').append(@drop_target)
    #         @drop_target = @el.find('#uploader-droptarget')
    #         @drop_target.on('dragover', ()=> @drop_target.addClass('over'))
    #                     .on('dragleave', ()=> @drop_target.removeClass('over'))
    #                     .on('drop', (e)=> @drop(e))
    #     if @drag_events == 0
    #         @drop_target.css('opacity', 1)
    #     if not @visible
    #         @toggle_visibility()
    #     @drag_events++

    # remove_droptarget: ()->
    #     --@drag_events
    #     if @drag_events == 0
    #         $(@drop_target).removeClass('over').css('opacity', 0)

    # drop: (e)->
    #     e.stopPropagation()
    #     e.preventDefault()
    #     @add_files(e.originalEvent)
    #     @remove_droptarget()

FileUploader =
    init: ()->
        @uploader = new UploaderView()
        @uploader.render()

    do_browse: (path)->
        @path = path
