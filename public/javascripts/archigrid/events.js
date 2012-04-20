/* FILE: events.js */

$(document).ready(function(){

  $.archigrid.events = {

    dispatch_standalone_edit : function($command_element){
      // Gather dom objects and params to set the form
      var $cell;

      if ($command_element.get(0).tagName === 'TD'){
        $cell = $command_element;
      } else {
        $cell = $command_element.parents("td:first");
      }
      $.archigrid.commons.jqgrid_table.data('calling-cell', $cell);

      if ($cell.hasClass('standalone-text')) {
        $.archigrid.editing.text_field_form($cell);
      } else if ($cell.hasClass('standalone-date')) {
        $.archigrid.editing.preferred_event_form($cell);
      }
    },

    // TODO: dry standalone_edits and open the proper form when user clicks on the edit command of a text cell
    standalone_edit_with_link : function(){
      var self = this;
      $.archigrid.commons.jqgrid_table.delegate("#standalone-edit-command", "click", function(event){
        self.dispatch_standalone_edit($(this).first());
        event.preventDefault();
        event.stopPropagation();
      });
      return this;

    },

    // Prepare and open the proper form when user double-clicks on a text cell
    standalone_edit_on_doubleclick : function(){
      var self = this;
      $.archigrid.commons.jqgrid_table.delegate("td.standalone-editable", "dblclick", function(event){
        self.dispatch_standalone_edit($(this).first());
        event.preventDefault();
        event.stopPropagation();
      });
      return this;
    },

    // Prepare and open the proper form when user hits enter on a text cell
    // WARNING: it is a keyup, actually, not a keypress, because chrome doesn't
    // fire the event on special keys with jQuery#keypress, but the function has
    // keypress in its name, because seems more intuitive
    standalone_edit_on_keypress : function(){
      var self = this;
      /*$(document).keyup(function(event){
        var $cell = $.archigrid.commons.jqgrid_table.find("td.standalone-editable.ui-state-highlight");
        // Store the currently selected cell to be reactivated when action has ended
        $.archigrid.commons.jqgrid_table.data('custom_selected_cell', $cell);
        if ($cell.length > 0 && event.keyCode === 32) {
          event.preventDefault();
          event.stopPropagation();
          self.dispatch_standalone_edit($cell);
        }
      });*/
      return this;
    }
  };
});

