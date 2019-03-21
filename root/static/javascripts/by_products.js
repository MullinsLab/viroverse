window.addEventListener("load", function() {
    var state = false;

    function toggleAllChromats() {
        state = !state;
        document.querySelectorAll('input.skip-chromats').forEach(function(c) {
            c.checked = state;
        })

        return false;
    }
    document.querySelectorAll('button.skip-chromats-toggle').forEach(function(b) {
        b.addEventListener("click", toggleAllChromats);
    });
});
