readable_size = (size)->
    # Converts given size in bytes to normalized size.
    #
    # Returns string containing number and multiplier.
    table = [
        # Mult.     |Biggest size in bytes  |Decimal digits
        ['B',       1024,                   0],
        ['KB',      1048576,                0],
        ['MB',      1073741824,             1],
        ['GB',      1099511627776,          2],
        ['TB',      1125899906842624,       3]
    ]
    for s in table
        if size < s[1]
            return "#{(size / (s[1] / 1024)).toFixed(s[2])} #{s[0]}"


class Dialog extends Backbone.View
    tagName: 'form'
    className: 'dialog'
    events:
        "click .submit": 'call_callback'
        "click .cancel": 'cancel'

    tear_down: ()->
        @remove()
        @blocker.remove()

    cancel: (e)->
        @tear_down()
        e.preventDefault()

    call_callback: (e)->
        @tear_down()
        e.preventDefault()
        object = {}
        for key, field of $(@el).serializeArray()
            object[field.name] = field.value
        @callback(object)

    initialize: ({@template, @model, @callback, @hook})->

    render: ()->
        @blocker = new Block()
        @blocker.render()

        tpl = _.template($(@template).html(), @model?.attributes or {})
        $('body').append(@$el.html(tpl)).append(@block)

        if @hook?
            @hook(@)


class ContextMenu extends Backbone.View
    tagName: 'ul'
    className: 'contextmenu'

    initialize: ()->
        @$body = $('body')

    clicked: (callback)->
        @remove()
        if callback?
            callback()

    add_entry: (entry, callback)->
        @$el.append(entry)
        $(entry).click(()=>@clicked(callback))

    add_entries: (entries, callbacks)->
        entries = entries.filter('li')
        _.each(entries, (entry, key)=>
            @add_entry(entry, callbacks[key])
        )

    remove: ()->
        _.defer(()=> @blocker.remove())
        super()

    render: (e)->
        width = @$el.appendTo(@$body).outerWidth()
        top = e.pageY
        left = e.pageX
        if left + width >= $(document).width()
            left = $(document).width() - width
        @$el.css({'top': top + 1, 'left': left + 1})

        handle = (b, e)=> @remove(b, e)
        @blocker = new Block({'mousedown': handle, 'contextmenu': handle})
        @blocker.render()


class Block extends Backbone.View
    tagName: 'div'
    className: 'blocker'

    initialize: (callbacks)->
        @callbacks = {}
        for key, callback of callbacks
            @callbacks[key] = @wrap_callback(callback)
        @delegateEvents(@callbacks)

    render: ()->
        @$el.appendTo($('body'))

    wrap_callback: (callback)->
        return (e)=>
            e.preventDefault()
            e.stopImmediatePropagation()
            return callback(@, arguments...)
