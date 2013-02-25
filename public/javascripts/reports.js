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

  $(".rtf-inventory").click(function (event) {
    event.preventDefault();
    $.blockUI({
      message: 'Generazione documento in corso'
    });
    $.ajax({
      url: $(this).attr('href'),
      data: {},
      dataType: "text",
      success: function () {
        $.unblockUI();
        $(window.location).attr('href', "/downloads/inventory.rtf");
      }
    });
    return false;
  });

  $(".rtf-project").click(function (event) {
    event.preventDefault();
    $.blockUI({
      message: 'Generazione documento in corso'
    });
    $.ajax({
      url: $(this).attr('href'),
      data: {},
      dataType: "text",
      success: function () {
        $.unblockUI();
        $(window.location).attr('href', "/downloads/project.rtf");
      }
    });
    return false;
  });

  $(".rtf-custodian").click(function (event) {
    event.preventDefault();
    $.blockUI({
      message: 'Generazione documento in corso'
    });
    $.ajax({
      url: $(this).attr('href'),
      data: {},
      dataType: "text",
      success: function () {
        $.unblockUI();
        $(window.location).attr('href', "/downloads/custodian.rtf");
      }
    });
    return false;
  });

});