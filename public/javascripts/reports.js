$(document).ready(function(){

  $("#reports-fond-autocomplete").archimate_autocomplete_setup();

  $("[id$='-name-autocomplete']").keypress(function(event) {
    if (event.keyCode == 13) {
      event.preventDefault();
    }
  });

  $("#reports-fond-name-autocomplete").autocomplete('option', 'select', function(event, ui){
    $("#reports-fond-name-autocomplete").attr("value",ui.item.value);
    $("#reports-fond-id-autocomplete").attr("value",ui.item.id);
    $("#reports-fond-choice").submit();
    return false;
  });

  $(".rtf").click(function(event) {
    event.preventDefault();
    $.blockUI({
      message:  'Generazione documento in corso'
    });
    $.ajax({
      url: $(this).attr('href'),
      data: {},
      dataType: "text",
      success:function() {
        $.unblockUI();
        $(window.location).attr('href', "/downloads/inventory.rtf");
      }
    });
    return false;
  });

});