function load_page(){
  $.get(
    window.location.pathname.replace('.html', '.md'),
    function(data){
      display_page(data)
    },
    'text'
  );
}

function display_page(content){
  content = content.replace(/.md/g, '.html');
  renderer = new marked.Renderer();
  renderer.heading = function(text, level){
    escapedText = text.toLowerCase().replace(/[^\w]+/g, '-');

    return '<h' + level + '><a name="' +
      escapedText +
      '" class="anchor" href="#' +
      escapedText +
      '"><span class="header-link"></span></a>' +
      text + '</h' + level + '>';
  }
  $('#content').html(marked(content, {renderer: renderer}));
  hljs.initHighlighting();
  if(window.location.hash){
    $('html, body').scrollTop(
      $("a[name='"+ window.location.hash.replace('#', '') + "']").offset().top
    );
  }
}

$(document).ready(load_page);
$(document).on('page:load', load_page);