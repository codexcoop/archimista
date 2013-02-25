/* FILE: config.js */

$(document).ready(function(){

  $.archigrid.config = {};

  // json embedded data, set server-side in the view, already translated in the current session locale
  $.archigrid.config.vocabularies = $.archigrid.commons.jqgrid_table.data('vocabularies');

  // json embedded data, set server-side in the view, already translated in the current session locale
  $.archigrid.config.column_labels = $.archigrid.commons.jqgrid_table.data('column-labels');

  // Columns must be completed with additional required properties (index and label),
  // see below, function complete_columns()
  $.archigrid.config.columns = {
    'id' : {
      name:'id',
      width:25,
      fixed:true,
      resizable:false,
      //hidden:true,
      search:false,
      //hidedlg:true,
      formatter : $.archigrid.formatters.destroy_record,
      align:'center',
      classes:"destroy-cell",
      sortable:false,
      label:'&nbsp;'
    },

    'sequence_number' : {
      name:'unit[sequence_number]',
      width:80,
      align:"right",
      fixed:true,
      // required for keyboard navigation, now dynamically added by $.archigrid.config.col_model()
      search:false, // provvisorio. La ricerca riceve sequence_number come input, ma mostra display_sequence_number...
      classes:"",
      resizable:false
    },

    'fond_name' : {
      name:'unit[fond_name]',
      resizable:true,
      width:220,
      label:'Classificazione',
      classes:""
    },

    // 'ancestry_depth' : {
    //  name:'unit[ancestry_depth]',
    //  width:40,
    //  align:"center",
    //  fixed:true,
    //  search:false,
    //  formatter: $.archigrid.formatters.level_string
    // stype:'select',
    // searchoptions:{value:$.archigrid.config.vocabularies['units.ancestry_depth']},
    // classes:""
    // },

    'tmp_reference_number' : {
      name:'unit[tmp_reference_number]',
      width:160,
      editable:true,
      classes:"editable-jqgrid-native",
      resizable:true,
      edittype:'text'
    },

    'tmp_reference_string' : {
      name:'unit[tmp_reference_string]',
      width:160,
      editable:true,
      classes:"editable-jqgrid-native",
      resizable:true,
      edittype:'text'
    },

    'folder_number' : {
      name:'unit[folder_number]',
      width:160,
      editable:true,
      classes:"editable-jqgrid-native",
      resizable:true,
      edittype:'text'
    },

    'file_number' : {
      name:'unit[file_number]',
      width:160,
      editable:true,
      classes:"editable-jqgrid-native",
      resizable:true,
      edittype:'text'
    },

    'reference_number' : {
      name:'unit[reference_number]',
      width:160,
      editable:true,
      classes:"editable-jqgrid-native",
      resizable:true,
      edittype:'text'
    },

    'title' : {
      name:'unit[title]',
      width:460,
      editable:true,
      classes:"editable-jqgrid-native",
      editrules:{required:true}
    },

    'given_title' : {
      name:'unit[given_title]',
      width:80,
      fixed:true,
      resizable:false,
      editable:true,
      classes:"editable-jqgrid-native",
      edittype:'checkbox',
      editoptions:{value:"1:0"},
      stype:'select',
      searchoptions:{value:{"":"","true":"Sì","false":"No"}},
      formatter:'checkbox',
      align:"center"
    },

    'content' : {
      name:'unit[content]',
      width:340,
      classes:'standalone-editable standalone-text'
    },

    'preferred_event' : {
      name:'unit[preferred_event]',
      width:220,
      fixed:true,
      classes:"standalone-editable standalone-date",
      search:false
    },

    'unit_type': {
      name:'unit[unit_type]',
      width:220,
      fixed:true,
      editable:true,
      classes:"editable-jqgrid-native",
      edittype:'select',
      formatter:'select',
      stype:'select',
      editoptions:{value:$.archigrid.config.vocabularies['units.unit_type']}
    },

    'medium' : {
      name:'unit[medium]',
      width:120,
      fixed:true,
      classes:"editable-jqgrid-native",
      editable:true,
      edittype:'select',
      formatter:'select',
      stype:'select',
      editoptions:{value:$.archigrid.config.vocabularies['units.medium']}
    },

    'physical_type' : {
      name:'unit[physical_type]',
      width:120,
      fixed:true,
      editable:true,
      classes:"editable-jqgrid-native",
      edittype:'select',
      formatter:'select',
      stype:'select',
      editoptions:{value:$.archigrid.config.vocabularies['units.physical_type']}
    },

    'physical_container_type' : {
      name:'unit[physical_container_type]',
      width:180,
      fixed:true,
      editable:true,
      classes:"editable-jqgrid-native"
    },

    'physical_container_title' : {
      name:'unit[physical_container_title]',
      width:220,
      fixed:true,
      editable:true,
      classes:"editable-jqgrid-native"
    },

    'physical_container_number' : {
      name:'unit[physical_container_number]',
      width:180,
      fixed:true,
      editable:true,
      classes:"editable-jqgrid-native"
    },

    'preservation' : {
      name:'unit[preservation]',
      width:180,
      fixed:true,
      editable:true,
      classes:"editable-jqgrid-native",
      edittype:'select',
      formatter:'select',
      stype:'select',
      editoptions:{value:$.archigrid.config.vocabularies['units.preservation']}
    },

    'preservation_note' : {
      name:'unit[preservation_note]',
      width:280,
      classes:'standalone-editable standalone-text'
    },

    'access_condition' : {
      name:'unit[access_condition]',
      width:220,
      fixed:true,
      editable:true,
      classes:"editable-jqgrid-native",
      edittype:'select',
      formatter:'select',
      stype:'select',
      editoptions:{value:$.archigrid.config.vocabularies['units.access_condition']}
    },

    'access_condition_note' : {
      name:'unit[access_condition_note]',
      width:280,
      classes:'standalone-editable standalone-text'
    },

    'use_condition' : {
      name:'unit[use_condition]',
      width:220,
      fixed:true,
      editable:true,
      classes:"editable-jqgrid-native",
      edittype:'select',
      formatter:'select',
      stype:'select',
      editoptions:{value:$.archigrid.config.vocabularies['units.use_condition']}
    },

    'use_condition_note' : {
      name:'unit[use_condition_note]',
      width:280,
      classes:'standalone-editable standalone-text'
    },

    'physical_description': {
      name:'unit[physical_description]',
      width:280,
      classes:'standalone-editable standalone-text'
    },

    'related_materials' : {
      name:'unit[related_materials]',
      width:280,
      classes:'standalone-editable standalone-text'
    },

    'arrangement_note': {
      name:'unit[arrangement_note]',
      width:280,
      classes:'standalone-editable standalone-text'
    },

    'restoration' : {
      name:'unit[restoration]',
      width:280,
      classes:'standalone-editable standalone-text'
    },

    'note' : {
      name:'unit[note]',
      width:280,
      classes:'standalone-editable standalone-text'
    }

  }; // columns

  // Set additional required properties in columns config objects
  // index (used for filtering and sorting)
  // label (use for the table headings)
  var complete_columns = function(){
    $.each($.archigrid.config.columns, function(attribute_name, column_config){
      if (attribute_name === 'id') { return null; }
      $.archigrid.config.columns[attribute_name]['index'] = attribute_name;
      $.archigrid.config.columns[attribute_name]['label'] = $.archigrid.config.column_labels[attribute_name];
    });
  };
  // Immediately call the function to complete the columns objects
  complete_columns.call();

  $.archigrid.config.available_attributes = function(){
    var available_attributes = [];
    $.each($.archigrid.config.columns, function(attr_name, config_object){
      //if (attr_name === 'id') return
      available_attributes.push({'attr_name':attr_name, 'label':config_object.label});
    });
    return available_attributes;
  };

  $.archigrid.config.available_attribute_names = function(){
    var available_attribute_names = [];
    $.each($.archigrid.config.columns, function(attr_name){
      available_attribute_names.push(attr_name);
    });
    return available_attribute_names;
  };

  // For consistency, should follow the same order as in $.archigrid.config.columns
  $.archigrid.config.default_attribute_names = [
    'id',
    'sequence_number',
    'tmp_reference_string',
    'title',
    'preferred_event',
    'unit_type'
  ];

  $.archigrid.config.col_model = function(){
    // Ensure that id is always the first column
    var col_model = [$.extend({}, $.archigrid.config.columns['id'], {index:'id'})];
    // Add the other selected attributes to the col_model
    $.each($.archigrid.config.selected_attribute_names, function(index, attribute_name){
      var base_column_config  = $.archigrid.config.columns[attribute_name];
      var final_column_config = base_column_config;
      // The first useful column is not at index 0, because the very first is dedicated to multiselect checkboxes
      if (index === 1) {
        final_column_config.classes = final_column_config.classes + " first-column";
      }
      // Id has already been added
      if (attribute_name !== 'id') {
        col_model.push(final_column_config);
      }
    });
    return col_model;
  };

});

