YAHOO.namespace("vv_freezer");

function freezer_sel(sel, custom){
          var http  = make_xmlhttp();
          http.open('POST', viroverse.url_base + "/freezer/summary/enum/rack/freezer/" + sel.value ,true);
          http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
          http.onreadystatechange = function () {
          if (http.readyState == 4) {
               try{
                    var racks = evalJSON(http);
                    var rackSel = document.getElementById("rack_id");
                    var frm = document.getElementById("find_box");
                    var boxSel = document.getElementById("box_id");
                    if(boxSel){
                        frm.removeChild(boxSel);
                        frm.removeChild(document.getElementById('box_label'));
                    }
                    if(!rackSel){
                         rackSel = document.createElement("select");
                         rackSel.id = "rack_id";
                         if(custom){
                              rackSel.addEventListener("change", custom, false);
                         }else{
                              rackSel.addEventListener("change", function(){rack_sel(rackSel)}, false);
                         }

                         rackLabel = document.createElement("label");
                         rackLabel.id = 'rack_label';
                         rackLabel.htmlFor = 'rack_id';
                         rackLabel.innerHTML = "Rack";
                         frm.appendChild(rackLabel);
                         frm.appendChild(rackSel);
                    }
                    rackSel.options.length = 0;
                    rackSel.options[0] = new Option("Choose one", "", false, false);
                    for (var i = 0 ; i < racks.length ; i++){
                        var idx = i + 1;
                        rackSel.options[idx] = new Option(racks[i].name, racks[i].id, false, false);
                    }
               }catch(e){
                    writeError(e);
               }
          }
    }
    http.send();
}
function rack_sel(sel, pos_click){
          var http  = make_xmlhttp();
          pos_click = pos_click || 'add vials'
          http.open('POST', viroverse.url_base + "/freezer/summary/enum/box/rack/" + sel.value ,true);
          http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
          http.onreadystatechange = function () {
               if (http.readyState == 4) {
                    try{
                         var boxes = eval( "(" + http.responseText + ")").Response;
                         var boxSel = document.getElementById("box_id");
                         var frm = document.getElementById("find_box");

                         if(!boxSel){
                              boxSel = document.createElement("select");
                              boxSel.id = "box_id";
                              boxSel.addEventListener("change", function(){fetchBox(boxSel.value, pos_click)}, false);
                              boxLabel = document.createElement("label");
                              boxLabel.id = 'box_label';
                              boxLabel.htmlFor = 'box_id';
                              boxLabel.innerHTML = "Box";
                              frm.appendChild(boxLabel);
                              frm.appendChild(boxSel);
                         }
                         boxSel.options.length = 0;
                         boxSel.options[0] = new Option("", "", false, false);
                         for (var i = 0 ; i < boxes.length ; i++){
                              var idx = i + 1;
                              boxSel.options[idx] = new Option(boxes[i].name, boxes[i].id, false, false);
                         }
                    }catch(e){
                         document.getElementById('error').innerHTML = "Error: " + e;
                         document.getElementById('debug').innerHTML = http.responseText;
                    }
               }
          }
          http.send();
}

function rack_sel_xfer(){
     rack_sel(document.getElementById("rack_id"), "xfer-vials");

}
function resetFreezer(){
     var f = document.getElementById("freezer_id");
     if(f.selectedIndex > 0){
          freezer_sel(f);
     }
}

