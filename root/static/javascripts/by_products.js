toggleAllChromats = (function(){
    var state = false;

    return function() {
        state = !state;
        document.querySelectorAll('input.skip-chromats').forEach(function(c) {
            c.checked = state;
        })

        return false;
    }
})();
