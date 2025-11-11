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

// Little easter egg

function easterEgg() {
    if((navigator.platform.includes("BSD") ||
       navigator.platform.includes("Linux") ||
       navigator.platform.includes("SunOS") ||
       navigator.platform.includes("HP-UX")) &&
       !navigator.userAgent.includes("Android")) {
        /* I'm not including Android and all the Apple OSs  */
        var group = document.createElement("div");
        group.className = "group";

        var message = document.createElement("p");
        message.innerHTML = "UNIX \\o/";
        group.appendChild(message);

        document.body.prepend(group);
    }else if(navigator.platform.includes("Haiku")) {
        var group = document.createElement("div");
        group.className = "group";

        var message = document.createElement("p");
        message.innerHTML = "Haiku \\o/";
        group.appendChild(message);

        document.body.prepend(group);
    }

    if(navigator.userAgent.includes("Ladybird/")) {
        var group = document.createElement("div");
        group.className = "group";

        var message = document.createElement("p");
        message.innerHTML = "Nice web browser! It looks like you're using " +
                            "&#128030;!";
        group.appendChild(message);

        document.body.prepend(group);
    }
}
