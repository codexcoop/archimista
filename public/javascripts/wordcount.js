$(document).ready(function(){
  $('.wordcount').each(function(){
    // We need to generalize

    var datacount = $(this).attr('data-count');
    var dcarray = datacount.split('-');
    var counterclass = dcarray[0];
    var maxlimit = dcarray[1];

    var length = $(this).val().length;
    if(length >= maxlimit) {
      $(this).val($(this).val().substring(0, maxlimit));
      length = maxlimit;
    }
    // update count on page load
    $('#counter-'+counterclass).html( (maxlimit - length) + ' characters left');
    // bind on key up event
    $(this).keyup(function(){
    // get new length of characters
    var new_length = $(this).val().length;

    if(new_length >= maxlimit) {
      $(this).val($(this).val().substring(0, maxlimit));
      // update the new length
      new_length = maxlimit;
    }
    // update count
    $('#counter-'+counterclass).html( (maxlimit - new_length) + ' characters left');
    });
	});
});