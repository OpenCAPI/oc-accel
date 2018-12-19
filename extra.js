(function(){
//rest of the javascript code here
 //  $(".dropdown-menu li a").click(function(){
 //	alert("This is alert!");
 // });

  $('.dropdown-menu li a').click(function(){
	var node = document.createElement("LI");
	var textnode = document.createTextNode($(this).text()); 
	node.appendChild(textnode);
	document.getElementsByClassName("main active").appendChild(node);
  });
 /*   $('.dropdown').each(function (key, dropdown) {
        var $dropdown = $(dropdown);
        $dropdown.find('.dropdown-menu a').on('click', function () {
			alert($(this).text());
            $dropdown.find('button').text($(this).text()).append(' <span class="caret"></span>');
        });
    });
 */
}).call(this);
