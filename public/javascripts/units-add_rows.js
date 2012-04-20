/* FILE: units-add_rows.js */

$(document).ready(function(){

 // Valida la form e triggera il submit
 $("#confirm-mass-add").click(function(){
    var add_rows_form    = $("#add-rows-form");
    var params            = add_rows_form.get_params_object();
    var errors            = {};
    var range_conditions  = params['number_of_rows'].match(/[^\d]/) === null && (parseInt(params['number_of_rows'], 10) > 100 || parseInt(params['number_of_rows'], 10) < 1 );

    if (params['number_of_rows'].match(/[^\d]/)) {
       $("#number-of-rows-msg").show();
       errors['number_of_rows_none'] = "a";
    }

    if (range_conditions) {
       $("#number-of-rows-msg").show();
       errors['number_of_rows_none'] = "b";
     }
     if (params['number_of_rows'].length === 0) {
       $("#number-of-rows-msg").show();
       errors['number_of_rows_blank'] = "c";
     }
     if (params['unit[title]'].length === 0) {
       $("#unit-title-msg").show();
       errors['unit_title_blank'] = "d";
     }
     if (params['unit[unit_type]'].length === 0) {
       $("#unit-type-msg").show();
       errors['unit_type_blank'] = "e";
     }

     if ($.isEmptyObject(errors)) {
       $(this).clone().insertAfter($(this)).prop("disabled", true).addClass("disabled");
       $(this).hide();
       add_rows_form.trigger('submit');
     }
  });

});

