/* FILE: utils.js */

$(document).ready(function(){

  $.archigrid.utils = {

    available_height : function(){
      var viewport_height     = $(window).height();
      var gridbox_top_offset  = $("#gbox_jqgrid").offset().top;
      // bottom-bar + filter toolbar together take about 100 pixels
      return viewport_height - gridbox_top_offset - 80;
    },

    content_width : function(){
      return $("#gbox_jqgrid").parent().width();
    },

    grid_viewport : function(){
      return $.archigrid.commons.jqgrid_table.closest(".ui-jqgrid-bdiv");
    },

    scrolling_container : function(){
      return this.grid_viewport().children("div:first");
    },

    current_cell : function(){ // used in keyboard_nav.js
      return $.archigrid.commons.jqgrid_table.find("td.edit-cell");
    // TODO: alternative, verify .edit-cell
    // return $.archigrid.commons.jqgrid_table.find("td.ui-state-highlight:first");
    },

    current_row : function(){
      return this.current_cell().closest("tr.jqgrow");
    },

    next_cell : function(){ // used in keyboard_nav.js e chiamato da archigrid.js
      return this.current_cell().next();
    },

    next_row : function(){ // used in keyboard_nav.js
      return this.current_row().next("tr.jqgrow");
    },

    preceding_row : function(){ // used in keyboard_nav.js
      return this.current_row().prev("tr.jqgrow");
    },

    first_cell_in_next_row : function(){ // used in keyboard_nav.js
      return this.next_row().find("td.first-column");
    },

    last_cell_in_preceding_row : function(){
      return this.preceding_row().find("td:visible:last")
    },

    is_any_dialog_open : function(){
      return $('body').hasClass('modal-open');
    },

    all_dialogs_close : function(){ // used in keyboard_nav.js
      return !this.is_any_dialog_open();
    },

    is_being_edited : function(){
      return this.current_cell().find("input[disabled!='disabled'], select[disabled!='disabled'], textarea[disabled!='disabled']").length > 0;
    },

    is_not_being_edited : function(){ // used in keyboard_nav.js
      return !this.is_being_edited();
    },

    get_cell_by_id_and_index : function(rowid, iCol){ // used in keyboard_nav.js
      return $.archigrid.commons.jqgrid_table
      .find("tr#"+rowid+" td[role='gridcell']")
      .slice(iCol,iCol+1);
    }

  };

});

