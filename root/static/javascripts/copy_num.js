
function initOverlays(){
    YAHOO.namespace("copy_num");



        YAHOO.copy_num.calcVolcDNA = new YAHOO.widget.Overlay("calcVolcDNA", { visible:false, width:"450px" ,context: ["copy_num_res","tl","tr",["beforeShow", "windowResize"]]} );
        YAHOO.copy_num.calcVolcDNA.render(document.body);

        YAHOO.util.Event.addListener("hideCalc", "click", YAHOO.copy_num.calcVolcDNA.hide, YAHOO.copy_num.calcVolcDNA, true);

        YAHOO.copy_num.dil_table = new YAHOO.widget.Overlay("dil_table", { visible:false, width:"450px" ,context: ["copy_num_res","tl","tr",["beforeShow", "windowResize"]]} );
        YAHOO.copy_num.dil_table.setHeader("Copy Number Dilution Table");
        YAHOO.copy_num.dil_table.setBody("");
        YAHOO.copy_num.dil_table.setFooter('<input type="button" id="hide3" value="Close" />');
        YAHOO.copy_num.dil_table.render(document.body);
        YAHOO.util.Event.addListener("show3", "click", YAHOO.copy_num.dil_table.show, YAHOO.copy_num.dil_table, true);
        YAHOO.util.Event.addListener("hide3", "click", YAHOO.copy_num.dil_table.hide, YAHOO.copy_num.dil_table, true);
}

var dilutions = new Array();

function show_copy_number(sel, cntr_id){
    var ids = new Array();
    for(var i = 0 ; i < sel.options.length ; i++){
        if(sel.options[i].selected){
            ids.push(sel.options[i].value);
        }
    }
    var http = make_xmlhttp();
    dilutions.length = 0;
    http.open('POST', viroverse.url_base + "/input/pcr/fetchCopyNumber/" + ids.join("/"),true);
    http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
    http.onreadystatechange = function () {
        if(http.readyState == 4){
            handleCopyNumData(http, cntr_id);
        }
         
    }
    http.send();

}

function handleCopyNumData(http, cntr_id){

    var response = eval( "(" + http.responseText + ")");
    var copy_num_data = response.Response;
    var container = document.getElementById(cntr_id);
    YAHOO.copy_num.dil_table.hide()
    container.innerHTML = "<h2>Amplifiable Copy Number calculations";
    if (!Object.keys(copy_num_data).length) {
        var p = document.createTextNode('No previous reactions');
        container.appendChild(p);
    }
    for(var iter in copy_num_data){
        var head = document.createElement("h3");
        head.innerHTML = copy_num_data[iter].name;
        container.appendChild(head);
        for(var id in copy_num_data[iter]){
            if (id == 'name') continue;
            var cpnumVal = document.createElement("p");
            cpnumVal.innerHTML = copy_num_data[iter][id].valueToString + "&nbsp;&nbsp;";
            container.appendChild(cpnumVal);
            if ( dilutions[id] = copy_num_data[iter][id].dil_table ) {
                var dilLink = document.createElement("a");
                dilLink.innerHTML = "Dilutions";
                dilLink.id = "dilLink_" + id;
                dilLink.className = "clk";
                dilLink.onclick = function(){ showDilTable(this);};
                cpnumVal.appendChild(dilLink);
            } else {
                var d = document.createTextNode('no calculations available');
                cpnumVal.appendChild(d);
            }
            cpnumVal.appendChild(document.createTextNode("\u00A0\u00A0"));
            if (copy_num_data[iter][id].value) {
                var cpVolCalc = document.createElement("a");
                cpVolCalc.innerHTML = "Calc Vol cDNA";
                cpVolCalc.onclick = function(){ showCalcVolcDNA(this);};
                cpVolCalc.setAttribute("data-copy_num", copy_num_data[iter][id].value );
                cpVolCalc.className = "clk";
                cpnumVal.appendChild(cpVolCalc);
            }
        }
    }
}

function showDilTable(clicked){
    var id = clicked.id.substr(clicked.id.search(/_/) + 1);
    YAHOO.copy_num.dil_table.cfg.setProperty("context",[clicked,"tl","tr"]);
    if (dilutions[id]) {
        YAHOO.copy_num.dil_table.setBody("<pre>" + dilutions[id] + "</pre>");
    } else {
        YAHOO.copy_num.dil_table.setBody("<pre>no data available</pre>");
    }
    YAHOO.copy_num.dil_table.show();
     }

function showCalcVolcDNA(clicked){
    var pos_rat = document.getElementById('pos_rat').value;
    document.getElementById('copy_num').value = clicked.getAttribute("data-copy_num");
    calcVolcDNA(pos_rat);
    YAHOO.copy_num.calcVolcDNA.cfg.setProperty("context",[clicked,"tl","tr"]);
    YAHOO.copy_num.calcVolcDNA.show();
}
function calcVolcDNA(pos_rat){
    var copy_num = document.getElementById('copy_num').value;
    var vol = (1/ parseFloat(pos_rat))/parseFloat(copy_num);
    vol = Math.round(vol * 1000)/1000
    document.getElementById('cp_num_calc_vol').innerHTML = vol;
    return vol;
}

function setInputVol(){
    var pos_rat = document.getElementById('pos_rat').value;
    var vol = calcVolcDNA(pos_rat);
    document.getElementById("input_vol").value = vol;
    YAHOO.copy_num.calcVolcDNA.hide();

}
