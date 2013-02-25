/* FILE: units.js */

// DA RIFARE TOTALMENTE! VEDI ANCHE ARCHIGRID.JS
// Microplugin to extract values from a form, as an object suitable to be analyzed,
// and to be sent via ajax
// WARNING ON CURRENT VERSION: it works only when there are no repeated names in the fields
// for example, if more checkboxes have the name "collection_of_values[]", whose values
// are treated as an array server-side, the current version of this method will
// return only the value of the last checkbox
(function($){
  $.fn.get_params_object = function() {
    // consider only the first form in the wrapped set
    var $form = this.first();
    // return an empty object if the element is not a form
    if ($form.get(0).tagName !== 'FORM') {return {};}

    // raw params, as array of objects:
    // [ {name:'name[of][field]', value:"whatever"}, {name:'name[of][anotherfield]', value:"something else"} ]
    var params      = $form.serializeArray();
    // build a single object with name of the fields as keys, and values of the fields as values
    var pseudo_json = {};
    var i = 0;
    for (i in params) {
      pseudo_json[params[i].name] = params[i].value;
    }
    return pseudo_json;
  };
})(jQuery);

$(document).ready(function(){
  // Fix per presunto bug di Bootstrap / button.
  // Problema: al click su icona contenuta in button.disabled si innesca ugualmente l'azione del button.
   $("#mass-remove i, #mass-classify i, #mass-reorder i").click(function(event) {
     if ($(this).parent().hasClass("disabled")) {
       event.stopPropagation;
       return false;
     }
   });

   // Checkrecords

   $("input:checkbox#select-all-records").live("click", function() {
     var $checkboxes = $("input:checkbox.selected-record-id");
     $checkboxes.prop('checked', $(this).prop('checked'));
     toggle_buttons($checkboxes);
   });

   $("input:checkbox.selected-record-id").live("click", function() {
     var $checkboxes = $("input:checkbox.selected-record-id");
     if ($(this).prop("checked") == false || !$checkboxes.is(":checked")) {
       $("input:checkbox#select-all-records").prop("checked", false);
     }
     toggle_buttons($checkboxes);
   });

   function toggle_buttons($checkboxes) {
     if ( $checkboxes.filter(":checked").length > 0 ) {
       $("#mass-classify").removeClass("disabled").prop("disabled", false);
       $("#mass-remove").removeClass("disabled").prop("disabled", false);
     } else {
       $("#mass-classify").addClass("disabled").prop("disabled", true);
       $("#mass-remove").addClass("disabled").prop("disabled", true);
     }
   }
});