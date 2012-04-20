/* FILE: units-remove_rows.js */

$(document).ready(function(){

  var RemoveRows =  {
    // Trova gli ids selezionati
    $form : $("#remove-rows-dialog form:first"),
    $fields_wrapper : $("#remove-rows-dialog form:first .fields-wrapper"),
    $selected_checkboxes : function () {
      return $("input:checkbox.selected-record-id").filter(":checked");
    },

    // Triggera il submit della form
    remove_rows : function(){
         var self = this;
         self.$form.trigger('submit');
    },
    // Popola la form con hidden inputs necessari per l'azione di delete
    open_delete_records_dialog : function(){
      var self = this;
      var record_ids = self.$selected_checkboxes().map(function(index, checkbox){
        return $(checkbox).val();
      });

      self.$fields_wrapper.empty();
      $.each(record_ids, function(index, id){
        $("<input>", {type:'hidden', name:'record_ids[]', value:id}).appendTo(self.$fields_wrapper);
      });
    }
  };

  $("#mass-remove").click(function () {
    RemoveRows.open_delete_records_dialog();
  });

  $("#confirm-mass-remove").click(function() {
    RemoveRows.remove_rows();
  });

});