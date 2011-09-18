(function() {
  $(function() {
    var BFMDirectoriesView, BFMFile, BFMFileTableView, BFMFileView, BFMFiles, BFMUrls, Route, Table;
    BFMFile = Backbone.Model.extend({
      url: 'file/'
    });
    BFMFiles = Backbone.Collection.extend({
      url: 'list_files/',
      initialize: function(attrs) {
        return this.bind('reset', this.added);
      },
      model: BFMFile,
      added: function() {
        return _.forEach(this.models, function(model) {
          return new BFMFileView({
            'model': model.attributes
          }).render();
        });
      }
    });
    BFMFileTableView = Backbone.View.extend({
      el: $('#result_list'),
      current_row: 1,
      clear: function() {
        this.current_row = 1;
        this.el.html('');
        return this.append($('<thead/>').append($('<tr/>')));
      },
      append: function(element) {
        return this.el.append(element);
      },
      prepend: function(element) {
        return this.el.prepend(element);
      },
      draw_head: function(template) {
        return this.el.find('tr:first').append($('#fileBrowseHeadTemplate').tmpl());
      },
      get_row_class: function() {
        this.current_row = (this.current_row + 1) % 2;
        return "row" + (this.current_row + 1);
      }
    });
    BFMFileView = Backbone.View.extend({
      tagName: 'tr',
      className: function() {
        return Table.get_row_class();
      },
      initialize: function(attrs) {
        this.table = Table;
        return this.model = attrs.model;
      },
      render: function() {
        var elm;
        elm = $(this.el).html($('#fileBrowseTemplate').tmpl(this.model));
        return this.table.append(elm);
      }
    });
    BFMDirectoriesView = Backbone.View.extend({
      el: $('directory-list')
    });
    BFMUrls = Backbone.Router.extend({
      initialize: function(attrs) {
        this.path = "";
        if ((attrs != null) && (attrs.path != null)) {
          this.path = attrs.path;
        }
        this.action = "";
        if ((attrs != null) && (attrs.action != null)) {
          return this.action = attrs.action;
        }
      },
      routes: {
        '*path': 'do_browse'
      },
      do_browse: function(path) {
        var Files;
        Table.clear();
        Table.draw_head('#fileBrowseHeadTemplate');
        Files = new BFMFiles();
        return Files.fetch();
      },
      goto: function(action, path) {
        return this.navigate("" + (this.path || path), true);
      }
    });
    Table = new BFMFileTableView();
    Route = new BFMUrls();
    return Backbone.history.start();
  });
}).call(this);
