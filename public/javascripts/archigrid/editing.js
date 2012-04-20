/* FILE: editing.js */

$(document).ready(function(){
  $.archigrid.editing = {
    // Editing della cella viene gestito diversamente dalla riga (vedi boot)
    set_cell_params_before_submit : function(rowid, cellname, value, iRow, iCol){
      // Necessario rendere navigabile con TAB l'ultima colonna editable nativa di jqGrid anche dopo il salvataggio
      var $cell = $.archigrid.commons.jqgrid_table.find("tr#"+rowid+" td[role='gridcell']").slice(iCol,iCol+1);
      $cell.attr("tabindex", "-1");
      // La url deve essere impostata per ogni singola cella (diversamente che per il row editing)
      $.archigrid.commons.jqgrid_table.jqGrid('setGridParam', {
        cellurl : '/units/'+rowid+'/ajax_update'
      });
      return {
        '_method':'PUT'
      };
    },

    /* EVENTS */
    preferred_event_form : function($cell) {
      // Gather dom objects and params to set the form
      var $row              = $cell.parents("tr:first");
      var record_id         = $row.attr('id');
      $.get("/units/"+ record_id +"/preferred_event").success(function(data){
        $.archigrid.commons.jqgrid_table.unblock();
        $('#preferred-event-dialog-container').html(data);
        $('#preferred-event-dialog').modal("show");
      });
    },

    process_preferred_event_form : function(){
      var $form = $('#preferred-event-dialog-container').find("form").first();
      var params = $form.get_params_object();
      $.post($form.attr('action'), params).success(function(response, textStatus, jqXHR){
        var final_status = jQuery.parseJSON(jqXHR.responseText);
        if (final_status.status === 'success') {
          $.archigrid.commons.jqgrid_table.data('calling-cell').html(response.full_display_date).attr('title', response.full_display_date);
          $("#preferred-event-dialog").modal("hide");
        } else {
          $("#event-error-messages").replaceWith("<div class=\"alert alert-error\">Data non valida</div>");
        }
        return false;
      });
    },

    /* TEXT FIELDS */
    text_field_form : function($cell){
      var $row              = $cell.parents("tr:first");
      var record_id         = $row.attr('id');
      var cell_index        = $row.find("td[role='gridcell']").index($cell);
      var column_model      = $.archigrid.commons.jqgrid_table.jqGrid('getGridParam','colModel');
      var column_properties = column_model[cell_index];
      var field =  column_properties['name'];

      $.get("/units/"+ record_id +"/textfield_form",{
        field: field
      },function(data){
        $('#textfield-dialog-container').html(data);
        $('#text-field-dialog').modal("show");
      });
    },

    process_text_field_form : function($cell){
      var $form = $('#textfield-dialog-container').find("form");
      var params = $form.get_params_object();
      params['_method']='PUT';
      $.ajax({
        url:$form.attr('action'),
        type:'POST',
        data:params,
        success:function(){
          var new_value = $form.find("#text-field-name").val();
          var truncated_value = new_value.substring(0,100).replace(/\s/g,' ');
          $.archigrid.commons.jqgrid_table.data('calling-cell').html(truncated_value).attr('title', truncated_value);
        }
      });
      $('#text-field-dialog').modal("hide");
      $('#textfield-dialog-container').html('');
    },

    /* SELECT COLUMNS */
    process_select_columns_form : function(){
      var $form = $.archigrid.commons.select_columns_dialog.find("form").first();
      var params = $form.serializeArray();
      var selected_attribute_names = [];
      $.each(params, function(index, input_field){
        if (input_field.name === 'selected_attributes[]') {
          selected_attribute_names.push(input_field.value);
        }
      });
      // First call this...
      $.archigrid.commons.jqgrid_table.data('selected-attributes', selected_attribute_names);
      // ...and then this, so that the list of attributes is correctly saved
      // in the $.archigrid.config.selected_attribute_names object
      $.archigrid.setup.set_selected_attribute_names();
      $form.trigger('submit');
    }
  };
});
