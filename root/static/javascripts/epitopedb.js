function validate_form(form, epit_mut_type) {
    var type = form.name;
    if (type == "peptide_result") {
        if (form.inputfile.value) {
            form.submit();
            return false;
        }else {
            if(!validate_pept_name(form)) {
                return false;
            }
            if (!validate_pept_seq(form)) {
                return false;
            }
            if (!validate_origin(form)) {
                return false;
            }
            if (!validate_region(form)) {
                return false;
            }
            if (!validate_hxb2_start(form)) {
                return false;
            }
            if (!validate_hxb2_end(form)) {
                return false;
            }
        }
    }else if (type == "pool_result") {
        if (form.inputfile.value) {
            form.submit();
            return false;
        }else {
            if (!validate_pool_name(form)) {
                return false;
            }
            if (!validate_peptide(form.pept_name.value, form.pept_seq.value)) {
                return false;
            }
        }
    }else if (type == "peptide_elispot_result") {
        if (form.inputfile.value) {
            form.submit();
            return false;
        }else {
            if(!validate_exp_year(form)) {
                return false;
            }
            if(!validate_exp_month(form)) {
                return false;
            }
            if(!validate_exp_day(form)) {
                return false;
            }
            if (!validate_plate(form)) {
                return false;
            }
            if (!validate_cohort(form)) {
                return false;
            }
            if (!validate_patient(form)) {
                return false;
            }
            if (!validate_sample(form)) {
                return false;
            }
            if (!validate_cell_num(form)) {
                return false;
            }
            if (!validate_peptide(form.pept_name.value, form.pept_seq.value)) {
                return false;
            }
            if (!validate_sfc(form)) {
                return false;
            }
        }

    }else if (type == "titration_result") {
        if (form.inputfile.value) {
            form.submit();
            return false;
        }else {
            if(!validate_exp_year(form)) {
                return false;
            }
            if(!validate_exp_month(form)) {
                return false;
            }
            if(!validate_exp_day(form)) {
                return false;
            }
            if (!validate_plate(form)) {
                return false;
            }
            if (!validate_cohort(form)) {
                return false;
            }
            if (!validate_patient(form)) {
                return false;
            }
            if (!validate_sample(form)) {
                return false;
            }
            if (!validate_cell_num(form)) {
                return false;
            }
            if (!validate_peptide(form.pept_name.value, form.pept_seq.value)) {
                return false;
            }
            if (!validate_conc(form)) {
                return false;
            }
            if (!validate_sfc(form)) {
                return false;
            }
        }
    }else if (type == "hla_restriction_result") {
        if (form.inputfile.value) {
            form.submit();
            return false;
        }else {
            if(!validate_exp_year(form)) {
                return false;
            }
            if(!validate_exp_month(form)) {
                return false;
            }
            if(!validate_exp_day(form)) {
                return false;
            }
            if (!validate_plate(form)) {
                return false;
            }
            if (!validate_cohort(form)) {
                return false;
            }
            if (!validate_patient(form)) {
                return false;
            }
            if (!validate_sample(form)) {
                return false;
            }
            if (!validate_cell_num(form)) {
                return false;
            }
            if (!validate_blcl(form)) {
                return false;
            }
            if (!validate_peptide(form.pept_name.value, form.pept_seq.value)) {
                return false;
            }
            if (!validate_sfc(form)) {
                return false;
            }
        }
    }else if (type == "pool_elispot_result") {
        if (form.inputfile.value) {
            form.submit();
            return false;
        }else {
            if(!validate_exp_year(form)) {
                return false;
            }
            if(!validate_exp_month(form)) {
                return false;
            }
            if(!validate_exp_day(form)) {
                return false;
            }
            if (!validate_plate(form)) {
                return false;
            }
            if (!validate_cohort(form)) {
                return false;
            }
            if (!validate_patient(form)) {
                return false;
            }
            if (!validate_sample(form)) {
                return false;
            }
            if (!validate_cell_num(form)) {
                return false;
            }
            if (!validate_pool_name(form)) {
                return false;
            }
            if (!validate_matrix_index(form)) {
                return false;
            }
            if (!validate_sfc(form)) {
                return false;
            }
        }
    }else if (type == "epitope_mutant_result") {

            if (!validate_peptide(form.ept_name.value, form.ept_seq.value, 'epitope')) {
                return false;
            }

        if(!validate_source(form)) {
            return false;
        }
        if (epit_mut_type == "mutant") {
            if (!validate_peptide(form.mut_name.value, form.mut_seq.value, epit_mut_type)) {
                return false;
            }
            if (!validate_cohort(form)) {
                return false;
            }
            if (!validate_patient(form)) {
                return false;
            }
            if (!validate_result(form)) {
                return false;
            }
        }
    }
    return true;
}

