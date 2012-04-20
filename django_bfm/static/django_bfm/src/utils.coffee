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
    # View responsible for rendering dialog box from given template.
    #
    # Methods:
    #
    # tear_down - destroys dialog box.
    # cancel - event callback, called when user clicks on "Cancel" button.
    # call_Callback - event callback, called when user submits dialog.
    #                 This function is also responsible for calling function
    #                 given as callback when Dialog was initialized.
    # render - draws dialog box into window.
    tagName: 'form'
    className: 'dialog'
    events:
        "click .submit": 'call_callback'
        "click .cancel": 'cancel'

    tear_down: ()->
        @remove()
        @block.remove()

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

    initialize: ({@template, @data, @callback, @hook})->


    render: ()->
        @block = $('<div />', {class: 'blocker'})

        tpl = _.template($(@template).html(), if @data? then @data else {})
        $('body').append(@$el.html(tpl)).append(@block)

        if @hook?
            @hook(@)


class ContextMenu extends Backbone.View
    tagName: 'ul'
    className: 'contextmenu'

    initialize: ()->
        @el = $(@el)
    clicked: (callback)->
        @el.hide(200, ()=>@remove())
        if callback?
            callback()
    add_entry: (entry, callback)->
        @el.append(entry)
        $(entry).click(()=>@clicked(callback))
    add_entries: (entries, callbacks)->
        entries = entries.filter('li')
        _.each(entries, (entry, key)=>
            @add_entry(entry, callbacks[key])
        )
    render: (e)->
        width = @el.appendTo($('body')).outerWidth()
        @el.hide().show(200, ()=> $('html').one('mouseup', ()=>@clicked()))
        top = e.pageY
        left = e.pageX
        if left + width >= $(document).width()
            left = $(document).width() - width
        @el.css(top: top, left: left)
