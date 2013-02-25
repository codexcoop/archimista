/* FILE: archigrid.js */

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
    if ($form.get(0).tagName !== 'FORM') {
      return {};
  }

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

  // Make sure that debugging footnotes don't alter the structure of the page
  $("div#footnotes_debug").remove();

  $.archigrid.setup .set_selected_attribute_names() // before any other setup!, saves the attributes' list in the config object
  .select_columns_dialog()
  .edit_text_command()
  .autoresize();

  $.archigrid.events
  .standalone_edit_on_keypress()
  .standalone_edit_on_doubleclick()
  .standalone_edit_with_link();

  $.archigrid.keyboard_nav.next_cell_on_tab();
  $.archigrid.keyboard_nav.trigger_jqgrid_arrows();
  $.archigrid.boot();

});

