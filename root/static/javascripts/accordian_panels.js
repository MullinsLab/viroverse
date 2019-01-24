function acc_pick_panel(clicked,show_id) {
    var show_el = document.getElementById(show_id);
    if (show_el) {
        if (clicked.innerHTML == '+') {
            show_el.style.display='block';
            clicked.innerHTML = '-'
        } else {
            show_el.style.display='none';
            clicked.innerHTML = '+'
        }
    }
}
