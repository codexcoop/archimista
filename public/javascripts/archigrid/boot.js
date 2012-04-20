/* FILE: boot.js */

$(document).ready(function(){

  $.archigrid.boot = function(){

// OPTIONS
// Reference: http://www.trirand.com/jqgridwiki/doku.php?id=wiki:options

    $.archigrid.commons.jqgrid_table.jqGrid({

      url: 'grid',
      datatype: 'json',
      postData: {selected_attributes:$.archigrid.config.selected_attribute_names},
      sortname: $.archigrid.commons.jqgrid_table.data('sortname'),
      rowNum: 100,
      rowTotal: $.archigrid.commons.jqgrid_table.data('total-entries'),
      pager: '#jqgrid-pager',
      loadui: 'block',

      gridview: true, // can't be used with treeGrid or subGrid

      // Pager bar in bottom right position
      // See related parameters: 'emptyrecords' and 'recordtext'
      viewrecords: true,

      // NOTE: you must set in the CSS #jqgrid td { white-space: nowrap !important; }
      // or table-layout fixed and td overflow hidden, because page and pagination depend on row height
      scroll: 1,
      scrollrows: true,

      // If the value is false and the value in width option is set
      // then the column width are not recalculated and have the values defined in colModel
      shrinkToFit: false,

      // Columns reordering
      // BUG nostro! si sposta solo il th.
      // Opzione temporaneamente disabilitata. Vedi "New in version 3.6"
      // sortable : true,

      cellEdit : true,
      cellsubmit : 'remote',
      cellurl : location.pathname.replace('/gridview',''),

// EVENTS
// Reference: http://www.trirand.com/jqgridwiki/doku.php?id=wiki:events

      resizeStop : function(newwidth, index){
        var table_width = $.archigrid.commons.jqgrid_table.width();
        $.archigrid.utils.grid_viewport().children("div:first").width(table_width);
      },

      gridComplete : function(){
        // Hide filters by default (but only the first time the grid is loaded)
        if (!$.archigrid.commons.jqgrid_table.data('completed-before')) {
          $.archigrid.commons.jqgrid_table[0].toggleToolbar();
          $.archigrid.commons.jqgrid_table.data('completed-before', true);
        }

        // Go to newly created records, if any
        $.archigrid.setup.auto_go_to_row();

        // create and set the universal checker
        $.archigrid.setup.check_all_button();
      },

// CELL EDITING
// Reference: http://www.trirand.com/jqgridwiki/doku.php?id=wiki:cell_editing

      beforeSubmitCell : function(rowid, cellname, value, iRow, iCol){
        return $.archigrid.editing.set_cell_params_before_submit(rowid, cellname, value, iRow, iCol);
      }, // return needed

      // NOTE: if you want to intercept events on the input elements, this seems to be
      // the only place where you can do that
      afterEditCell : function(rowid, cellname, value, iRow, iCol){
        $.archigrid.keyboard_nav.take_over_tab_navigation(rowid, iRow, iCol);
      }, 

      // colNames moved to colModel => label property, easier to manage
      colNames : [ ],

      // NOTE: non standard attributes will be inserted as conventional html attributes
      // for example: "data-your-property" => 'your value' will be accessible
      // through the jQuery method $("<selector>").data('your-property')
      // WARNING: if you change the columns' order, it must be changed server-side as well
      colModel: $.archigrid.config.col_model()
    }); // $.archigrid.commons.jqgrid_table.jqGrid({})

    $.archigrid.commons.jqgrid_table.jqGrid('filterToolbar');
    $.archigrid.commons.jqgrid_table.jqGrid('setGridHeight', $.archigrid.utils.available_height());
    $.archigrid.commons.jqgrid_table.jqGrid('setGridWidth', $.archigrid.utils.content_width());

    return this;
  }; // $.archigrid.boot()

});

