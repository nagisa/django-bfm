class FileUploadView extends Backbone.View
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
            @directory = FileUploader.path

    render_el: ()->
        # Render file to a element, attach events and return it.
        filename = if @file.name? then @file.name else @file.fileName
        tpl = _.template($('#file_upload_tpl').html())
        @setElement(tpl({filename: filename}))
        @progress = @$el.find('.progress')
        @percent = @$el.find('.percent')
        @delegateEvents(@events)
        return @$el

    start_upload: ()->
        # If file is not uploading yet, start the upload.
        if not @xhr?
            @$el.addClass('active')
            @xhr = $.ajax_upload(@file, {
                'url': @url,
                'headers': {"X-CSRFToken": @csrf_token},
                'progress': (e, completion)=> @report_progress(e, completion),
                'complete': (e, data)=> @upload_complete(e, data),
                'error': (e)=> @upload_error(e),
                'abort': (e)=> @upload_abort(e)
            })

    report_progress: (e, completion)->
        # Update file representation to conform current upload status.
        percent = completion * 100
        @progress.css('width', "#{percent}%")
        @percent.text("#{percent.toFixed(1)}%")

    upload_complete: (e, data)->
        # Update file representation to finished upload.
        @complete = true
        @report_progress(100)
        @$el.removeClass('active')
        @$el.find('.filename').attr('href', data.url).text(data.filename)
        # Reload file browser
        # I don't like those calls to FileBrowser. Any ideas?
        if @directory == FileBrowser.path
            _.defer(()=>
                FileBrowser.files.add(data)
                FileBrowser.files.updated()
            )
        FileUploader.uploader.report_finished(@)

    upload_abort: (e)->
        # Update file representation to aborted upload.
        @$el.toggleClass('active aborted')
        FileUploader.uploader.report_finished(@)

    upload_error: (e)->
        # Update file representation to failed upload.
        @$el.toggleClass('active failed')
        FileUploader.uploader.report_finished(@)

    abort: (e)->
        @xhr.abort()

    remove_upload: (e)->
        @remove()
        if not @complete
            FileUploader.uploader.remove_upload(@)


class UploaderView extends Backbone.View
    # View responsible for rendering whole uploader applet.

    events: {
        'click #toggle-uploader': 'toggle_visibility',
        'change input[type="file"]': 'add_files',
        'click .clear': 'clear_finished'
    }

    initialize: ()->
        @setElement(@make('div', {'id': 'uploader'}))
        @upload_queue = []
        @finished_uploads = []
        @upload_count = window.BFMOptions.uploads_at_once
        @active_uploads = 0

    render: ()->
        # Add uploader element to window and attach events.
        @$el.appendTo($('body'))
        @$el.append(_.template($('#uploader_tpl').html()))
        @file_table = @$el.find('#uploader-table')
        if @can_upload_directory()
            @$el.find('.upload-folder').parent().css('display', 'inline-block')

        @delegateEvents(@events)
        $('html').on('dragenter.uploaderdrag', (e)=> @show_droptarget(e))
        $('html').on('dragleave.uploaderdrag', (e)=> @hide_droptarget(e))
        @$el.find('#uploader-droptarget').on('drop', (e)=> @drop(e))

    can_upload_directory: ()->
        # Checks for browser ability to select directory instead of files in
        # file selection dialog. It is way faster. WAAAAY FASTER.
        #
        # Has no entry in HTML5 specification.
        # Currently known to work only in Chrome(-ium) daily builds.
        input = document.createElement('input')
        input.type = "file"
        return input.directory? or input.webkitdirectory? or input.mozdirectory?

    toggle_visibility: (e)->
        # Shows or hides uploader depending on its current status.
        @$el.toggleClass('visible')

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
        # We'll try until at least one file will start or we exhaust our queue.
        while @upload_count - @active_uploads > 0
            # We can't do anything if we have no files, right?
            if @upload_queue.length == 0
                break
            uploadable = @upload_queue.shift()
            if uploadable?
                uploadable.start_upload()
                @active_uploads += 1
                break

        # Add/remove exit confirmation
        if @active_uploads>0
            window.onbeforeunload = @unload_message
        else
            window.onbeforeunload = null

    report_finished: (file)->
        # Callback to handle finished uploads.
        @active_uploads -= 1
        @finished_uploads.push(file)
        @upload_files()

    remove_upload: (file)->
        # Remove upload from queue.
        index = @upload_queue.indexOf(file)
        if index != -1
            delete(@upload_queue[index])

    clear_finished: (e)->
        # Remove all finished files.
        while @finished_uploads.length > 0
            @finished_uploads.pop().remove()

    unload_message: (e)->
        # Return message which should be said when user tries quit while still
        # some uploads are pending.
        return (e.returnValue = $.trim($('#upload_cancel_tpl').text()))

    show_droptarget: (e)->
        # Make drag-and-drop target visible. This callback may be called a lot.
        if not @block?
            @block = $(@make('div', {'class': 'blocker'}))
            @block.appendTo($('body'))
            @$el.addClass('dragging visible')

        @drag_count = if @drag_count? then @drag_count + 1 else 1

    hide_droptarget: (e)->
        # Hide drag-and-drop-target. This callback may be called a lot, however
        # while user drags it shouldn't be called more than show_droptarget.
        if @drag_count - 1 == 0
            _.defer(()=> @$el.removeClass('dragging'))
            if @block?
                @block.remove()
                delete(@block)
            delete(@drag_count)
        else
            @drag_count -= 1

    drop: (e)->
        # Handle file drop.
        e.stopPropagation()
        e.preventDefault()
        # @hide_droptarget doesn't get called when user drops a file.
        @hide_droptarget(e)
        @add_files(e.originalEvent)


FileUploader =
    init: ()->
        @uploader = new UploaderView()
        @uploader.render()

    do_browse: (path)->
        @path = path
