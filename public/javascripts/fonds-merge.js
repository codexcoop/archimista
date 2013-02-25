$(document).ready(function () {

  $(document).delegate(".merge", 'click', function () {
    var id = $(this).attr('data-id');
    $.get('fonds/' + id + '/merge_with').success(function (data) {
      $('#merge-with-container').html(data);
      $('#merge-with-container #merge-fonds-modal').modal("show");
    });
  });

  $(document).delegate("#fonds-list input[@name='new_root_id']", 'click', function () {
    $("#confirm-merge").prop('disabled', false).removeClass('disabled');
  });

  $(document).delegate('.livesearch', 'click', function () {
    $('.livesearch').each(function () {
      if ($(this).hasClass('highlight')) {
        $(this).removeClass('highlight');
      }
    });
    $(this).addClass('highlight');
  });

  $(document).delegate("#confirm-merge", 'click', function () {
    if ($(this).hasClass("disabled")) {
      return false;
    } else {
      $("#merge-fonds-form").trigger('submit');
    }
  });

});