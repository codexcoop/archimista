/* FILE: units-full_path.js */

$(document).ready(function () {

  $("#close-fonds-tree-wrapper").hide();

  $("#confirm-new-fond").live('click', function(){
    if($(".jstree-clicked").length == 0) {
      alert("Selezionare un complesso");
    } else {
      $("#close-fonds-tree-wrapper").hide();
      $("#load-fonds-tree-wrapper").show();

      var unit_id = $(this).data('unit-id');
      var new_fond_id = $(".jstree-clicked").parent().attr("id").split("-").pop();

      if(unit_id != undefined){
        var url = "/units/" + unit_id + "/render_full_path";
      } else {
        var url = "/units/new/render_full_path";
      }

      $.get(
        url,
        { fond_id : new_fond_id },
        function(html_response){
          $("#unit-path-content").html(html_response);
          $("#close-fonds-tree-wrapper").hide();
        }
      );
      $("#unit-path-tree-wrapper").slideUp('slow');
      $("input#unit_fond_id").val(new_fond_id);
    }
    return false;
  });

  var ajax_tree = function(root_fond_id, fond_id){
    $.getScript("/javascripts/jsTree/jquery.jstree.min.js", function(){
      $.jstree._themes = "/javascripts/jsTree/themes/";
      $("#unit-path-tree").bind("loaded.jstree", function(event, data) {
        $(this).jstree("open_all");
      });
      $("#unit-path-tree").jstree({
        plugins   : ["themes", "ui", "json_data"],
        themes    : { theme : "apple", dots : false, icons : true },
        ui        : { initially_select : ["#node-"+ fond_id], "select_limit" : 1 },
        json_data : {
          ajax : {
            dataType : "json",
            url : "/fonds/" + root_fond_id + "/tree"
          }
        }
      });
    });
  };

  var load_fonds_tree = function(options){
    var $command      = $(options.command);
    var $current_root = $("#unit-path-tree [data-is-root='true']");
    var fond_id       = options.fond_id || $command.data('fond-id');
    var root_fond_id  = options.root_fond_id || $command.data('root-fond-id');

    if (!root_fond_id) return false;

    if ($current_root.length == 0) {
      ajax_tree(root_fond_id, fond_id);
    } else {
      var current_root_id = $current_root.attr("id").replace("node-","").toString();
      if (root_fond_id != current_root_id) {
        ajax_tree(root_fond_id, fond_id);
      }
    }

    return false;
  };

  $("#load-fonds-tree").live('click', function(event){
    $("#load-fonds-tree-wrapper").hide();
    $("#close-fonds-tree-wrapper").show();
    $("#unit-path-tree-wrapper").slideDown('slow');
    load_fonds_tree({command:this});
    return false;
  });

  $("#close-fonds-tree").live('click', function(){
    $("#load-fonds-tree-wrapper").show();
    $("#close-fonds-tree-wrapper").hide();
    $("#unit-path-tree-wrapper").slideUp('slow');
    return false;
  });

});

