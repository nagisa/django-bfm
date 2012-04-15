$ = if jQuery? then jQuery else django.jQuery

$ ->
    $.ajax_upload = (file, options)->
        # jQuery method. Handles file upload with status reporting.

        progress = (e)=>
            completion = e.loaded / file.size
            completion = if ~~completion == 1 then 1 else completion
            settings.progress(e, completion)

        complete = (e)=>
            if(~~(xhr.status / 100) == 2)
                data = JSON.parse(xhr.response)
                settings.complete(e, data)
            else
                settings.fail(e)

        settings = {
            headers: {"X-CSRFToken": null},
            url: null,
            progress: =>,
            complete: =>,
            error: =>,
            abort: =>,
            fail: (e)-> settings.error(e)
        }
        $.extend(settings, options)

        xhr = new XMLHttpRequest()
        xhr.upload.addEventListener("progress", progress, false)
        xhr.addEventListener("load", complete, false)
        xhr.addEventListener("error", settings.error, false)
        xhr.addEventListener("abort", settings.abort, false)
        xhr.open("POST", settings.url)
        for header, value of settings.headers
            xhr.setRequestHeader(header, value)

        form = new FormData()
        form.append("file", file)
        xhr.send(form)

        return xhr
