$(document).ready(function () {

  // tree instance
  $(".tree-item").each(function(){
    $(this).jstree({
      core : { strings : { loading : "Caricamento ..." } },
      plugins : ["themes", "json_data"],
      themes : { theme : "apple", dots : false, icons : true },
      json_data : {
        ajax : {
          dataType : "json",
          url : $(this).data("tree-path") // as a relative path, all url will be appended to current url
        }
      }
    });
  });

  // empty trash
  $(document).ajaxStop($.unblockUI);

  // FIXME: dismettere dialog JqueryUI
  $("#confirm-empty-trash").dialog({
    width: 400,
    buttons: {
      "Annulla": function() {
        disabled: true,
        $(this).dialog("close");
      },
      "Vuota il Cestino": function() {
        disabled: true,
        $(this).dialog("close");
        $.blockUI({ message: 'Eliminazione in corso...' });
        $.ajax({
          type: "DELETE",
          url: '/fonds/' + $(this).attr("data-fond-id") + '/destroy_subtree',
          success: function(){
            location.reload();
          }
        });
      }
    }
  });

  $("#empty-trash").click(function() {
    $("#confirm-empty-trash").dialog("open");
    return false;
  });

});

