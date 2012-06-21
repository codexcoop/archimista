$(document).ready(function(){

  $("#exports-fond-autocomplete").archimate_autocomplete_setup();

  $("#exports-fond-name-autocomplete").autocomplete('option', 'select', function(event, ui){
    $("#exports-fond-name-autocomplete").attr("value",ui.item.value);
    $("#exports-fond-id-autocomplete").attr("value",ui.item.id);
    $("#exports-fond-choice").submit();
    return false;
  });

  $("#exports-custodian-autocomplete").archimate_autocomplete_setup();

  $("#exports-custodian-name-autocomplete").autocomplete('option', 'select', function(event, ui){
    $("#exports-custodian-name-autocomplete").attr("value",ui.item.value);
    $("#exports-custodian-id-autocomplete").attr("value",ui.item.id);
    alert(ui.item.id)
    $("#exports-custodian-choice").submit();
    return false;
  });

  $("#exports-project-autocomplete").archimate_autocomplete_setup();

  $("#exports-project-name-autocomplete").autocomplete('option', 'select', function(event, ui){
    $("#exports-project-name-autocomplete").attr("value",ui.item.value);
    $("#exports-project-id-autocomplete").attr("value",ui.item.id);
    alert(ui.item.id)
    $("#exports-project-choice").submit();
    return false;
  });

  $("#import-wait").submit(function() {
    $.blockUI({
      message:  'Importazione in corso...'
    });
  });

  $("#exports-fond-choice").submit(function(event) {
    event.preventDefault();
    $.blockUI({
      message:  'Esportazione in corso...'
    });
    $.ajax({
      url: '/exports.json',
      data: {
        target_id: $("#exports-fond-id-autocomplete").val(),
        target_class: 'fond',
        mode: 'full'
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

  $("#exports-custodian-choice").submit(function(event) {
    event.preventDefault();
    $.blockUI({
      message:  'Esportazione in corso...'
    });
    $.ajax({
      url: '/exports.json',
      data: {
        target_id: $("#exports-custodian-id-autocomplete").val(),
        target_class: 'custodian',
        mode: 'full'

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

  $("#exports-project-choice").submit(function(event) {
    event.preventDefault();
    $.blockUI({
      message:  'Esportazione in corso...'
    });
    $.ajax({
      url: '/exports.json',
      data: {
        target_id: $("#exports-project-id-autocomplete").val(),
        target_class: 'project',
        mode: 'full'

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
        target_id: $(this).attr('target-id'),
        target_class: $(this).attr('target-class'),
        mode: $(this).attr('target-mode')
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

  $('#export-tabs a:first').tab('show');

});


