$(document).ready(function() {

  uncheckAll();

  $("#sortable").sortable({
    cursor: 'move',
    placeholder : 'sortable-placeholder',
    forcePlaceholderSize : true,
    opacity : 0.7,
    update : function () {
      var order = $('#sortable').sortable('serialize');
      var action = "/digital_objects/sort";
      $.get(action+"?"+order, function(data) {});
    }
  });

  $('[id^=digital_object_ids_]').change(function() {
    toggleBulkDestroy();
  });

  $(document).on("click", "#bulk-destroy", function (){
    if ($(this).prop('disabled') === false) {
      var params = decodeURIComponent($('input:checkbox:checked').serialize());
      var action = "/digital_objects/bulk_destroy";
      $.get(action+"?"+params, function(data) {
        window.location.reload();
      });
    }
  });

  if (!checkBoxes()) {
    $("#toggle-all").prop('disabled', true).addClass('disabled');
  }

  $(document).on('change', "#toggle-all", function() {
    var CheckBoxes = $("input[name=digital_object_ids\\[\\]]");
    CheckBoxes.prop("checked", !CheckBoxes.prop("checked"));
    toggleBulkDestroy();
  });

  function toggleBulkDestroy() {
    var checkBoxChecked = $('input:checkbox:checked');
    if (checkBoxChecked.length) {
      $("#bulk-destroy").prop('disabled', false).removeClass('disabled').addClass('btn-danger');
      $("#bulk-destroy i").addClass('icon-white');
    }
    else {
      $("#bulk-destroy").prop('disabled', true).addClass('disabled').removeClass('btn-danger');
      $("#bulk-destroy i").removeClass('icon-white');
    }
  }

  function uncheckAll() {
    $('input:checkbox:checked').prop('checked', false);
  }

  function checkBoxes() {
    var test = $("input[name=digital_object_ids\\[\\]]").length ? true : false;
    return test;
  }

});