function validate_pept_name(form) {
    var pept_name = form.pept_name.value;
    if (!pept_name) {
        alert ("Please enter the peptide name");
        return false;
    }else if (pept_name.match(/^\s+/) || pept_name.match(/\s+$/)) {
        alert ("Please no leading or ending whitespace(s) in peptide name");
        return false;
    }
    return true;
}

function validate_pept_seq(form) {
    var pept_seq = form.pept_seq.value;
    if (!pept_seq) {
        alert ("Please enter the peptide sequence");
        return false;
    }else if (!pept_seq.match(/^[A-Za-z]+$/)) {
        alert ("Please enter the valid peptide sequence");
        return false;
    }
    return true;
}

function validate_pool_name(form) {
    var pool_name = form.pool_name.value;
    if (!pool_name) {
        alert ("Please enter the pool name");
        return false;
    }else if (pool_name.match(/^\s+/) || pool_name.match(/\s+$/)) {
        alert ("Please no leading or ending whitespace(s) in pool name");
        return false;
    }
    return true;
}

function validate_origin(form) {
    var origin = form.origin.value;
    if (!origin) {
        alert ("Please choose one of peptide origins");
        return false;
    }
    return true;
}

function validate_region(form) {
    var region = form.region.value;
    if (!region) {
        alert ("Please choose one of regions");
        return false;
    }
    return true;
}

function validate_hxb2_start(form) {
    var hxb2_start = form.hxb2_start.value;
    if (!hxb2_start) {
        alert ("Please enter the peptide's HXB2 start position");
        return false;
    }else if (!hxb2_start.match(/^\d+$/)) {
        alert ("Please enter only digit(s) for HXB2 start position");
        return false;
    }
    return true;
}

function validate_hxb2_end(form) {
    var hxb2_end = form.hxb2_end.value;
    if (!hxb2_end) {
        alert ("Please enter the peptide's HXB2 end position");
        return false;
    }else if (!hxb2_end.match(/^\d+$/)) {
        alert ("Please enter only digit(s) for HXB2 end position");
        return false;
    }
    return true;
}

function validate_exp_year(form) {
    var exp_year = form.exp_year.value;
    if (!exp_year) {
        alert ("Please choose the year of experiment");
        return false;
    }
    return true;
}

function validate_exp_month(form) {
    var exp_month = form.exp_month.value;
    if (!exp_month) {
        alert ("Please choose the month of experiment");
        return false;
    }
    return true;
}

function validate_exp_day(form) {
    var exp_day = form.exp_day.value;
    if (!exp_day) {
        alert ("Please choose the day of experiment");
        return false;
    }
    return true;
}

function validate_plate(form) {
    var plate = form.plate.value;
    if (!plate) {
        alert ("Please enter plate number for the experiment");
        return false;
    }else if (!plate.match(/^\w+$/)) {
        alert ("Please enter the plate number with only letters, digits, and underscores");
        return false;
    }
    return true;
}

function validate_cohort(form) {
    var cohort = form.cohort.value;
    if (!cohort) {
        alert ("Please choose a cohort");
        return false;
    }
    return true;
}

function validate_patient(form) {
    if (!form.patient || !form.patient.value) {
        alert ("Please choose a patient");
        return false;
    }
    return true;
}

function validate_sample(form) {
    if (!form.sample_id || !form.sample_id.value) {
        alert ("Please choose date and tissue for the patient");
        return false;
    }
    return true;
}

function validate_cell_num(form) {
    var cell_num = form.cell_num.value;
    if (!cell_num) {
        alert ("Please enter the cell numbers per well");
        return false;
    }else if (!cell_num.match(/^\d+$/)) {
        alert ("Please enter only digit(s) for cell numbers");
        return false;
    }
    return true;
}

