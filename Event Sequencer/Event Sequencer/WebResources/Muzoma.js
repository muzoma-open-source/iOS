// (c) 2016 Muzoma Limited
// scrolling code for HTML webview
//alert('hello');
var curLine = 0
window.setInterval(function () { gotoLine(curLine++, "chords") }, 800);

// e.g. gotoLine(curLine++, "chords")
function gotoLine(songLine, className) {
    var eles = document.getElementsByClassName(className);
    if (songLine < eles.length) {
        scroll.To(eles[songLine]);
    }
}

var scrollHandle = 0
var scroll = (function () {
    var elementPosition = function (a) {
        return function () {
            return a.getBoundingClientRect().top;
        };
    };

    var scrolling = function (el) {
        window.clearTimeout(scrollHandle) // clear down for multiple calls

        var elPos = elementPosition(el),
            duration = 100,
            increment = Math.round(Math.abs(elPos()) / 40),
            time = Math.round(duration / increment),
            prev = 0,
            E;

        function scroller() {
            E = elPos();

            if (E === prev) {
                return;
            } else {
                prev = E;
            }

            increment = (E > -20 && E < 20) ? ((E > -5 && E < 5) ? 1 : 5) : increment;

            if (E > 1 || E < -1) {

                if (E < 0) {
                    window.scrollBy(0, -increment);
                } else {
                    window.scrollBy(0, increment);
                }

                scrollHandle = setTimeout(scroller, time);

            } else {
                scrollHandle = 0
            }
        }

        scroller();
    };

    return {
        To: scrolling
    }

})();