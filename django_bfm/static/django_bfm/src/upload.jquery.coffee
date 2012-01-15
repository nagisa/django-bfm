if jQuery?
    $ = jQuery
else
    $ = django.jQuery
$ ->
    $.ajax_upload = (file, options)->
        # jQuery method. Handles file upload with status reporting.

        stats_averages = (time, loaded)->
            # Averagerizes stats.
            # Takes in new values of time and loaded ammount as arguments.
            stats.push
                time: time
                loaded: loaded
            while(time - stats[0].time > 10000)
                stats.shift()
            time_diff = time - stats[0].time
            size_diff = loaded - stats[0].loaded
            speed = ~~((size_diff*1000/time_diff)+0.5) # Double bitwise NOT
            completion = loaded/file.size
            if(completion > 1)
                completion = 1
            last_call = time - stats[stats.length-2].time
            last_call = last_call + last_call/10
            return completion: completion, speed: speed, last_call: last_call

        progress = (e)->
            # Reports progress to callback passed to this function.
            settings.progress(e, stats_averages(new Date(), e.loaded))

        complete = (e)->
            # Reports to outside, that uploading has finished...
            if(xhr.status == 200)
                data = JSON.parse(xhr.response)
                settings.complete(e, data)
            else
                settings.fail(e)

        settings =
            headers:
                "X-CSRFToken": null
            url: null
            progress: ->
            complete: ->
            error: ->
            abort: ->
            fail: (e)-> settings.error(e) # If someone someday would need
                                           # optimization.
        $.extend(settings, options)
        xhr = new XMLHttpRequest()
        form = new FormData()
        form.append("file", file)
        stats = [
            time: new Date()
            loaded: 0
        ]

        xhr.upload.addEventListener("progress", ((e)=> progress(e)), false)
        xhr.addEventListener("load", ((e)=> complete(e)), false)
        xhr.addEventListener("error", ((e)=> settings.error(e)), false)
        xhr.addEventListener("abort", ((e)=> settings.abort(e)), false)

        xhr.open("POST", settings.url)
        for header, value of settings.headers
            xhr.setRequestHeader(header, value)
        xhr.send(form)
        return xhr
