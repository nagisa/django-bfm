django.jQuery ->
    $ = django.jQuery
    readable_size = (size) ->
        table = [['B', 1024, 0],['KB', 1048576, 0],['MB', 1073741824, 1],
                 ['GB', 1099511627776, 2], ['TB', 1125899906842624, 3]]
        for s in table
            if size < s[1]
                return "#{(size/(s[1]/1024)).toFixed(s[2])} #{s[0]}"

    select_template = """
    <div class="bfmuploader">
        <form>
            <div class="button submit">Upload files</div>
            <input type="file" class="selector" multiple />
        </form>
    </div>
    """
    uploader_template = """
        <div class="uploadinghead">
            <div class="status">Uploading&nbsp;(<span class="speed">0 B/s</span>)</div>
            <div class="controls"><a class="icon minimize"></a></div>
        </div>
        <div class="uploading">
            <table></table>
        </div>
    """
    file_template = """
        <tr>
            <td class="filename"></td>
            <td class="tight"><a class="icon stop"></a></td>
        </tr>
        <tr class="uploadstatus"><td colspan="2"><span class="progress"></span></td></tr>
    """
    uploaded_template = """
        <a href="#" target="_blank"></a>
    """
    uploadlist = []
    uploadable = (file) ->
        obj =
            file: file
            el: $(file_template)
            upload: () ->
                csrf_token = $('input[name=csrfmiddlewaretoken]').val()
                @xhr = $.ajax_upload @file, {
                    url: "/files/upfile/?directory="
                    headers:
                        "X-CSRFToken": csrf_token
                    progress: ((e, stats) => @report_progress(e, stats))
                    complete: ((e, data) => @upload_complete(e, data))
                    error: ((e) => @upload_error(e))
                    abort: ((e) => @upload_abort(e))
                }
            report_progress: (e, stats) ->
                $('.uploadinghead').find('.status .speed').text("#{readable_size(stats.speed)}/s")
                @el.find('.progress').stop(true).animate({
                    width: "#{stats.completion*100}%"
                }, stats.last_call)
            upload_complete: (e, data) ->
                @el.find('.filename').html $(uploaded_template).text(data.filename).attr('href', data.url)
                @el.find('.progress').stop(true).animate({
                    width: "100%"
                }, 300)
                @next()
            upload_abort: (e) ->
                @el.find('.progress').css('background', '#FF6600')
                @next()
            upload_error: (e) ->
                @el.find('.progress').css('background', '#CC0000')
                @next()

        filename = if obj.file.name? then obj.file.name else obj.file.fileName
        obj.el.find('.filename').text(filename)
        obj.el.find('.stop').click (e)->
            obj.xhr.abort()
        obj.el.appendTo($('.uploading table'))
        return obj

    uploader = () ->
        o =
            el: $(select_template)
            selected: (e) ->
                @el = @el.html($(uploader_template))
                @el.find('.minimize').click (e) => @minimize(e)
                selected_files = e.currentTarget.files
                for file in selected_files
                    f=uploadable(file)
                    f.next = () =>
                        uploadlist.shift()
                        if uploadlist.length>0
                            uploadlist[0].upload()
                        else
                            @complete()
                    uploadlist.push(f)
                uploadlist[0].upload()
            minimize: (e) ->
                @el.find('.minimize').removeClass('minimize').addClass('maximize').unbind().click (e)=>@maximize(e)
                @el.find('.uploading').toggleClass('minimized')
                @el.find('.uploadinghead').toggleClass('minimized')
            maximize: (e) ->
                @el.find('.maximize').addClass('minimize').removeClass('maximize').unbind().click (e)=>@minimize(e)
                @el.find('.uploading').toggleClass('minimized')
                @el.find('.uploadinghead').toggleClass('minimized')
            complete: () ->
                but = @el.find('.minimize') || @el.find('.maximize')
                but.removeClass('minimize maximize').addClass('refresh').unbind().click (e)=>
                    @el.remove()
                    uploader()
        o.el.appendTo('body')
        o.el.find('input[type=file]').bind 'change', (e) => o.selected(e)
    uploader()