function fetchBox(box_id, onclick){
     var boxDiv = document.getElementById('box_display');
     boxDiv.innerHTML = "";
     if(isNaN(box_id) || box_id < 1){
          return;
     }
     var http  = make_xmlhttp();
     var url = onclick?viroverse.url_base + "/freezer/summary/box/" + box_id + "/" + onclick + "/":viroverse.url_base + "/freezer/summary/box/" + box_id;
     showLoadingBox(boxDiv, "Loading Box....", "500px", "500px");
     http.open('POST', url ,true);
     http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
     http.onreadystatechange = function () {
          if (http.readyState == 4) {
               if(http.status == 500){
                    writeError("Server Error");
                    return;
               }
               boxDiv.innerHTML = http.responseText;
               if(viroverse.scientist.can_manage_freezers && YAHOO.vv_freezer && YAHOO.vv_freezer.container && YAHOO.vv_freezer.container.renameBox){
                    var editBoxName = document.createElement("a");
                    var full_name = boxDiv.getElementsByTagName("h2").item(0).innerHTML;
                    var names = full_name.split("/");
                    name = names[2].replace(/\s/,"");
                    editBoxName.className = "clk";
                    editBoxName.innerHTML = "Edit Box Name";
                    editBoxName.addEventListener("click", function(){showRenameBox(name);}, false);
                    document.getElementById('box_id').value = box_id;
                    boxDiv.insertBefore(editBoxName, document.getElementById('freezer_box'));

                    var moveVials = document.createElement("a");
                    moveVials.className = "clk";
                    moveVials.innerHTML = "Reposition Vials";
                    moveVials.href = viroverse.url_base  + "/freezer/input/x_fer_vial/" +  box_id;
                    boxDiv.insertBefore(moveVials, document.getElementById('freezer_box'));
                    //
               }
               if(onclick == 'xfer-vials'){
                    YAHOO.example.DDApp.addBox();
               }
          }
     }
     http.send();
}
function fetchRack(id){
    var rack_id = document.getElementById("rack_id").value;
    var rackDiv = document.getElementById(id);
    rackDiv.innerHTML = "";
    if(isNaN(rack_id) || rack_id < 1){
    return;
    }
    var http  = make_xmlhttp();
    var url = viroverse.url_base + "/freezer/summary/rackAjax/" + rack_id ;
    showLoadingBox(rackDiv.parentNode, "Loading Rack....", "100px", "500px");
    http.open('POST', url ,true);
    http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
    http.onreadystatechange = function () {
        if (http.readyState == 4) {
        if(http.status == 500){
        writeError("Server Error");
        return;
        }
            try{
        rackDiv.parentNode.removeChild(document.getElementById('loadDiv'));
                var rack = evalJSON(http);
                rackDiv.setAttribute("data-rack_id", rack_id);
                with(rackDiv.style){
                    width = (rack.num_columns * 110)  + "px";
                    height = (rack.num_rows * 56) + "px";
                }
                for (var i = 0 ; i < rack.boxes.length ; i++){
                    var box = document.createElement("div");
                    box.className = "freezer-box";
                    box.id = rack.boxes[i].box_id;
                    box.innerHTML = "<span>" + format_box_name(rack.boxes[i].name) + "</span>";
                    rackDiv.appendChild(box);
                }

            }catch(e){
                writeError(e);
            }
        }
    }
    http.send();
}


function fetchDDRack(){
    var rack_id = document.getElementById("rack_id").value;
    var rackDiv = document.getElementById("rack2");
    rackDiv.innerHTML = "";
    if(isNaN(rack_id) || rack_id < 1){
    return;
    }
    var http  = make_xmlhttp();
    var url = viroverse.url_base + "/freezer/summary/rackAjax/" + rack_id ;
    showLoadingBox(rackDiv.parentNode, "Loading Rack....", "100px", "500px");
    http.open('POST', url ,true);
    http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
    http.onreadystatechange = function () {
        if (http.readyState == 4) {
            if(http.status == 500){
                writeError("Server Error");
                return;
            }
            try{
                rackDiv.parentNode.removeChild(document.getElementById('loadDiv'));
                var oldHeads = rackDiv.parentNode.getElementsByTagName("h2");
                for (var i = 0 ; i < oldHeads.length ; i++) {
                    rackDiv.parentNode.removeChild(oldHeads.item(i));
                }
                var rack = evalJSON(http);
                rackDiv.setAttribute("data-rack_id", rack_id);
                with(rackDiv.style){
                    width = (rack.num_columns * 110)  + "px";
                    height = (rack.num_rows * 56) + "px";
                }
                var rackH = document.createElement("h2");
                rackH.innerHTML = "Freezer:  " + rack.freezer.name +' / Rack: ' + rack.name;

                rackDiv.parentNode.insertBefore(rackH, rackDiv);
                for (var i = 0, len = rack.boxes.length; i < len; i++) {
                    var box = document.createElement("div");
                    box.className = "freezer-box";
                    box.id = rack.boxes[i].box_id;
                    box.innerHTML = "<span>" + format_box_name(rack.boxes[i].name) + "</span>";
                    rackDiv.appendChild(box);
                }

                if(rack.boxes.length == 0){
                    // new YAHOO.util.DDTarget(rackDiv);
                    YAHOO.example.DDApp.init();
                }
                else if (rack.boxes.length < (rack.num_columns * rack.num_rows)) {
                    YAHOO.util.Event.onContentReady(rack.boxes[rack.boxes.length - 1].box_id, YAHOO.example.DDApp.init());
                }
                else {
                    var rack2 = YAHOO.util.DDM.getDDById('rack2');
                    if (rack2) {;
                        rack2.lock();
                    }
                }
            }catch(e){
                writeError(e);
            }
        }
    }
    http.send();
}