function validate_peptide(pept_name, pept_seq, type) {

    if (!pept_name && !pept_seq) {
        if (type == "epitope") {
            alert ("Please enter wild-type peptide by either name or sequence");
        }else if (type == "mutant") {
            alert ("Please enter mutant peptide by either name or sequence");
        }else {
            alert ("Please enter peptide by either name or sequence");
        }
        return false;
    }else if (pept_name) {
        if (pept_name.match(/^\s+/) || pept_name.match(/\s+$/)) {
            if (type == "epitope") {
                alert ("Please no leading or ending whitespace(s) in wild-type peptide name");
            }else if (type == "mutant") {
                alert ("Please no leading or ending whitespace(s) in mutant peptide name");
            }else {
                alert ("Please no leading or ending whitespace(s) in peptide name");
            }
            return false;
        }
    }else if (pept_seq) {
        if (!pept_seq.match(/^[A-Za-z]+$/)) {
            if (type == "epitope") {
                alert ("Please enter the valid sequence for wild-type peptide");
            }else if (type == "mutant") {
                alert ("Please enter the valid sequence for mutant peptide");
            }else {
                alert ("Please enter the valid peptide sequence");
            }
            return false;
        }
    }
    return true;
}

function validate_sfc(form) {
    var sfc_obj = form.sfc;
    if (sfc_obj.length) {
        for (var i = 0; i < sfc_obj.length; i++) {
            if (!sfc_obj[i].value) {
                alert ("Please enter the number of spot forming cells");
                return false;
            }else if (!sfc_obj[i].value.match(/^\d+$/)) {
                alert ("Please enter valid number of spot forming cells");
                return false;
            }
        }
    }else if (sfc_obj.value) {
        if (!sfc_obj.value.match(/^\d+$/)) {
            alert ("Please enter valid number of spot forming cells");
            return false;
        }
    }else {
        alert ("Please enter the number of spot forming cells");
        return false;
    }
    return true;
}

function validate_conc(form) {
    var conc = form.conc.value;
    if (!conc) {
        alert ("Please choose a concentration");
        return false;
    }
    return true;
}

function validate_blcl(form) {
    var blcl = form.blcl.value;
    if (!blcl) {
        alert ("Please choose a BLCL");
        return false;
    }
    return true;
}

function validate_pool_name(form) {
    var pool_name = form.pool_name.value;
    if (!pool_name) {
        alert ("Please enter the peptide pool name");
        return false;
    }else if (pool_name.match(/^\s+/) || pool_name.match(/\s+$/)) {
        alert ("Please no leading or ending whitespace(s) in peptide pool name");
        return false;
    }
    return true;
}

function validate_matrix_index(form) {
    var matrix_index = form.matrix_index.value;
    if (matrix_index && !matrix_index.match(/^\w+$/)) {
        alert ("Please enter the matrix index with only letters, digits, and underscores");
        return false;
    }
    return true;
}

function validate_source(form) {
    var source = form.source.value;
    if (!source) {
        alert ("Please choose a source of the epitope");
        return false;
    }
    return true;
}

function validate_result(form) {
    var result = form.note.value;
    if (!result) {
        alert ("Please choose a result of the mutant");
        return false;
    }
    return true;
}



function restalltextbox(textbox) {
    var name = textbox.name;
//    alert ("name: "+name);
    var size = textbox.size;
    var textSpan = textbox.parentNode;
    textSpan.removeChild(textbox);
    var input = document.createElement("input");
    input.setAttribute('type', 'text');
    input.setAttribute('name', name);
    if (name =='pept_name' || name == "pept_seq") {
        input.setAttribute('id', name);
        input.setAttribute('class', 'auto');
    }

    if (size) {
        input.setAttribute('size', size);
    }
    textSpan.appendChild(input);
    input.focus();

    if (name =='pept_name' || name == "pept_seq") {
        new AutoSuggestControl(document.getElementById(name), new RemoteSuggestions(name));
    }
}

function addMeasure(button) {
    var parentDiv = button.parentNode.parentNode;
    var buttonSpan = button.parentNode.parentNode.removeChild(button.parentNode);    //remove button span
    var br = document.createElement("br");
    br.setAttribute("clear", "all");
    var newLabel = document.createElement("label");
    newLabel.appendChild(document.createTextNode("Measure " + (parentDiv.getElementsByTagName("label").length + 1)));
    var formSpan = document.createElement("span");
    formSpan.setAttribute("class", "formw");
    var input = document.createElement("input");
    input.setAttribute("type", "text");
    input.setAttribute("name", "sfc");

    formSpan.appendChild(input);

    if(parentDiv.getElementsByTagName("label").length == 1) {
        var buttonInput = document.createElement("input");
        buttonInput.setAttribute("type", "button");
        buttonInput.setAttribute("value", " - ");
        buttonInput.setAttribute("onclick", "removeMeasure(this)");
        buttonSpan.appendChild(buttonInput);
    }

    parentDiv.appendChild(br);
    parentDiv.appendChild(newLabel);
    parentDiv.appendChild(formSpan);
    parentDiv.appendChild(buttonSpan);
    input.focus();
}

