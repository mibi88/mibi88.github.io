document.onscroll = function() {
    if (window.scrollY > 10) {
        document.getElementById("bar").style.boxShadow =
                                                "0pt 4pt var(--shadow)";
        document.getElementById("up_button").style.display = "block";
    }else{
        document.getElementById("bar").style.boxShadow =
                                                    "0pt 4pt var(--bar-bg)";
        document.getElementById("up_button").style.display = "none";
    }
}
function topFunction() {
    document.body.scrollTop = 0;
    document.documentElement.scrollTop = 0;
}

function loadArticle(element) {
    var xmlhttp = new XMLHttpRequest();
    xmlhttp.onreadystatechange = () => {
        if(xmlhttp.status == 200 && xmlhttp.readyState == 4){
            element.innerHTML = xmlhttp.responseText;
            var article_list = document.getElementById("article-list");
            var titles = element.getElementsByClassName("title");
            var name = "<i>Untitled</i>";
            if(titles.length){
                name = titles[0].textContent.trim();
            }
            article_list.innerHTML += "<a href=\"#" + element.id + "\">" +
                                      name + "</a></br>"
        }else if(xmlhttp.readyState == 4){
            var url = element.textContent.trim();
            element.innerHTML = "<b>Failed to load article</b> " +
                                "\"<a href=\"" + url + "\">" +
                                url + "</a>\"!";
        }
    };
    xmlhttp.open("GET", element.textContent, true);
    xmlhttp.send();
}

function loadAllArticles() {
    var articles = document.getElementsByClassName("article");
    var article_list = document.getElementById("article-list");
    article_list.innerHTML = "";
    for(var i=0;i<articles.length;i++){
        loadArticle(articles[i]);
    }
}

