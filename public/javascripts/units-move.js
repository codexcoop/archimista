$(document).ready(function(){

  $(document).delegate(".move", 'click', function(){
    id = $(this).attr('data-id');
    $.get('/units/'+ id +'/move').success(function(data){
      $('#move-container').html(data);
      $('#move-container #move-unit-modal').modal("show");
    });
  });

  $(document).delegate("#units-list input[@name='new_parent_id']", 'click', function(){
    $("#confirm-move").prop('disabled', false).removeClass('disabled');
  });

  $(document).delegate("#confirm-move", 'click', function (){
    if ($(this).hasClass("disabled")) {
      return false;
    } else {
      if ($(this).hasClass("down")) {
        $(this).removeClass('down');
        $("#move-down-form").trigger('submit');
      }
      if ($(this).hasClass("up")) {
        $(this).removeClass('up');
        $("#move-up-form").trigger('submit');
      }
    }
  });
});


