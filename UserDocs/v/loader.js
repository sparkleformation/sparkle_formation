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
  $('#content').html(marked(content));
  hljs.initHighlighting();
}

$(document).ready(load_page);
$(document).on('page:load', load_page);