function removeMeasure(button) {
    var buttonDiv = button.parentNode.parentNode;
    var buttonSpan = buttonDiv.removeChild(button.parentNode);
    var labels = buttonDiv.getElementsByTagName("label");
    var inputs = buttonDiv.getElementsByTagName("input");
    var brs = buttonDiv.getElementsByTagName("br");
    buttonDiv.removeChild(inputs.item(inputs.length - 1).parentNode);
    buttonDiv.removeChild(labels.item(labels.length - 1));
    buttonDiv.removeChild(brs.item(brs.length - 1));
    inputs.item(inputs.length - 1).focus();
    if (labels.length == 1) {
        var inputs = buttonSpan.getElementsByTagName("input");
        buttonSpan.removeChild(inputs.item(inputs.length-1));
    }
    buttonDiv.appendChild(buttonSpan);

}

function noenter(event) {
    if(event && event.which == 13) {
        getSamples(); 
        return false;
    }
}

function removeChildNodes(parentNode) {
    var kids = parentNode.childNodes;    // Get the list of children
    var numkids = kids.length;  // Figure out how many children there are
    for(var i = numkids-1; i >= 0; i--) {  // Loop backward through the children
        var c = parentNode.removeChild(kids[i]);    // Remove a child
    }
}

function Remote() {

    if (typeof XMLHttpRequest != "undefined") {
        this.http = new XMLHttpRequest();
    } else if (typeof ActiveXObject != "undefined") {
        this.http = new ActiveXObject("MSXML2.XmlHttp");
    } else {
        alert("No XMLHttpRequest object available. This functionality will not work.");
    }
}

function getPatient(coId) {
    var info = document.getElementById("patientSpan");
    removeChildNodes(info);
    if (coId) {
        var http = new Remote();
        RequestPatients(http.http, coId);
    }

}

function RequestPatients (oHttp, coId) {
//    alert ("coId: "+coId);
//    return;

    //build the URL
    var sURL = viroverse.url_base + "/enum/patients/" + coId;
 
    //open connection to states.txt file
    oHttp.open("get", sURL, true);
    oHttp.onreadystatechange = function () {
        if (oHttp.readyState == 4) {
            //evaluate the returned text JavaScript (an array)
            eval(oHttp.responseText);
            aPatient = json_result;
            writePatients(aPatient);
        }    
    };

    oHttp.send(null);
}

function writePatients(aPatient) {
    var info = document.getElementById("patientSpan");
    removeChildNodes(info);

    var spanSelect = document.createElement("select");
    spanSelect.setAttribute("name", "patient");
    spanSelect.setAttribute("onChange", "getSample(this.value)");
    spanSelect.style.width = "150px";

    var topOption = document.createElement("option");
    topOption.setAttribute("value", "");
    topOption.setAttribute("selected", "true");
    topOption.appendChild(document.createTextNode("Choose one"));
    spanSelect.appendChild(topOption);

    var aPatient_temp = new Array();
    var aPatitne_asoc = new Array();
    for (var i in aPatient) {
        aPatient_temp.push(aPatient[i].external_patient_id);
        aPatitne_asoc[aPatient[i].external_patient_id] = aPatient[i].patient_id;
    }

    var aPatient_sort = aPatient_temp.sort();

    for (var i in aPatient_sort) {
        var option = document.createElement("option");
        option.setAttribute("value", aPatitne_asoc[aPatient_sort[i]]);
        option.appendChild(document.createTextNode(aPatient_sort[i]));
        spanSelect.appendChild(option);
    }
    info.appendChild(spanSelect);
}

function getSample(patient_id) {
    var info = document.getElementById("patientInfo");
    removeChildNodes(info);
    if (patient_id) {
        var http = new Remote();
        RequestSamples(http.http, patient_id);
    }

}

