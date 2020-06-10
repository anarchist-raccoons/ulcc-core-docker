window.onload = function() {
        var outer = document.createElement('div');
        outer.classList.add("ribbon-wrapper");
        var inner = document.createElement('div');
        inner.classList.add("corner-ribbon");
        inner.classList.add("top-right");
        inner.classList.add("shadow");
        inner.classList.add("ribbon-#ENVIRONMENT#");
        var content = document.createTextNode("#ENVIRONMENT_TEXT#");
        inner.appendChild(content);
        outer.appendChild(inner);
        document.body.appendChild(outer);
}