function reorderBoxes(){
    var rack = document.getElementById('rack');
    var boxes = YAHOO.util.Dom.getElementsByClassName('freezer-box', 'div');
    var box_ids = new Array;
    var http  = make_xmlhttp();

    for(var i = 0 ; i < boxes.length ; i++){
        box_ids.push(boxes[i].id);
    }
    http.open('POST', viroverse.url_base + "/freezer/input/reorderBoxes/" + box_ids.join("/") ,true);
    http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
    http.onreadystatechange = function () {
        if (http.readyState == 4) {
        if(http.status == 500){
        writeError("Server Error");
        return;
        }
            if(http.responseText != 1){
            writeError("Unknown Error on Reordering","");
            }
        }
    }
    http.send();
}

function reorderRacks(){
    var rack_ctr = document.getElementById('freezer_racks');
    var rack_ids = new Array;
    var http  = make_xmlhttp();

    for(var i = 0 ; i < rack_ctr.rows.length ; i++){
        rack_ids.push(rack_ctr.rows.item(i).id);
    }
    http.open('POST', viroverse.url_base + "/freezer/input/reorderRacks/" + rack_ids.join("/") ,true);
    http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
    http.onreadystatechange = function () {
        if (http.readyState == 4) {
        if(http.status == 500){
        writeError("Server Error");
        return;
        }
            if(http.responseText != 1){
            writeError("Unknown Error on Reordering","");
            }
        }
    }
    http.send();
}

