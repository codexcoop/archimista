// Creators: hide/show fields by creator type

$(document).ready(function() {

  var creator_type = $('#creator_creator_type').val();

  switch (creator_type) {
    case "C":
      $('.hide').show();
      $('#institutions-selection').show();
      $('#preferred_name_p').hide();
      $('#preferred_name_cf').show();
      $('#creator_residence').show();
      break;
    case "F":
      $('.hide').hide();
      $('#institutions-selection').hide();
      $('#preferred_name_p').hide();
      $('#preferred_name_cf').show();
      $('#creator_residence').hide();
      break;
    case "P":
      $('#institutions-selection').hide();
      $('.hide').hide();
      $('#preferred_name_p').show();
      $('#preferred_name_cf').hide();
      $('#creator_residence').hide();
      break;
    default:
      $('.hide').hide();
      $('#institutions-selection').hide();
      $('#preferred_name_p').hide();
      $('#preferred_name_cf').show();
      $('#creator_residence').show();
  }

  $('#creator_creator_type').change(function() {
    switch ($('#creator_creator_type').val()) {
      case "C":
        $(".archidate-place").hide();
        $('.hide').show();
        $('#institutions-selection').show();
        $('#preferred_name_p').hide();
        $('#preferred_name_cf').show();
        $('#creator_residence').show();
        break;
      case "F":
        $(".archidate-place").hide();
        $('.hide').hide();
        $('#institutions-selection').hide();
        $('#preferred_name_p').hide();
        $('#preferred_name_cf').show();
        $('#creator_residence').hide();
        break;
      case "P":
        $(".archidate-place").show();
        $('.hide').hide();
        $('#institutions-selection').hide();
        $('#preferred_name_p').show();
        $('#preferred_name_cf').hide();
        $('#creator_residence').hide();
        break;
      default:
        $(".archidate-place").hide();
        $('.hide').hide();
        $('#institutions-selection').hide();
        $('#preferred_name_p').hide();
        $('#preferred_name_cf').show();
        $('#creator_residence').show();
    }
  });
});