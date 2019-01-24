// is this used? (bmaust 2008-08-05)
function add (sourceForm_id, targetTable_id, input_name) {
    var source = document.getElementById(sourceForm_id);
    var target = document.getElementById(targetTable_id);

    var selects = source.getElementsByTagName('select');
    for (var i=0; i < selects.length; i++) {
            select = selects.item(i)
        if (select.value.length <1) {
                continue
            }

            var input = document.createElement("input");
            input.setAttribute("type", "hidden");
            input.setAttribute("name", input_name);
            input.setAttribute("value", select.value);

            add_to_box(input, select.options.item(select.selectedIndex).text, target, select.value);

    }

}

// deprecated 2008-08-05 (used in post_gel.tt,PCR.tt, etc)
function form_to_sidebar_ajax(sourceForm_id,sidebar_type,error_div_id) {
    to_do = function () {
        reload_sidebar(sidebar_type);
        setFormDisable(source,false)
    };

    submit_form_ajax(sourceForm_id,to_do,error_div_id);
}

function sidebar_remove (object_type,object_id,reload_type) {
    if (!reload_type) {
        reload_type = object_type;
    }
    var sidebar_url = viroverse.url_base + 'sidebar/remove/' + object_type + '/' + object_id;
    var http = make_xmlhttp();

    http.open('GET',sidebar_url,true);
    http.onreadystatechange = function () {
        if (http.readyState == 4) {
            reload_sidebar(reload_type);
        }
    }
    http.send(null);

    return false; //prevent scrolling to the top
}

function sidebar_clear_type (object_type,reload_type) {
    if (!reload_type) {
        reload_type = object_type;
    }
    var sidebar_url = viroverse.url_base + 'sidebar/remove_type/' + object_type;
    var http = make_xmlhttp();

    http.open('GET',sidebar_url,true);
    http.onreadystatechange = function () {
        if (http.readyState == 4) {
            reload_sidebar(reload_type);
        }
    }
    http.send(null);

    return false; //prevent scrolling to the top

}

function sidebar_add (object_type,object_id,desc,arg_array) {
    var object_str;
    if (typeof(object_id) == 'object') {
        object_str = object_id.join('/');
    } else {
        object_str = object_id;
    }
    var sidebar_name = arg_array?arg_array[0]:"";
    var reload_name;
    if (sidebar_name) {
        reload_name = sidebar_name;
    } else {
        reload_name = object_type;
    }
    var sidebar_url = viroverse.url_base + '/sidebar/add/'+object_type+'/' + object_str;
    var http = make_xmlhttp();

    var button, spinner;
    if (window.product_finder && this instanceof product_finder) {
        button = this.btn_el;
        button.disabled = true;
        spinner = document.createElement("img");
        spinner.src = viroverse.url_base + "/static/images/spinner.gif";
        YAHOO.util.Dom.insertAfter(spinner, button);
    }

    http.open('GET',sidebar_url,true);
    http.onreadystatechange = function () {

        if (http.readyState == 4) {
            if (button)  button.disabled = false;
            if (spinner) spinner.parentNode.removeChild(spinner);
            reload_sidebar(reload_name);
        }
    }
    http.send(null);
}

function reload_sidebar (object_type ) {
    if (!document.getElementById('sidebar')) return;

    var sidebar_url = viroverse.url_base + '/sidebar/' + object_type;

    var sidebar = document.getElementById('sidebar');
    var overlay = gray_overlay(sidebar);

    var http = make_xmlhttp();
    http.open('GET', sidebar_url,true);
    http.onreadystatechange = function () {
        // Update overlay appearance
        overlay.class = 'loading' + http.readyState;

        if (http.readyState == 4) {
            sidebar.innerHTML = http.responseText;
            evalScripts(sidebar);
            overlay.parentNode.removeChild(overlay);
        }
    };
    http.send(null);
    return false;
}

function add_single_input (input, text_description, targetTable_id) {
    var target = document.getElementById(targetTable_id);

    var new_input = document.createElement("input");
    new_input.setAttribute("type", "hidden");
    new_input.setAttribute("name", input.name);
    new_input.setAttribute("value", input.value);


    add_to_box(new_input, text_description, target, input.id);

}

function sync_checkbox (box,type,id) {
    if (box.checked) {
        sidebar_add(type,id,null,[]);
    } else {
        sidebar_remove(type,id)
    }
}


// and is this being used? bmaust 2008-08-05
function add_to_box (input, text, target_table,id) {

            var delContainer = document.createElement("th");

            var alink = document.createElement("a");
            alink.setAttribute("href", "#");
            alink.setAttribute("onclick", "deleteThis(this.parentNode.parentNode)");
            alink.setAttribute("class", "del_link");
            alink.appendChild(document.createTextNode("del"));
            delContainer.appendChild(alink);
            delContainer.appendChild(input);

            var newTD = document.createElement("td");
            newTD.appendChild(document.createTextNode( text ));
            newTR = target_table.insertRow(-1);
            newTR.id = 'del_'+id;
            newTR.appendChild(delContainer);
            newTR.appendChild(newTD);

}
