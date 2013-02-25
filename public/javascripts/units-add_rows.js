/* FILE: units-add_rows.js */

// OPTIMIZE: fix errori JSHint
$(document).ready(function(){

  $("#mass-add-modal").on('hide', function () {
    $(".inline-msg").hide();
  });

  // Valida la form e triggera il submit
  $("#confirm-mass-add").click(function(){
    var add_rows_form  = $("#add-rows-form");
    var params         = add_rows_form.get_params_object();
    var errors         = {};
    var valid_range    = (parseInt(params['number_of_rows'], 10) >= 1 && parseInt(params['number_of_rows'], 10) <= 100);

    $(".inline-msg").hide();

    // Nota: tolleriamo 0 in prima posizione
    if (params['number_of_rows'].replace(/\s/g, "").match(/^\d+$/) === null) {
      $("#number-of-rows-msg").show();
      errors['a'] = "a";
    }
    if (valid_range === false) {
      $("#number-of-rows-msg").show();
      errors['b'] = "b";
    }
    if (params['unit[title]'].replace(/\s/g, "").length === 0) {
      $("#unit-title-msg").show();
      errors['c'] = "c";
    }
    if (params['unit[unit_type]'].length === 0) {
      $("#unit-type-msg").show();
      errors['d'] = "d";
    }
    if (params['unit[tmp_reference_number]'].replace(/^\s+|\s+$/g, "").match(/^\d*$/) === null) {
      $("#tmp-reference-number-msg").show();
      errors['e'] = "e";
    }

    if ($.isEmptyObject(errors)) {
      $(this).clone().insertAfter($(this)).prop("disabled", true).addClass("disabled");
      $(this).hide();
      add_rows_form.trigger('submit');
    }
  });

});

