$(document).ready(function(){

  $("#exports-fond-autocomplete").archimate_autocomplete_setup();

  $("#exports-fond-name-autocomplete").autocomplete('option', 'select', function(event, ui){
    $("#exports-fond-name-autocomplete").attr("value",ui.item.value);
    $("#exports-fond-id-autocomplete").attr("value",ui.item.id);
    $("#exports-fond-choice").submit();
    return false;
  });

  $("#import-wait").submit(function() {
    $.blockUI({
      message:  'Importazione in corso...'
    });
  });

  $(".export-wait").submit(function(event) {
    event.preventDefault();
    $.blockUI({
      message:  'Esportazione in corso...'
    });
    $.ajax({
      url: '/exports.json',
      data: {
        f: $("#exports-fond-id-autocomplete").val()
      },
      dataType: 'json',
      success:function(data) {
        $.unblockUI();
        tokens = data["export"]["dest_file"].split('/');
        file = tokens[tokens.length - 1];
        $(window.location).attr('href', "/exports/download?file="+file);
      }
    });
    return false;
  });

  $(".export-aef-wait").click(function(event) {
    event.preventDefault();
    $.blockUI({
      message:  'Esportazione in corso...'
    });
    $.ajax({
      url: '/exports.json',
      data: {
        f: $(this).attr('fond-id')
      },
      dataType: 'json',
      success:function(data) {
        $.unblockUI();
        tokens = data["export"]["dest_file"].split('/');
        file = tokens[tokens.length - 1];

        tokens = data["export"]["data_file"].split('/');
        data_file = tokens[tokens.length - 1];

        tokens = data["export"]["metadata_file"].split('/');
        metadata_file = tokens[tokens.length - 1];

        $(window.location).attr('href', "/exports/download?file="+file+"&data="+data_file+"&meta="+metadata_file);
      }
    });
    return false;
  });

  $(".delete-import").click(function() {
    $("#confirm-delete-btn").attr("data-import-id", $(this).attr("data-import-id"));
    $("#confirm-delete-import").modal("show");
    return false;
  });

  $("#confirm-delete-btn").click(function(){
    var id = $(this).attr("data-import-id");
    $('#confirm-delete-import').modal("hide");

    $.blockUI({
      message: 'Eliminazione in corso...'
    });

    $.ajax({
      type: "DELETE",
      url: '/imports/' + id,
      success: function(data){
        $.unblockUI();
        if (data.status === "success") {
          location.reload();
        } else {
          $("div.container").prepend('<div class="alert alert-error"><a class="close" data-dismiss="alert">×</a>' + data.msg + '.</div>');
        }
      }
    })

  });

});


