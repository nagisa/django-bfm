(function() {
  $(function() {
    var BFMChildDirectoriesView, BFMDirectories, BFMDirectoriesView, BFMDirectoryView, BFMFile, BFMFileTableView, BFMFileView, BFMFiles, BFMUrls, D, Dirs, Files, Route, Table, readable_size;
    readable_size = function(size) {
      var s, table, _i, _len;
      table = [['B', 1024, 0], ['KB', 1048576, 0], ['MB', 1073741824, 1], ['GB', 1099511627776, 2], ['TB', 1125899906842624, 3]];
      for (_i = 0, _len = table.length; _i < _len; _i++) {
        s = table[_i];
        if (size < s[1]) {
          return "" + ((size / (s[1] / 1024)).toFixed(s[2])) + " " + s[0];
        }
      }
    };
    BFMFile = Backbone.Model.extend({
      initialize: function() {
        this.set({
          'date': new Date(this.get('date'))
        });
        return this.set({
          'pdate': this.parseDate(),
          'psize': this.parseSize()
        });
      },
      delete_file: function() {
        return $.ajax({
          url: this.url,
          data: {
            action: 'delete',
            file: this.get('filename'),
            directory: this.get('rel_dir')
          }
        });
      },
      touch_file: function() {
        return $.ajax({
          url: this.url,
          data: {
            action: 'touch',
            file: this.get('filename'),
            directory: this.get('rel_dir')
          }
        });
      },
      url: 'file/',
      parseDate: function() {
        var d;
        d = this.get("date");
        return "" + (d.getFullYear()) + "-" + (d.getMonth()) + "-" + (d.getDate());
      },
      parseSize: function() {
        return readable_size(this.get('size'));
      }
    });
    BFMFiles = Backbone.Collection.extend({
      url: 'list_files/',
      initialize: function(attrs) {
        return this.bind('reset', this.added);
      },
      comparator: function(model) {
        var date, dh, dt;
        date = model.get('date');
        dt = date.getFullYear() * 10000 + date.getMonth() * 100 + date.getDate();
        dh = date.getHours() * 100 + date.getMinutes();
        return -(dt + dh * 0.0001);
      },
      comparators: {
        date: {
          desc: function(model) {
            var date, dh, dt;
            date = model.get('date');
            dt = date.getFullYear() * 10000 + date.getMonth() * 100 + date.getDate();
            dh = date.getHours() * 100 + date.getMinutes();
            return -(dt + dh * 0.0001);
          },
          asc: function(model) {
            var date, dh, dt;
            date = model.get('date');
            dt = date.getFullYear() * 10000 + date.getMonth() * 100 + date.getDate();
            dh = date.getHours() * 100 + date.getMinutes();
            return dt + dh * 0.0001;
          }
        },
        size: {
          desc: function(model) {
            return -model.get('size');
          },
          asc: function(model) {
            return model.get('size');
          }
        },
        filename: {
          desc: function(model) {
            var str;
            str = model.get("filename");
            str = str.toLowerCase().split("");
            return _.map(str, function(letter) {
              return String.fromCharCode(-(letter.charCodeAt(0)));
            });
          },
          asc: function(model) {
            return model.get("filename");
          }
        },
        mime: {
          desc: function(model) {
            var str;
            str = model.get("mimetype");
            str = str.toLowerCase().split("");
            return _.map(str, function(letter) {
              return String.fromCharCode(-(letter.charCodeAt(0)));
            });
          },
          asc: function(model) {
            return model.get('mimetype');
          }
        }
      },
      model: BFMFile,
      added: function() {
        return _.forEach(this.models, function(model) {
          return new BFMFileView({
            'model': model
          }).render();
        });
      }
    });
    BFMDirectories = Backbone.Collection.extend({
      url: 'list_directories/',
      initialize: function(attrs) {
        return this.bind('reset', this.added);
      },
      added: function() {
        return _.forEach(this.models, function(model) {
          return new BFMDirectoryView({
            'model': model.attributes
          }).render();
        });
      }
    });
    BFMFileTableView = Backbone.View.extend({
      el: $('#result_list'),
      current_row: 1,
      ord: ['date', true],
      events: {
        'click th': 'resort_date'
      },
      resort_date: function(e) {
        var name;
        name = e.currentTarget.getAttribute('data-name');
        if (!Files.comparators[name]) {
          return false;
        }
        if (this.ord[0] === name) {
          this.ord[1] = !this.ord[1];
        } else {
          this.ord = [name, true];
        }
        this.clear();
        if (this.ord[1]) {
          Files.comparator = Files.comparators[name].desc;
        } else {
          Files.comparator = Files.comparators[name].asc;
        }
        return Files.sort();
      },
      clear: function() {
        this.current_row = 1;
        this.el.html('');
        this.append($('<thead/>').append($('<tr/>')));
        return this.draw_head();
      },
      append: function(element) {
        return this.el.append(element);
      },
      prepend: function(element) {
        return this.el.prepend(element);
      },
      draw_head: function() {
        var c, cl;
        c = {};
        cl = 'descending';
        if (!this.ord[1]) {
          cl = 'ascending';
        }
        c[this.ord[0]] = cl + ' sorted';
        return this.el.find('tr:first').append($('#fileBrowseHeadTemplate').tmpl(c));
      },
      get_row_class: function() {
        this.current_row = (this.current_row + 1) % 2;
        return "row" + (this.current_row + 1);
      }
    });
    BFMDirectoriesView = Backbone.View.extend({
      el: $('.directory-list'),
      append: function(elm) {
        return this.el.append(elm);
      }
    });
    BFMDirectoryView = Backbone.View.extend({
      tagName: 'li',
      events: {
        "click .directory": "load_directory"
      },
      load_directory: function(e) {
        e.stopImmediatePropagation();
        Route.goto(this.model.rel_dir);
        Dirs.el.find('.selected').removeClass('selected');
        return this.el.children('a').addClass('selected');
      },
      initialize: function(attrs) {
        this.model = attrs.model;
        return this.el = $(this.el);
      },
      render: function() {
        return Dirs.append(this.srender());
      },
      srender: function() {
        var child;
        this.el.html("<a class='directory'>" + this.model.name + "</a>");
        if (this.model.childs != null) {
          child = new BFMChildDirectoriesView({
            'childs': this.model.childs,
            'parent': this
          });
          child.render();
        }
        return this.el;
      },
      append: function(element) {
        return this.el.append(element);
      }
    });
    BFMChildDirectoriesView = Backbone.View.extend({
      tagName: 'ul',
      initialize: function(attrs) {
        this.el = $(this.el);
        this.childs = attrs.childs;
        return this.parent = attrs.parent;
      },
      render: function() {
        var callback;
        callback = function(child) {
          var directory;
          directory = new BFMDirectoryView({
            'model': child
          });
          return this.parent.append(this.el.append(directory.srender()));
        };
        return _.forEach(this.childs, callback, this);
      }
    });
    BFMFileView = Backbone.View.extend({
      tagName: 'tr',
      events: {
        "click .delete": 'delete',
        "click .touch": 'touch'
      },
      "delete": function(e) {
        this.model.delete_file();
        return this.remove();
      },
      touch: function(e) {
        return this.model.touch_file();
      },
      className: function() {
        return Table.get_row_class();
      },
      initialize: function(attrs) {
        this.table = Table;
        this.attrs = attrs.model.attributes;
        return this.model = attrs.model;
      },
      render: function() {
        var elm;
        elm = $(this.el).html($('#fileBrowseTemplate').tmpl(this.attrs));
        if (this.attrs.mimetype.substring(0, 5) === "image") {
          elm.find('.icons .resize').css('display', 'block');
        }
        return this.table.append(elm);
      }
    });
    BFMUrls = Backbone.Router.extend({
      initialize: function(attrs) {
        this.path = "";
        if ((attrs != null) && (attrs.path != null)) {
          return this.path = attrs.path;
        }
      },
      routes: {
        '*path': 'do_browse'
      },
      do_browse: function(path) {
        Table.clear();
        return Files.fetch();
      },
      goto: function(path) {
        return this.navigate("" + (path || this.path), true);
      }
    });
    Table = new BFMFileTableView();
    Dirs = new BFMDirectoriesView();
    Files = new BFMFiles();
    D = new BFMDirectories;
    D.fetch();
    Route = new BFMUrls();
    return Backbone.history.start();
  });
}).call(this);