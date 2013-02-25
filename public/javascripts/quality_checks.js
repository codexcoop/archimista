$(document).ready(function () {

  $("#quality_checks-fond-autocomplete").archimate_autocomplete_setup();

  $("[id$='-name-autocomplete']").keypress(function (event) {
    if (event.keyCode === 13) {
      event.preventDefault();
    }
  });

  $("#quality_checks-fond-name-autocomplete").autocomplete('option', 'select', function (event, ui) {
    $("#quality_checks-fond-name-autocomplete").attr("value", ui.item.value);
    $("#quality_checks-fond-id-autocomplete").attr("value", ui.item.id);
    $("#quality_checks-fond-choice").submit();
    return false;
  });

  $("#quality_checks-creator-autocomplete").archimate_autocomplete_setup();

  $("#quality_checks-creator-name-autocomplete").autocomplete('option', 'select', function (event, ui) {
    $("#quality_checks-creator-name-autocomplete").attr("value", ui.item.value);
    $("#quality_checks-creator-id-autocomplete").attr("value", ui.item.id);
    $("#quality_checks-creator-choice").submit();
    return false;
  });

  $("#quality_checks-custodian-autocomplete").archimate_autocomplete_setup();

  $("#quality_checks-custodian-name-autocomplete").autocomplete('option', 'select', function (event, ui) {
    $("#quality_checks-custodianr-name-autocomplete").attr("value", ui.item.value);
    $("#quality_checks-custodian-id-autocomplete").attr("value", ui.item.id);
    $("#quality_checks-custodian-choice").submit();
    return false;
  });

});