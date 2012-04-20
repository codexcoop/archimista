/* FILE: units-classify.js */

$(document).ready(function(){

  var $tree = $("#classify-tree");

  function selected_tree_node_id(){
    var selected_element_id, node_record_id;
    selected_element_id = $tree.find(".jstree-clicked").parent("li").attr('id');
    if ( selected_element_id === undefined ) {
      return null;
    } else {
      node_record_id = selected_element_id.replace(/^node-/i, '');
      return node_record_id || null;
    }
  }

  // DIALOG MASS
  $("#mass-classify").click(function(){
    if ( $tree.children().length > 0 ) { return null; }

    $tree
    .bind('loaded.jstree', function(event, data){
      $tree.jstree("open_all");
      // OPTIMIZE: DRY (fare funzione, codice ripetuto qui e in units-jump_to)
      $tree.find('li a').each(function() {
        var units_count = $(this).parent("li").data('units');
        $(this).append(' <em>(' + units_count + ')</em>');
      });
    })
    .bind("select_node.jstree", function(event, data){
      $("#confirm-classify").prop("disabled", false).removeClass("disabled");
    })
    .jstree({
      plugins   : ["themes", "ui", "json_data"],
      themes    : { theme : "apple", dots : false, icons : true },
      ui        : { initially_select : [], "select_limit" : 1 },
      json_data : {
        ajax : {
          dataType : "json",
          url : "/fonds/" + $tree.data('root-fond-id') + "/tree"
        }
      }
    });
  });

  // Avvia chiamata ajax per il save
  function submit_new_classification () {
    var $button, params, new_fond_id, $checkboxes;
    $checkboxes = $("input:checkbox.selected-record-id");
    $button = $(this);
    new_fond_id = selected_tree_node_id();
    params      = $checkboxes.filter(":checked").serializeArray();
    params      = params.concat([
                    {'name' : 'new_fond_id', 'value' : new_fond_id},
                    {'name' : '_method', 'value' : 'PUT'}
                  ]);
    $.ajax({
      dataType  : 'json',
      type      : 'POST',
      data      : params,
      url       : "/units/classify"
    }).success(function(data, textStatus, jqXHR){
      var $checkboxes;

      $("input:checkbox#select-all-records").prop('checked', false);
      $checkboxes = $("input:checkbox.selected-record-id");

      window.location.replace(data.new_location);
      $checkboxes.prop('checked', false);
    });
  }

  $("#confirm-classify").click(function() {
     submit_new_classification();
  });
});
