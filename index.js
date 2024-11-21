document.onscroll = function() {
    if (window.scrollY > 10) {
        document.getElementById("bar").style.boxShadow="0pt 4pt darkgray";
        document.getElementById("up_button").style.display="block";
    }else{
        document.getElementById("bar").style.boxShadow="0pt 4pt white";
        document.getElementById("up_button").style.display="none";
    }
}
function topFunction() {
    document.body.scrollTop = 0;
    document.documentElement.scrollTop = 0;
}