function placeVial(pos){
     var sel_aliquots = new Array;
     var Dom = YAHOO.util.Dom;
     var aliquots = document.getElementById('add_aliqs').getElementsByTagName("input");
     for( var i = 0 ; i < aliquots.length ; i++){
          if (aliquots.item(i).checked){
              sel_aliquots.push(aliquots.item(i).parentNode);
          }
     }
     var num_cells = pos.parentNode.cells.length;
     var num_rows = pos.parentNode.parentNode.rows.length;
     var table = document.getElementById('freezer_box');
     var histDiv = document.getElementById('placeHist');
     var c = pos.cellIndex;
     var http  = make_xmlhttp();
     var used_aliquots = new Array();
     var url_args = new Array();
     var box_loc = document.getElementById('freezer_id').options[document.getElementById('freezer_id').selectedIndex].text +"/" +
                     document.getElementById('rack_id').options[document.getElementById('rack_id').selectedIndex].text +"/" +
                     document.getElementById('box_id').options[document.getElementById('box_id').selectedIndex].text;
     walkTable : for(var r = pos.parentNode.sectionRowIndex ; r < num_rows ; r++){
          while(sel_aliquots.length > 0 && c < num_cells){
               var curCell = table.rows[r].cells[c];
               if(curCell.tagName.toLowerCase() == "th"){
                     c++;
                     continue;
               }
               if(Dom.hasClass(curCell, "empty")){
                    var a_label = sel_aliquots.shift();
                    var a = a_label.getElementsByTagName("input").item(0);
                    used_aliquots[a.value] = a;
                    var placed = a.value.split('_')
                    var sh = placed[0];
                    var id = placed[1];
                    curCell.innerHTML += a.nextSibling.data;
                    Dom.removeClass(curCell, "empty");
                    Dom.addClass(curCell, "occupied");
                    a_label.parentNode.removeChild(a_label);
                    var hist = document.createElement('div');
                    with(hist.style){
                          marginBottom = "5px";
                    }
                    var undo = document.createElement('a');
                    undo.innerHTML = "undo";
                    undo.className = 'clk';
                    undo.setAttribute("data-box_pos_id", curCell.id)
                    undo.addEventListener("click", function(){undoPos(this);}, false);
                    hist.innerHTML = a.nextSibling.data +  "<br /> Placed in  " + box_loc + "/" + curCell.getAttribute('data-name') + '&nbsp;&nbsp;';
                    hist.appendChild(undo);
                    histDiv.appendChild(hist);
                    url_args.push(sh + "_" + id + "_" + curCell.id);
                    c++;
               }else{
                    break walkTable;
               }

          }
          c = 0;//reset c to zero at end of row
     }
     http.open('POST', viroverse.url_base + "/freezer/input/addToBox/" + url_args.join("/"),true);
     http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
     http.onreadystatechange = function () {
          if (http.readyState == 4 && http.status == 200) {
               var resp = http.responseText.split("/");
               var errors = new Array;
               for(var i = 0 ; i < resp.length ; i++){
                    var r = resp[i].split("_");
                    if(r[4] != 1){ // if all is well nothing to do this just handles errors
                         var vial = used_aliquots[r[2] + "_" + r[3]];
                         document.getElementById("sidebar").appendChild(vial);
                         var cell = document.getElementById(r[0]);
                         if(r[4] == 0){ // space is not empty (could be occupied or reserved)
                              errors.push("Position " + r[1] + " Not Available");
                              cell.innerHTML = "<b>" + r[1] +"</b><br />Not Available Contents Unknown";
                              document.getElementById("sidebar").appendChild(vial);
                         }else if (r[4] == -1){  //vial not found in system this should never really happen
                              errors.push(r[2].charAt(0).toUpperCase() + r[2].slice(1) + " " + vial.innerHTML + " Not Found");
                              cell.innerHTML = "<b>" + r[1] +"</b><br />";
                              Dom.removeClass(cell, "occupied");
                         }else if (r[4] == -2){ //vial already in freezer
                              errors.push( r[2].charAt(0).toUpperCase() + r[2].slice(1) + " " + vial.innerHTML + " Is Already in the Freezer");
                              cell.innerHTML = "<b>" + r[1] +"</b><br />";
                              Dom.removeClass(cell, "occupied");
                         }else{ //don't know what happened, hopefully boomed and caught in log
                              errors.push("Unknown Error at Position " + r[1]);
                              cell.innerHTML = "<b>" + r[1] +"</b><br />";
                              document.getElementById("sidebar").appendChild(vial);
                              Dom.removeClass(cell, "occupied");
                         }
                    }
              }
              if(errors.length > 0){
               writeError(errors.join("<br />"), '');
              }
          }else if(http.status == 500){
              writeError("Server Error");
              return;
          }
     }
     http.send();
}

function undoPos(clicked){
     var box_pos_id = clicked.getAttribute('data-box_pos_id');
     var http  = make_xmlhttp();
     http.open('POST', viroverse.url_base + "/freezer/input/undoAdd/" + box_pos_id ,true);
     http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
     http.onreadystatechange = function () {
     if (http.readyState == 4) {
               var ret = evalJSON(http);
               var pos = document.getElementById(ret.box_pos.box_pos_id);
               if(pos){//if box not curently on page don't need to do
                    YAHOO.util.Dom.removeClass(pos, "occupied");
                    YAHOO.util.Dom.addClass(pos, "empty");
                    pos.innerHTML = "<b>" + ret.box_pos.pos + "</b>";
               }
               var histDiv = document.getElementById('placeHist');
               var aliq_l = document.createElement('label');
               var aliq = document.createElement('input');
               aliq_l.className = "aliq";
               aliq.type = 'checkbox';
               aliq.value = 'aliquot_' + ret.aliquot.aliquot_id;
               aliq.addEventListener("change", function (){highlight_cb(this);}, false);
               aliq_l.appendChild(aliq);
               aliq_l.appendChild(document.createTextNode(ret.aliquot.name))
               document.getElementById('add_aliqs').insertBefore(aliq_l, document.getElementById('check_all_link'));
               histDiv.removeChild(clicked.parentNode);
          }
     }
     http.send("");
}

