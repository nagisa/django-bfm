jQuery.ajax_upload = (file, options) ->
    $ = jQuery;
    readable_size = (size) ->
        table = [['B', 1024, 0],['KB', 1048576, 0],['MB', 1073741824, 1],
                 ['GB', 1099511627776, 2], ['TB', 1125899906842624, 3]]
        for s in table
            if size < s[1]
                return "#{(size/(s[1]/1024)).toFixed(s[2])} #{s[0]}"
    stats_averages = (time, loaded) ->
        stats.push
            time: time
            loaded: loaded
        while time - stats[0].time > 10000
            stats.shift()
        time_diff = time - stats[0].time
        size_diff = loaded - stats[0].loaded
        speed = ~~((size_diff*1000/time_diff)+0.5)
        completion = loaded/file.size
        if completion > 1
            completion = 1
        last_call = time - stats[stats.length-2].time
        last_call = last_call + last_call/10
        return completion: completion, speed: speed, last_call: last_call
    progress = (e) ->
        settings.progress e, stats_averages(new Date(), e.loaded)

    settings =
        headers:
            "X-CSRFToken": null
        url: null
        progress: ->
        complete: ->
        error: ->
        abort: ->

    $.extend(settings, options)

    xhr = new XMLHttpRequest()
    form = new FormData()
    form.append "file", file
    stats = [
        time: new Date()
        loaded: 0
    ]
    xhr.upload.addEventListener "progress", ((e) => progress(e)), false
    xhr.addEventListener "load", ((e) => settings.complete(e)), false
    xhr.addEventListener "error", ((e) => settings.error(e)), false
    xhr.addEventListener "abort", ((e) => settings.abort(e)), false

    xhr.open "POST", settings.url
    for header, value of settings.headers
        xhr.setRequestHeader header, value
    xhr.send form
    return xhr