$(document).ready(function() {
  // let tiddlers be closed
  $("div.ditty a[rel='close']").live('click',
    function() {
      $(this).parents('.ditty').slideUp('fast', function() { $(this).remove(); } );
      return false;
    }
  );

  // make get links work
  $("a.existing").live('click',
    function() {
      var tag = this;
      var ditty_name = $(this).attr('title');
      var ditty = $("div.ditty#" + ditty_name);
      if (ditty.size() == 0) {
      $.get(this, function(data, status) {
          $(tag).parents('.ditty').after(data);
          }); 
      };
      return false;
    }
  );

  // make the editing form cancellable
  $("div.ditty_edit ul.edit_links a[rel='cancel']").live('click',
    function() {
      $(this).parents('.ditty_edit').prev().slideDown('fast');
      $(this).parents('.ditty_edit').remove();
      return false;
    }
  );

  // make the new link work.
  $("a[href='/new']").live('click',
    function() {
      var tag = this
      $.get(this, function(data, status) {
        $('#ditties').prepend(data);
      });
      return false;
    }
  );

  // make a new link work.
  $("a.new_ditty").live('click',
    function() {
      var tag = this
      $.get(this, function(data, status) {
        $(tag).parents('.ditty').prepend(data);
      });
      return false;
    }
  );

  // make edit links work
  $('#ditties').delegate("div.ditty a[rel='edit']", 'click', function(event) {
    var tag = $(this);
    $.get(tag, function(data, status) {
      $(tag).parents('.ditty').after(data);
      $(tag).parents('.ditty').hide();
    });
    return false;
  });

  // make delete links work
  $("div.ditty_edit a[rel='destroy']").live('click',
    function() {
      var tag = this;
      $.ajax({
        url: this,
        type: 'POST',
        timeout: 5000,
        data: {_method: 'DELETE' },
        success: function (data, status) {
          // we return the title, so!
          $("#" + data).remove();
          $("#edit_" + data ).remove();
        },
        error: function (xhr, status) {
          alert(xhr.responseText);
        }
      });
      return false;
    }
  );

  // make done links work
  $("div.ditty_edit a[rel='update']").live('click',
    function() {
      var tag = this;
      var form_data = {};
      form_data._method = 'PUT';

      // find the form
      var form = $(tag).parents('.ditty_edit').children('form');
      form_data.title = $(form).children("input[name='ditty_title']").val();
      form_data.body = $(form).children("textarea[name='ditty_body']").val();

      $.ajax({
        url: this,
        type: 'POST',
        timeout: 5000,
        data: form_data,
        success: function (data, status) {
          $(tag).parents('.ditty_edit').prev().replaceWith(data);
          $(tag).parents('.ditty_edit').remove();
        },
        error: function (xhr, status) {
          alert(xhr.responseText);
        }
      });
      return false;
    }
  );

  // make done links work on create forms
  $("div.ditty_edit a[rel='create']").live('click',
    function() {
      var tag = this;
      var form_data = {};

      // find the form
      var form = $(tag).parents('.ditty_edit').children('form');
      form_data.title = $(form).children("input[name='ditty_title']").val();
      form_data.body = $(form).children("textarea[name='ditty_body']").val();

      $.ajax({
        url: this,
        type: 'POST',
        timeout: 5000,
        data: form_data,
        success: function (data, status) {
          $(tag).parents('.ditty_edit').after(data);
          $(tag).parents('.ditty_edit').remove();
          $("a[title='" + form_data.title + "'].new_ditty").addClass('existing').removeClass('new_ditty').attr('href', "/"+ form_data.title);
        },
        error: function (xhr, status) {
          alert(xhr.responseText);
        }
      });
      return false;
    }
  );

}); // close ready block