function vialDetails(clicked, shorthand, id) {
    if (id == "") {
        return; //no id so nothing to do
    }
    var http = make_xmlhttp();
    if (id == "all") {
        var aliqs = clicked.parentNode.getElementsByTagName('p');
        var ids = new Array();
        for (var i = 0; i < aliqs.length; i++) {
            var arrId = aliqs.item(i).id.split("_");
            if (arrId[0] == 'aliquot')
                ids.push(arrId[1]);
        }
        id = ids.join("/");
    }
    var url = viroverse.url_base + "freezer/summary/aliquot_ajax/" + id;
    http.open('POST', url, true);
    http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
    http.onreadystatechange = function() {
        if (http.readyState == 4) {
            var aliquots = evalJSON(http);
            var remDisplay = "none";
            var addDisplay = "none";
            for (var i = 0; i < aliquots.length; i++) {
                if (aliquots[i].isInFreezer) {
                    remDisplay = "block";
                } else {
                    addDisplay = "block";
                }
            }
            document.getElementById('rem_ctr').style.display = remDisplay;
            document.getElementById('add_ctr').style.display = addDisplay;

            var aliquot;
            var fields = [
                'orphaned',
                'vol',
                'num_thaws',
                ['scientist_name_ac', 'possessing_scientist'],
                ['keys', 'aliquot_id'],
                ['units', 'units', 'innerHTML'],
            ].map(function(f){
                if ( !(f instanceof Array) )
                    f = [f, f]
                if (!f[2])
                    f[2] = "value"
                return f;
            });

            if (aliquots.length == 1) {
                aliquot = aliquots[0];
            } else if (aliquots.length > 1) {
                aliquot = {};
                fields.forEach(function(f) {
                    var values = Array.unique(aliquots.map(function(a){ return a[f[1]] }));
                    if (!values.length) {
                        aliquot[f[1]] = "";
                    } else if (values.length == 1) {
                        aliquot[f[1]] = values[0];
                    } else {
                        aliquot[f[1]] = "multiple";
                    }
                });

                // Always set aliquot_id to our multiple id string
                aliquot.aliquot_id = id;
            } else {
                return; //no aliquots nothing to do
            }

            fields.forEach(function(f){
                document.getElementById(f[0])[f[2]] = aliquot[f[1]];
            });

            initAliqCal();
            YAHOO.vv_freezer.container.manageVial.cfg.setProperty("context", [clicked, "tl", "bl"]);
            YAHOO.vv_freezer.container.manageVial.show();
        }
    }
    http.send();
}

function addFoundToFreezer(clicked){
    var aliqs = clicked.parentNode.getElementsByTagName('p');
    var ids = new Array();
    for(var i = 0 ; i < aliqs.length ; i++){
    ids.push(aliqs.item(i).id.split("_")[1]);
    }
    var http = make_xmlhttp();
    var url = viroverse.url_base + "freezer/search_freezers/addFoundToFreezer/" + ids.join("/");
    http.open('POST', url ,true);
    http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
    http.onreadystatechange = function () {
    if (http.readyState == 4) {
        var check = evalJSON(http);
        if (check == 1){
        window.location = viroverse.url_base + "freezer/input/add_to_box/";
        }
    }
    }
    http.send("");
}

function updateVials(){
    clearError();
    var form = document.getElementById('updateVial');
    var params = form2url(form).replace(/^[^?]*\?/,"");
    var http = make_xmlhttp();

    http.open('POST', viroverse.url_base + "/freezer/input/updateVials/", true);
    http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
    http.onreadystatechange = function () {
          if (http.readyState == 4) {
               var ret = evalJSON(http);
               if(ret == 1){
                    closeVialFrm();
                    if(document.getElementById("box_display")){ //if editing on box display need to reload results
                         var box_id = document.getElementById("box_id").value;
                         fetchBox(box_id);
                    }else{ //editing line in sidebar
                        reloadFreezerSidebar();
                    }
               }
    }
    }
    http.send(params);

}

function reloadFreezerSidebar(){
    asyncRequest(viroverse.url_base + "/sidebar/reload/freezer-sidebar.tt", '', null, function (o) {
        var sidebar = document.getElementById("sidebar");
        sidebar.innerHTML = o.responseText;
        evalScripts(sidebar);
    });
}

