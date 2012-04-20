$(document).ready(function () {
  // OPTIMIZE: I18n
  // OPTIMIZE: var node_numeric_id ricavato in 3 modi diversi

  var initial_node_id = location.pathname.split("/").slice(0, 3).pop();

  // tree instance
  $("#tree").jstree({
    core : {
      initially_open  : ["[data-is-root='true']"],
      strings : {
        loading : "Caricamento...",
        new_node : "Nuovo livello"
      }
    },
    plugins : ["themes", "ui", "dnd", "crrm", "json_data"],
    themes : {
      theme : "apple",
      dots : false,
      icons : true
    },
    ui : {
      initially_select : ["#node-" + initial_node_id],
      "select_limit" : 1
    },
    crrm : {
      move : {
        check_move : function (data) {
          return NodeManipulation.check_move(data);
        }
      }
    },
    json_data : {
      ajax : {
        dataType : "json",
        url : "tree"
      }
    }
  }) // end jstree config
  .bind("create.jstree", function (e, data) {
    NodeManipulation.create(data);
  })
  .bind("remove.jstree", function (e, data) {
    NodeManipulation.remove(data);
  })
  .bind("rename.jstree", function (e, data) {
    NodeManipulation.rename(data);
  })
  .bind("move_node.jstree", function (e, data) {
    NodeManipulation.move_node(data);
  }); // end jstree instance

  var NodeManipulation = {

    create : function (data) {
      $("#tree").block({
        message:null
      });

      $.post(
        "/fonds/",  // url (path), la action e' sempre create perche' la request e' $.post
        {
          "fond[parent_id]" : data.rslt.parent.attr("id").replace("node-", ""),
          "fond[name]" : data.rslt.name
        },

        function (json_response) {
          if(json_response.status) {
            $(data.rslt.obj).attr("id", "node-" + json_response.node.id);
          }
          else {
            $.jstree.rollback(data.rlbk);
          }
          $("#tree").unblock();
        }
        );
      return false;
    },

    rename : function (data) {
      var node_numeric_id = data.rslt.obj.attr("id").replace("node-", "");
      var new_name        = data.rslt.new_name;
      var url             = "/fonds/" + node_numeric_id + "/rename";
      $("#tree").block({
        message:null
      });

      $.post(
        url,
        {
          "_method"    : "PUT", // notice the underscore (rails mimics the put with _method param)
          "id"         : node_numeric_id,
          "fond[name]" : new_name
        },
        function (json_response) {
          if(json_response.status == 'success') {
            $("#ajax-form-wrapper input#fond_name").val(json_response.node.name);
          } else {
            $.jstree.rollback(data.rlbk);
          }
          $("#tree").unblock();
        }
        );
      return false;
    },

    remove : function(data) {
      var node_numeric_id = data.rslt.obj.attr("id").toString().replace("node-", "");
      $("#tree").block({
        message:null
      });

      $.post(
        "/fonds/" + node_numeric_id + "/move_to_trash",
        {
          "_method" : "PUT",
          "id" : node_numeric_id
        },
        function (json_response) {
          if(json_response.status == 'success') {
            $(".jstree-clicked").trigger("click");
            $("#trash").show();
          } else {
            $.jstree.rollback(data.rlbk);
          }
          $("#tree").unblock();
        }
        );
      return false;
    },

    move_node : function(data) {
      // the returned object "data.rslt" contains:
      // .o - the node being moved
      // .r - the reference node in the move
      // .ot - the origin tree instance
      // .rt - the reference tree instance
      // .p - the position to move to (may be a string - "last", "first", etc)
      // .cp - the calculated position to move to (always a number)
      // .np - the new parent
      var $moved_node = data.rslt.o;
      $("#tree").block({
        message:null
      });
      var node_numeric_id = $moved_node.attr("id").replace("node-", "");

      $.post(
        "/fonds/" + node_numeric_id + "/move",
        {
          "_method" : "PUT",
          "id" : node_numeric_id,
          "fond[new_parent_id]" : data.rslt.np.attr("id").replace("node-",""), //new parent
          "fond[new_position]" : data.rslt.cp, // new calculated position, starts from zero when new parent, or moving up inside siblings
          "fond[name]" : data.rslt.name // original name
        },
        function (json_response) {
          $("#tree").unblock();
          if(json_response.status != 'success') {
            $.jstree.rollback(data.rlbk);
          }
        }
        );
      return false;
    },

    check_move : function(data) {
      // see move_node for the properties of the "data" object
      var marker_id = /^node-/;
      var test = data.np.attr("id").match(marker_id) !== null;
      return test;
    }
  }; // end of NodeManipulation-namespaced functions

  // EVENTS

  $("#tree ul li").live("dblclick", function() {
    $("#tree").jstree("rename", this);
    return false;
  });

  $("span.jstree-action").click(function(event) {
    $("#tree").jstree(this.id);
    event.preventDefault();
  });

  $("#remove-node").click(function() {
    var $node = $(".jstree-clicked").parent();
    if ($node.attr("data-is-root") == "true" ) {
      alert("Non è possibile rimuovere il livello iniziale");
    } else {
      var question = "Confermi l'eliminazione del livello selezionato e dei livelli dipendenti?";
      var answer   = confirm( question );
      if(answer == 1) {
        $("#tree").jstree("remove", $node);
      }
    }
    return false;
  });

  $("#trash").click(function() {
    var root_fond_id = $(this).data("target");
    var path_items = [location.host, "fonds", root_fond_id, "trash"];
    location.href = location.protocol + '//' + path_items.join("/");
  });

  function reprocessWidths() {
    var width = $('#tree-wrapper').width();
    $('#tree-wrapper').css('height', 'auto');
    $('#main').css('left', width + 'px');
    $('#main-form-controls').css('left', width+1 + 'px');
  }

  $("#tree-wrapper").resizable({
    handles : {
      'e': "#handle"
    },
    minWidth : 280,
    maxWidth : 760,
    resize: function() {
      reprocessWidths();
    },
    stop: function(event, ui) {
      $.cookie('tree_width', ui.size.width, {
        expires: 30,
        path: '/'
      });
    }
  });

  $("#tree").unblock();

  $("#ajax-form-wrapper")
  .block({
    message : $(this).data('loading-message')
    })
  .load(location.pathname.replace('treeview', 'edit'), function(){
    $(this).unblock();
  });

  $("#tree ul li a").live("click", function() {
    var $this               = $(this);
    var editing_record_id   = $this.parent("li").attr('id').split("-").pop();
    var edit_path           = "/fonds/"+ editing_record_id + "/edit";
    var $ajax_form_wrapper  = $("#ajax-form-wrapper");
    var $ajax_form          = $("form[data-node-id]");
    var current_record_id   = $ajax_form.data('record-id'); // OPTIMIZE: ridondante ?

    if (editing_record_id != current_record_id) {
      $ajax_form_wrapper.block({
        message : $ajax_form_wrapper.data('loading-message')
      });
      $ajax_form_wrapper.load(edit_path, function(){
        $ajax_form_wrapper.unblock();
      });
    }
  });

  $("#ajax-form-wrapper").on("click", '#fond-preview', function(event){
    if ($(this).hasClass("disabled")) {
      return false;
    }
  });

  $("#ajax-form-wrapper").delegate("form", 'submit', function(event) {
    var $ajax_form_wrapper, $form, url, node_id, $node, node_ins, $html_response, node_description;

    $ajax_form_wrapper  = $("#ajax-form-wrapper");
    $form               = $(this);
    url                 = location.href.replace(location.pathname, '').replace(/#/g, '') + $form.attr("action");
    node_id             = $form.data("node-id");
    $node               = $("#"+ node_id +" > a");
    node_ins            = $node.html().match(/<ins.*\/ins>/);

    // block the interface
    $ajax_form_wrapper.block({
      message : $ajax_form_wrapper.data('loading-message')
    });

    $.post(url, $form.serialize(), 'html')
    .success(function(data, textStatus, jqXHR){
      // gather description for the current tree node (data attribute)
      $html_response = $(data);
      $form = $html_response.filter(function(index, element){
        return $(element).is('form');
      });
      node_description = $form.data("node-description");
      // replace content with html response
      $ajax_form_wrapper.html($html_response);
      // bring the main div to top
      $("#main").scrollTop(0);
      // update description in tree node
      $node.html(node_ins + node_description);
      // reprocess widths of tree and main divs
      reprocessWidths();
      // unblock the interface
      $ajax_form_wrapper.unblock();
    });

    return false;
  });

  $("#fond-editor-name-autocomplete").archimate_autocomplete_setup();

  $("[id$='-name-autocomplete']").keypress(function(event) {
    if (event.keyCode == 13) {
      event.preventDefault();
    }
  });

  $("#fond-editor-name-autocomplete").autocomplete('option', 'select', function(event, ui){
    $("#fond-editor-name-autocomplete").attr("value", ui.item.value);
    return false;
  });

});

