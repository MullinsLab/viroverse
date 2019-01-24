function gel_add_product (object_type,id,desc,error_div_id) {
    var object_ids
    if (typeof(id) == 'object') {
        object_ids = id.join('/');
    } else {
        object_ids = id;
    }
    var the_url = viroverse.url_base + '/input/gel_add_label/'+object_type + '/' +object_ids;

    to_do = function (resp) {
        //TODO: these form_ids should probably be an array passd in
        setFormDisable(document.getElementById('gel_image'),false)
//        setFormDisable(document.getElementById('gel_find'),false)
        //setFormDisable(document.getElementById('new_label_form'),false) Form Removed labels are now added on the annotation page
        //document.getElementById(error_div_id).style.display = 'none';
        reload_sidebar('gel');
    }

    load_url_ajax(the_url,to_do,false,'sidebar');
}

function gel_remove (object_type,object_position) {
    var sidebar_url = viroverse.url_base + '/sidebar/gel_remove/' + object_type + '/' + object_position;
    var http = make_xmlhttp();

    http.open('GET',sidebar_url,true);
    http.onreadystatechange = function () {
        if (http.readyState == 4) {
            reload_sidebar('gel');
        }
    }
    http.send(null);
    return false; //prevent scrolling to the top
}

function gel_sidebar_clear () {
    var url = viroverse.url_base + '/sidebar/gel_clear/';

    div_load_ajax(url,'sidebar');
}


function resizeGel(gel){
    if(gel.width == "400"){
        gel.removeAttribute('width');
    }else{
        gel.width = "400";
    }
}


function intTo96Well(integer) {
    var alphahash = {
                0 : 'A',
                1 : 'B',
                2 : 'C',
                3 : 'D',
                4 : 'E',
                5 : 'F',
                6 : 'G',
                7 : 'H'
    };
    var alpha_key = parseInt(integer/12);
    var numeric = integer % 12;
    if(numeric == 0){
        alpha_key--;
        numeric = 12;
    }
    if(numeric < 10){
        numeric = '0' + numeric;
    }
    return alphahash[alpha_key] + numeric;
}

function ninetySixWell2Int(alpha_numeric){

    var alphahash = {
                'A' : 0,
                'B' : 12,
                'C' : 24,
                'D' : 36,
                'E' : 48,
                'F' : 60,
                'G' : 72,
                'H' : 84
    };
    return alphahash[alpha_numeric.charAt(0)] + parseInt(alpha_numeric.substr(1,2));
}