function closeVialFrm(){
    document.getElementById('orphaned').value = "";
    document.getElementById('vol').value = "";
    document.getElementById('num_thaws').value = ""
    document.getElementById('scientist_name_ac').value = "";
    document.getElementById('keys').value = "";
    document.getElementById('rem_ctr').checked = false;
    document.getElementById('add_ctr').checked = false;
    YAHOO.vv_freezer.container.manageVial.hide();
}

function initAliqCal(){
    var navConfig = {
    strings : {
        month: "Choose Month",
        year: "Enter Year",
        submit: "OK",
        cancel: "Cancel",
        invalidYear: "Please enter a valid year"
    },
    monthFormat: YAHOO.widget.Calendar.SHORT,
    initialFocus: "year"
    };

    YAHOO.vv_freezer.aliqCal = new YAHOO.widget.Calendar("aliqCal","aliqCalContainer", {title:"Choose a Date:", navigator:navConfig, close:true} );
    YAHOO.vv_freezer.aliqCal.selectEvent.subscribe(handeAliqDateSel, YAHOO.vv_freezer.aliqCal, true);
    YAHOO.vv_freezer.aliqCal.render();
    YAHOO.vv_freezer.aliqCal.hide();

    YAHOO.util.Event.addListener("orphaned", "focus", showAliqLostCal, YAHOO.vv_freezer.aliqCal, true);

}

function showAliqLostCal(){
    YAHOO.vv_freezer.dateField = document.getElementById('orphaned');
    YAHOO.vv_freezer.aliqCal.show();
    positionAliqCal();
}

function positionAliqCal(){
    var calCtr = document.getElementById('aliqCalContainer');
    var pos = YAHOO.util.Dom.getXY(YAHOO.vv_freezer.dateField);
    YAHOO.util.Dom.setXY(calCtr, pos);
    var foo = 'bar';

}

function handeAliqDateSel(type,args,obj){
    var year = args[0][0][0];
    var month = parseInt(args[0][0][1]) < 10 ? "0" + args[0][0][1] : args[0][0][1];
    var day = parseInt(args[0][0][2]) < 10 ? "0" + args[0][0][2] : args[0][0][2];
    YAHOO.vv_freezer.dateField.value = year + "-" + month + "-" + day;
    if(YAHOO.vv_freezer.dateField.id == "orphaned" ){
    document.getElementById("remove").checked = "checked";
    }
    YAHOO.vv_freezer.aliqCal.hide();
}

function deleteBoxCheck(box_id, name){
     YAHOO.vv_freezer.container.confirmDelete.setBody("Really Delete Box " + name + "?<br />This can not be undone!<br /><br />");
     viroverse.deleteBox = new Object;
     viroverse.deleteBox.name = name;
     viroverse.deleteBox.id = box_id;
     YAHOO.vv_freezer.container.confirmDelete.show();
}

function deleteBox(){
     YAHOO.vv_freezer.container.confirmDelete.hide();
     var http  = make_xmlhttp();
     var url = viroverse.url_base + "freezer/input/deleteBox/" + viroverse.deleteBox.id;
     http.open('POST', url ,true);
     http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
     http.onreadystatechange = function () {
          if (http.readyState == 4) {
               var ret = evalJSON(http);
               if(ret == 1){
                    var rackBox = document.getElementById(viroverse.deleteBox.id);
                    rackBox.parentNode.removeChild(rackBox);
                    document.getElementById("box_display").innerHTML = "";
               }
          }
     }
     http.send("");
}

function asyncRequest(sURL, sData, oArg, fnSuccess) {
    YAHOO.util.Connect.asyncRequest(
        'POST',
        sURL,
        {
            success: fnSuccess,
            failure: function(o) {
                writeError("Server Error");
                return -1;
            },
            argument: oArg
        },
        sData
    );
}

function add_vials() {
    clearError();
    var arrVials = YAHOO.viroverse.oTreeble.getChecked();
    if (arrVials.length) {
        var nCt = 0;
        for (var i = arrVials.length - 1; i >= 0; i--) {
            if (!isNumber(arrVials[i]) || arrVials[i] < 0) {
                arrVials.splice(i, 1);
                nCt++;
            }
        }
        if (nCt) {
            writeError('Cannot add ' + nCt + ' unknown item' + (nCt > 1 ? 's' : '') + '.');
        }
        if (arrVials.length > 0)
            sidebar_add('found_aliquots', arrVials, null, []);
    }
}
