// (c) 2016 Muzoma Limited
// scrolling code for Muzoma HTML webview
//alert('hello');
/* Test code
var curLine = 0
window.setInterval(function () { gotoLine(curLine) }, 800);
window.setInterval(function () { gotoLine(curLine++, true) }, 1600);
*/

var prevChordEle = null
var prevLyricEle = null

//var bgHiLiteColour = 'lime'

// e.g. gotoLine(curLine++, true)
function gotoLine(songLine, highLight) {
    if( songLine == 0 )
    {
        if( prevChordEle )
        {
            //prevChordEle.style.backgroundColor = null
            prevChordEle.className = 'chords'
            prevChordEle = null
        }
        
        if( prevLyricEle )
        {
            //prevLyricEle.style.backgroundColor = null
            prevLyricEle.className = 'lyrics'
            prevLyricEle = null
        }
        
        var titleEle = document.getElementById( "title" )
        scroll.To(titleEle);
    }
    else
    {
        var chordEle = document.getElementById( "chord" + songLine );
        if (chordEle) {
            scroll.To(chordEle);
            if( highLight )
            {
                if( prevChordEle )
                {
                    //prevChordEle.style.backgroundColor = null
                    prevChordEle.className = 'chords'
                }
                //chordEle.style.backgroundColor = bgHiLiteColour;
                chordEle.className = 'chordsHiLite';
                prevChordEle = chordEle;
            }
        }
        
        var lyricEle = document.getElementById( "lyric" + songLine );
        if (lyricEle) {
            scroll.To(lyricEle);
            if( highLight )
            {
                if( prevLyricEle )
                {
                    //prevLyricEle.style.backgroundColor = null
                    prevLyricEle.className = 'lyrics'
                }
                //lyricEle.style.backgroundColor = bgHiLiteColour;
                lyricEle.className = 'lyricsHiLite';
                prevLyricEle = lyricEle;
            }
        }
    }
}


// e.g. gotoLine(curLine++, "chords")
/*function gotoLine(songLine, className) {
    var eles = document.getElementsByClassName(className);
    if (songLine < eles.length) {
        scroll.To(eles[songLine]);
    }
}*/

var availHeight = window.innerHeight
|| document.documentElement.clientHeight
|| document.body.clientHeight;

var scrollHandle = 0
var scroll = (function () {
    var elementPosition = function (a) {
        return function () {
            return a.getBoundingClientRect().top - (availHeight / 2);  // middle
        };
    };

    var scrolling = function (el) {
        window.clearTimeout(scrollHandle) // clear down for multiple calls

        var elPos = elementPosition(el),
            duration = 200,
            increment = Math.round(Math.abs(elPos()) / 10),
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