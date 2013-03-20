$(document).ready(function () {

  $('#report-tabs a:first').tab('show');

  $("[id$='-name-autocomplete']").keypress(function (event) {
    if (event.keyCode === 13) {
      event.preventDefault();
    }
  });

  $("#reports-fond-autocomplete").archimate_autocomplete_setup();

  $("#reports-fond-name-autocomplete").autocomplete('option', 'select', function (event, ui) {
    $("#reports-fond-name-autocomplete").attr("value", ui.item.value);
    $("#reports-fond-id-autocomplete").attr("value", ui.item.id);
    $("#reports-fond-choice").submit();
    return false;
  });

  $("#reports-custodian-autocomplete").archimate_autocomplete_setup();

  $("#reports-custodian-name-autocomplete").autocomplete('option', 'select', function (event, ui) {
    $("#reports-custodian-name-autocomplete").attr("value", ui.item.value);
    $("#reports-custodian-id-autocomplete").attr("value", ui.item.id);
    $("#reports-custodian-choice").submit();
    return false;
  });

  $("#reports-project-autocomplete").archimate_autocomplete_setup();

  $("#reports-project-name-autocomplete").autocomplete('option', 'select', function (event, ui) {
    $("#reports-project-name-autocomplete").attr("value", ui.item.value);
    $("#reports-project-id-autocomplete").attr("value", ui.item.id);
    $("#reports-project-choice").submit();
    return false;
  });

  $(".xls, .csv, .pdf, .rtf").click(function(event){
    event.preventDefault();
    if($(this).attr('href') != "#") {
      $.blockUI({
        message: 'Generazione documento in corso'
      });
      $.ajax({
        url: $(this).attr('href'),
        data: {},
        dataType: "json",
        success: function (data) {
          $.unblockUI();
          $(window.location).attr('href', "/reports/download?file=" + data.file);
        }
      });
    }
    return false;
  });

  if($('#turn-off-buttons').length) {
    $(".btn").each(function() {
      $(this).prop('disabled', true).addClass('disabled');
      $(this).prop("href","#");
    });
  }

  $("#close-fonds-tree-wrapper").hide();

  var ajax_tree = function(root_fond_id, fond_id){
    $.getScript("/javascripts/jsTree/jquery.jstree.min.js", function(){
      $.jstree._themes = "/javascripts/jsTree/themes/";
      $("#unit-path-tree").bind("loaded.jstree", function(event, data) {
        $(this).jstree("open_all");
        $(this).find('li a').each(function() {
          var units_count = $(this).parent("li").data('units');
          $(this).append(' <em>(' + units_count + ')</em>');
        });
      });
      $("#unit-path-tree").jstree({
        plugins   : ["themes", "ui", "json_data"],
        themes    : {
          theme : "apple",
          dots : false,
          icons : true
        },
        ui        : {
          initially_select : ["#node-"+ fond_id],
          "select_limit" : 1
        },
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

    if (!root_fond_id) {
      return false;
    }

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
    load_fonds_tree({
      command: this
    });
    return false;
  });

  $("#close-fonds-tree").live('click', function(){
    $("#load-fonds-tree-wrapper").show();
    $("#close-fonds-tree-wrapper").hide();
    $("#unit-path-tree-wrapper").slideUp('slow');
    return false;
  });


  $("#confirm-new-branch").live('click', function(event){
    event.preventDefault();
    if($(".jstree-clicked").length == 0) {
      alert("Selezionare un livello");
    } else {
      var params = {};
      var get = new Array();
      var fond = $(".jstree-clicked").parent().attr("id").split("-").pop();
      var dest = $(location).attr('pathname').replace(/[0-9]+/g, fond);
      var variables = $(location).attr('search').split('?')[1].split('&');

      $.each(variables, function(key, elem) {
        var tmp = elem.split("=");
        if(tmp[0] == 'mode' || tmp[0] == 'order') {
          params[tmp[0]] = tmp[1];
        }
      });

      if ($("#include-subtree").is(":checked")) {
        params.subtree = 1;
      } else {
        params.subtree = 0;
      }

      $.each(params, function(key, elem) {
        get.push(key + "=" + elem);
      });
      $(window.location).attr('href', dest + '?' + get.join('&'));
    }
  });


});