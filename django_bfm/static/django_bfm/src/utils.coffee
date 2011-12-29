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
            return "#{ (size / (s[1] / 1024)).toFixed(s[2]) } #{ s[0] }"


directory_upload_support = ()->
    # Checks for browser ability to select directory instead of files in file
    # selection dialog. It is way faster. WAAAAY FASTER.
    #
    # Currently known to work only in Chrome(-ium) daily builds.
    input = document.createElement('input')
    input.type = "file"
    if input.directory? or input.webkitdirectory? or input.mozdirectory?
        return true
    return false


Dialog = Backbone.View.extend
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
        $(@el).fadeOut(200, => @remove())
        $('.block').fadeOut(200)
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
    initialize: (attrs)->
        @url = attrs.url
        @model = attrs.model
        @template = attrs.template
        @callback = attrs.callback
        @hook = attrs.hook
    render: ()->
        tpl = _.template($(@template).html(), @model.attributes)
        element = $(@el).html(tpl)
        $('body').append(element.fadeIn(200))
        $('.block').fadeIn(300)
        if @hook?
            @hook(@)


ContextMenu = Backbone.View.extend
    tagName: 'ul'
    className: 'contextmenu'

    initialize: ()->
        @el = $(@el)
        @block = $('<div />', class: 'block invisible')
    clicked: (callback)->
        @el.fadeOut(200, ()=>@remove())
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
        width = @el.appendTo($('body')).hide().fadeIn(200).outerWidth()
        top = e.pageY + 2
        left = e.pageX
        if left + width >= $(document).width()
            left = $(document).width() - width
        @el.css(top: top, left: left)
        $(document).one('mousedown', ()=>@clicked(()->))