function RequestSamples (oHttp, patient_id) {
//    alert ("coId: "+coId);
//    return;

    //build the URL
    var sURL = viroverse.url_base + "/enum/samples/" + patient_id;
 
    //open connection to states.txt file
    oHttp.open("get", sURL, true);
    oHttp.onreadystatechange = function () {
        if (oHttp.readyState == 4) {
            //evaluate the returned text JavaScript (an array)
            eval(oHttp.responseText);
            aSample = json_result;
            writeSamples(aSample);
        }    
    };

    oHttp.send(null);
}


function writeSamples(aSample) {
    var info = document.getElementById("patientInfo");
    removeChildNodes(info);

    count = count_properties(aSample)
    if (!count) {
        info.appendChild(document.createTextNode("There is no sample recorded for this patient."));

    } else {
        var spanSelect = document.createElement("select");
        spanSelect.setAttribute("name", "sample_id");
        spanSelect.style.width = "150px";

        var aSample_temp = new Array();
        var aSample_asoc = new Array();
        for (var i in aSample) {
            var date = aSample[i].date;
            var tissue_type = aSample[i].tissue_type;
            var sample_id = aSample[i].sampleid;
            if (!aSample_asoc[date]) {
                aSample_asoc[date] = new Array();
                aSample_temp.push(date);
            }
            aSample_asoc[date][sample_id] = tissue_type;
        }

        var aSample_sort = aSample_temp.sort();

        for (var i in aSample_sort) {
            var date = aSample_sort[i];
            for (var sample_id in aSample_asoc[date]) {
                var tissue_type = aSample_asoc[date][sample_id];
                var sample_label = date+", "+tissue_type;
                var option = document.createElement("option");
                option.setAttribute("value", sample_id);
                option.appendChild(document.createTextNode(sample_label));
                spanSelect.appendChild(option);
            }
        }
        info.appendChild(spanSelect);
    }
}


function to_search_sidebar_ajax(type, pept, edate, sdate, tissue) {
//    alert ("url_base: "+url_base);
    var new_tissue = tissue;
    if (tissue.match(/\+/)) {
        new_tissue = tissue.replace(/\+/, "%2b");
    }
    var url = viroverse.url_base + "/search/epitopedb_search/peptide/show_figure?type="+type+"&pept="+pept+"&tissue="+new_tissue+"&edate="+edate+"&sdate="+sdate;
//    alert ("url: "+url);
    var http = make_xmlhttp();

    http.open('GET',url,true);
    http.onreadystatechange = function() {

        if (http.readyState == 4) {
//            alert ("html: "+http.responseText);
            document.getElementById('search_sidebar_content').innerHTML = http.responseText;
        }
    }
    http.send(null);
}


function to_sidebar_ajax(sourceForm_id, error_div_id, ept_mut_type) {
    source = document.getElementById(sourceForm_id);
    if (!source) {
        alert(sourceForm_id+" could not be found");
    }
    form_get = form2url(source);

    if (ept_mut_type == "epitope_result" || ept_mut_type == "mutant_result") {
        form_get = form_get+'&type='+ept_mut_type;
    }

//    alert ("type: "+form_get);

    var http = make_xmlhttp();

    http.open('GET',form_get,true);
    http.onreadystatechange = function() {

        if (http.readyState == 4) {
            if (error_div_id && http.responseText.substring(0,5) == 'Error' ) {
                ediv = document.getElementById('error');
                ediv.style.display = 'block';
                ediv.innerHTML = http.responseText;
            } else {
                if (error_div_id) {
                    document.getElementById(error_div_id).style.display = 'none';
                }
                document.getElementById('sidebar_content').innerHTML = http.responseText;
            } 

        }
    }
    http.send(null);
}

function update(sourceForm_id) {
    source = document.getElementById(sourceForm_id);
    if (!source) {
        alert(sourceForm_id+" could not be found");
    }
    form_get = form2url(source);
//    alert ("form_get: "+form_get);
    var http = make_xmlhttp();

    http.open('GET',form_get,true);
    http.onreadystatechange = function() {
//        alert ("readyState: "+http.readyState);
        if (http.readyState == 4) {
            document.getElementById('sidebar_content').innerHTML = http.responseText;
        }
    }
    http.send(null);

}

function skip(sourceForm_id) {
    var http = make_xmlhttp();
    var url = viroverse.url_base + '/input/epitopedb/input_sidebar/skip';
//    alert ("url: "+url);
    http.open('GET',url,true);
    http.onreadystatechange = function() {
//        alert ("readyState: "+http.readyState);
        if (http.readyState == 4) {
            document.getElementById('sidebar_content').innerHTML = http.responseText;
        }
    }
    http.send(null);

}


