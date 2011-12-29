Urls = Backbone.Router.extend
    # Object responsible for managing navigation. Main responsibility is to pass
    # navigation events to seperate parts of application.
    #
    # Methods:
    #
    # do_pass - passes navigation event to every part of application.
    # do_navigate - navigates to first page of root directory.
    routes:
        'path=*path^page=:page': 'do_pass'
        '': 'do_navigate'

    initialize: ()->
        FileBrowser.router = DirectoryBrowser.router = @

    do_pass: (path, page)->
        FileBrowser.do_browse(path, page)
        DirectoryBrowser.do_browse(path)
        FileUploader.do_browse(path)
        return

    do_navigate: (path)->
        @navigate("path=^page=1", true)


$ =>
    new Urls()
    FileUploader.init()
    Backbone.history.start({root: BFMRoot})