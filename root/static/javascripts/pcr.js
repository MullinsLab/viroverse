//requires suggestion-primer.js to create primerDataSource
viroverse.pcrRounds = new Array(); //global variable to track primer counts, etc between rounds
function pcr_init (firstRoundDivId,primerIds,primerDivId) {
    var first = document.getElementById(firstRoundDivId)

    //mock up object to work with later js
    var firstObj = new Object;
    firstObj.html = first
    firstObj.rank = 1
    firstObj.myParent = first.parentNode
    firstObj.addPrimer = pcrRound.prototype.addPrimer;
    firstObj.delPrimer = pcrRound.prototype.delPrimer;
    firstObj.primerDiv = document.getElementById(primerDivId);

    firstObj.primers = new Array;

    for (var i=0; i < primerIds.length; i++) {
        firstObj.primers.push(new YAHOO.widget.AutoComplete(primerIds[i],primerIds[i]+'result',viroverse.primerDataSource));
    }

    viroverse.pcrRounds[1] = firstObj;
}

function pcrRound (parentDiv,prevRound,button,dataSource) {
    this.myParent = parentDiv;
    var multiplex;
    var multiplexElem = document.getElementById('multiplex');
    /* Switching between multiplex and non-multiplex rounds while setting
     * up a reaction doesn't make any sense and can't be handled by the backend,
     * so prevent it a little bit. This doesn't persist when the form is
     * reloaded on submission but this is just a mild best-effort improvement;
     * I'm not going to spelunk further into the Old Javascript at this time.
     * -- silby@ 2019-04-11
     */
    if (multiplexElem != null) {
        multiplex = multiplexElem.checked;
        multiplexElem.disabled = true;
    }
    if (multiplex) {
        lastRank = prevRound.rank;
        this.rank = lastRank + 1 + (.1 * (viroverse.pcrRounds.length - lastRank )); //only works for first round multiplex!
        this.roundsIndex = viroverse.pcrRounds.push(this) - 1;
    } else {
        this.rank = prevRound.rank +1;
        this.roundsIndex = viroverse.pcrRounds.push(this) - 1;
    }
    this.primers = new Array;

    this.html = prevRound.html.cloneNode(true);

    var legend = this.html.getElementsByTagName("legend").item(0)
    legend.innerHTML = "Round "+this.rank+" ";

    desc = this.html.getElementsByTagName("*");
    for (var i=0; i<desc.length; i++) {
        if (desc.item(i).name) {
            var oldname = desc.item(i).name;
            desc.item(i).name = oldname.replace("round_"+(prevRound.rank),"round_"+this.rank)
        }
        if (desc.item(i).id) {
            var oldid = desc.item(i).id;
            desc.item(i).id = oldid.replace("round_"+(prevRound.rank),"round_"+this.rank)
        }
    }

    parentDiv.appendChild(this.html);

    //round add button
    if (!multiplex) {
        var theRank = this.rank
        button.onclick = function (click) { addRound(button,theRank) }
        legend.appendChild(button.parentNode.removeChild(button));
    }

    //remove multiplex from rounds >1
    if (document.getElementById('pcr_round_'+this.rank+'_multiplex') ) {
        deleteThis(document.getElementById('pcr_round_'+this.rank+'_multiplex'));
    }

    //primers
    document.getElementById("pcr_round_"+this.rank+"_notes").value = '';
    document.getElementById("count_round_"+this.rank).value = this.rank;
    var primerPlus = document.getElementById('addprimer_round_'+this.rank+'p');
    var primerMinus = document.getElementById('addprimer_round_'+this.rank+'m');
    var count = this.roundsIndex;
    primerPlus.onclick = function (click) { viroverse.pcrRounds[count].newPrimer(click.target) }
    primerMinus.onclick = function (click) { viroverse.pcrRounds[count].removePrimer(click.target) }
    var buttonParent = primerPlus.parentNode.parentNode.removeChild(primerPlus.parentNode);
    this.primerDiv = document.getElementById('round_'+this.rank+'_primers');
    removeChildNodes(this.primerDiv);

    var lastPrimerDiv;

    //alert("there were "+viroverse.pcrRounds[this.rank-2].primers.length+" primers last time in "+(this.rank-2));
    for (var i=0; i < viroverse.pcrRounds[prevRound.rank].primers.length ;i++) {
        lastPrimerDiv = this.addPrimer(primerPlus)
    }
    if (lastPrimerDiv) {
        lastPrimerDiv.appendChild( buttonParent );
    }

    //TODO: finish, test
}

pcrRound.prototype.addPrimer = function () {
    var primerNu = this.primers.length + 1
    var unique = "pcr_round_" + this.rank + "_primer_" + (primerNu)

    var newLabel = document.createElement("label");
    newLabel.appendChild( document.createTextNode("Primer " + (primerNu)) );
    var formSpan = document.createElement("span");
    formSpan.setAttribute("class","formw");
    var input = document.createElement("input");
    input.setAttribute("type","text");
    input.setAttribute("name", unique);
    input.setAttribute("id",unique );
    input.setAttribute("size","40");
    input.setAttribute("class","auto");
    formSpan.appendChild(input);
    var resultDiv = document.createElement('div');
    resultDiv.className = 'primer_auto y_auto formw';
    resultDiv.id = unique + 'result'
    var aDiv = document.createElement("div");
    aDiv.appendChild(newLabel);
    aDiv.appendChild(formSpan);
    aDiv.appendChild(resultDiv);
    this.primerDiv.appendChild(aDiv);

    this.primers.push(new YAHOO.widget.AutoComplete(unique,resultDiv.id,viroverse.primerDataSource) );
    return(aDiv);
}

pcrRound.prototype.delPrimer = function () {
    //var kids = this.primerDiv.childNodes;
    //alert(this.primers.length)
    if (this.primers.length > 1) {
        this.primerDiv.removeChild(this.primerDiv.lastChild); //primer
        this.primers.pop();
        //todo: delete?
    }

    return this.primerDiv.lastChild;
}

pcrRound.prototype.remove = function () {
    //not actually supported
}

function pcr_add_template(product_type,product_id,product_text,arg_array) {
    var put_it_id = arg_array[0];
    var form_id = arg_array[1];
    var error_id = arg_array[2];
    var findr = arg_array[3];
    targetSelect = document.getElementById(put_it_id);

    var opt = document.createElement('option');
    opt.setAttribute('value',product_type.replace(/\.[rd]na$/i, '') + 'box' + product_id);
    opt.innerHTML = product_text ;
    targetSelect.appendChild(opt);

    build_form = document.getElementById(form_id);
    setFormDisable(build_form,false);

    document.getElementById(error_id).style.display = 'none';

    validate_product(product_type, product_id, opt.value, arg_array);
    sidebar_add(product_type, product_id,"pcr",["pcr"]);
}

function validate_product(product_type, product_id, opt_value, arg_array) {
    var select_id = arg_array[0],
        error_id  = arg_array[2];

    if (product_type === 'extraction') {
        load_url_ajax(
            viroverse.url_base + 'enum/fetch_generic/' + product_type + '/' + encodeURIComponent(product_id),
            function(json) {
                var extraction = evalJSON_response(json)[0];
                if (extraction === null || extraction.extract_type !== 'RNA') {
                    return;
                }
                else if (extraction.has_rt_products) {
                    writeError("You can't perform PCR on an RNA extraction. "
                             + "You should use the existing cDNA product instead, or create new cDNA first.");
                }
                else {
                    writeError("You can't perform PCR on an RNA extraction. "
                             + "You should create cDNA first and then use it instead.");
                }
            },
            error_id
        );
    }
}

function pcr_add_template_reamp(product_type,product_id,product_text,arg_array) {
    var put_it_id = arg_array[0];
    var form_id = arg_array[1];
    var error_id = arg_array[2];
    targetSelect = document.getElementById(put_it_id);

    var opt = document.createElement('option');
    opt.setAttribute('value',product_type.replace(/\.[rd]na$/i, '') + 'box' + product_id);
    opt.innerHTML = product_text ;
    targetSelect.appendChild(opt);
    //targetSelect.selectedIndex = targetSelect.length -1 ;
    opt.setAttribute('selected',true);
    //opt.onclick = function () { addDilutionBox(put_it_id,opt.index) }

    build_form = document.getElementById(form_id);
    setFormDisable(build_form,false);

    document.getElementById(error_id).style.display = 'none';

}


function addRound(button,prevIndex) {
    var prevRound = viroverse.pcrRounds[prevIndex];
    var parentDiv = prevRound.myParent;
    new pcrRound (parentDiv,prevRound,button,viroverse.primerDataSource);
}

pcrRound.prototype.newPrimer = function (button) {
    var buttonSpan = button.parentNode.parentNode.removeChild(button.parentNode); //remove button span and hold onto reference
    newDiv = this.addPrimer(button);
    newDiv.appendChild(buttonSpan);
}

//deprecated
function addRoundPrimer(button,roundNu) {
    var buttonSpan = button.parentNode.parentNode.removeChild(button.parentNode); //remove button span and hold onto reference
    newPrimerDiv = viroverse.pcrRounds[roundNu].addPrimer(button);
    newPrimerDiv.appendChild(buttonSpan)
}

pcrRound.prototype.removePrimer = function (button) {
    var buttonSpan = button.parentNode.parentNode.removeChild(button.parentNode); //remove button span and hold onto reference
    lastPrimerDiv = this.delPrimer(button);
    //alert(lastPrimerDiv.nodeName)
    lastPrimerDiv.appendChild(buttonSpan)
}
//deprecated
function delRoundPrimer(button,roundNu) {
    var buttonSpan = button.parentNode.parentNode.removeChild(button.parentNode); //remove button span and hold onto reference
    lastPrimerDiv = viroverse.pcrRounds[roundNu].delPrimer(button);
    //alert(lastPrimerDiv.nodeName)
    lastPrimerDiv.appendChild(buttonSpan)

}


function addPrimer(button) {
    var parentDiv = button.parentNode.parentNode.parentNode; // this should be the primergroup div
    var roundDiv = parentDiv.parentNode;
    var roundNo = roundDiv.id.substr(5)

    var newLabel = document.createElement("label");
    newLabel.appendChild( document.createTextNode("Primer " + (parentDiv.getElementsByTagName("div").length +1)) );


    var formSpan = document.createElement("span");
    formSpan.setAttribute("class","formw");
    var input = document.createElement("input");
    input.setAttribute("type","text");
    //    parentDiv.getElementsByTagName("div")
    unique = "pcr_round_" + roundNo + "_primer_" + (parentDiv.getElementsByTagName("div").length)
    input.setAttribute("name", unique);
    input.setAttribute("id",unique );
    input.setAttribute("size","40");
    input.setAttribute("class","auto");
    formSpan.appendChild(input);

    var resultDiv = document.createElement('div');
    resultDiv.className = 'primer_auto y_auto formw';
    resultDiv.id = unique + 'result'

    var aDiv = document.createElement("div");
    aDiv.appendChild(newLabel);
    aDiv.appendChild(formSpan);
    aDiv.appendChild(buttonSpan);
    parentDiv.appendChild(aDiv);
    parentDiv.appendChild(resultDiv);
    abr = document.createElement('br');
    abr.setAttribute('clear','all');
    parentDiv.appendChild(abr);
    //new AutoSuggestControl(document.getElementById(unique), new RemoteSuggestions("primer"));
    new YAHOO.widget.AutoComplete(unique,resultDiv.id,viroverse.primerDataSource);
}

function removePrimer(button) {
    var primerDiv = button.parentNode.parentNode;
    var buttonSpan = primerDiv.removeChild(button.parentNode); //remove button span and hold onto reference
    var divs = primerDiv.parentNode.getElementsByTagName("div")
    primerDiv.parentNode.removeChild(primerDiv);
    divs.item(divs.length -1).appendChild(buttonSpan);
}

function toggleMultiplex(checkbox) {
    controlSpan = checkbox.parentNode.getElementsByTagName('span').item(0);
    if (checkbox.checked == true) {
        controlSpan.style.visibility = 'visible';
    } else {
        controlSpan.style.visibility = 'hidden';
    }
}

function addDilutionBox (selectID,volID,replID, dilCtnrId) {
    var volNode = document.getElementById(volID);
    var replNode = document.getElementById(replID);

    var e = 0;
    if (!volNode.value) {
        var va = new YAHOO.util.ColorAnim(volID,{backgroundColor: {from:'#FF1111', to: '#FFF'} },1);
        va.animate();
        e++;
    } 

    // both 0 and NaN are falsey, so we can ensure positive integers
    var repl = parseInt(replNode.value, 10);
    if (!repl) {
        var ra = new YAHOO.util.ColorAnim(replID,{backgroundColor: {from:'#FF1111', to: '#FFF'} },1);
        ra.animate();
        e++;
    } else {
        replNode.value = repl; // normalize to int
    }

    if (e) {
        return;
    }

    var selectNode = document.getElementById(selectID);
    var selectedNodes = new Array; 
    for (var oi = 0; oi < selectNode.options.length;oi++) {
        var o = selectNode.options[oi]
        if (o.selected) {
            selectedNodes.push(o);
        }
    }

    for (var si=0;si<selectedNodes.length;si++) {
        var selectedNode = selectedNodes[si];
        var dil = document.createElement('div');
        dil.className = 'pcrRound';
        var prevDils = document.getElementById(selectedNode.value+"div")
        var prevDilsHolder;

        if (prevDils) {
            dilcount = prevDils.getElementsByTagName('div').length + 1
        } else {
            dilcount = 1
            prevDilsHolder = document.createElement('div');
            prevDils = document.createElement('div')
            prevDils.setAttribute('id',selectedNode.value+"div");
            head = document.createElement('h3')
            head.appendChild(document.createTextNode(selectedNode.text))
            prevDils.appendChild(head)
            prevDilsHolder.appendChild(prevDils);
            document.getElementById(dilCtnrId).appendChild(prevDilsHolder);
        }

        var b = document.createElement('a')
        b.setAttribute('href','#');
        b.innerHTML = 'del';
        b.onclick = function () { return delDilutionBox(this.parentNode) }
        dil.appendChild(b)

        var inpvol = document.createElement('input');
        inpvol.setAttribute("type","hidden")
        inpvol.setAttribute("value",volNode.value)
        inpvol.setAttribute("name",selectedNode.value+'vol'+dilcount);

        dil.appendChild(inpvol)

        var inpunit = document.createElement('input')
        inpunit.setAttribute('type','hidden')
        inpunit.setAttribute('name',selectedNode.value+'unit'+dilcount);
        inpunit.setAttribute('value','ul');

        dil.appendChild(inpunit)

        var inp = document.createElement('input');
        inp.setAttribute("type","hidden")
        inp.setAttribute("value",replNode.value)
        inp.className = 'check_r'
        inp.setAttribute("name",selectedNode.value+'repl'+dilcount);

        dil.appendChild(inp)

        desc = document.createElement('span');
        desc.innerHTML = volNode.value+" &mu;L x"+replNode.value;

        dil.appendChild(desc);

        prevDils.appendChild(dil)
    }
}

//removes the box and renames any subsequent inputs
function delDilutionBox (theBox) {

    var dome = theBox
    var input_name_match = /(\d+)$/;


    var sib = dome.nextSibling
    while (sib != null) {
        var inputs = sib.getElementsByTagName('input');
        for (i=0; i<inputs.length; i++) {
            var match_Res = input_name_match(inputs[i].name);
            if (match_Res != null) {
                inputs[i].setAttribute('name',inputs[i].name.substring(0,match_Res.index) + (parseInt(match_Res[0]) - 1 ) )
            }
        }
        sib = sib.nextSibling
    }

    deleteThis(theBox)

    return false;
}

function empty_templates(templatebox_id,findr) {
    var t = document.getElementById(templatebox_id) 
    if (t) {
        t.innerHTML = '';
        sidebar_clear_type("rt","pcr");
        sidebar_clear_type("extraction","pcr");
        sidebar_clear_type("bisulfite_converted_dna","pcr");
        findr.clear_added_things();
    }

    return false;
}

function templateSelClickHandler(sel,findr){
    show_copy_number(sel, 'copy_num_res');
    show_concentration(sel,'concentration',findr);
}

function show_concentration (selected_template,el_id,findr) {
    var d = document.getElementById(el_id);
    var info = findr.added_things[selected_template.selectedIndex];
    var c = info.concentration
    if (!c) {
        d.style.display = 'none';
    } else {
        d.style.display = 'inline';
        var i = d.getElementsByTagName('input').item(0);
        i.value = c;
        i.focus();
        i.select();
    }
}

function mass_change (mass_id,vol_id,templ_select_id,findr) {
    var m_input = document.getElementById(mass_id);
    var v_input = document.getElementById(vol_id);
    var t_select = document.getElementById(templ_select_id);

    var c = findr.added_things[t_select.selectedIndex].concentration ; 
    if (c && m_input.value ) {
        v_input.value = (m_input.value / c).toFixed(2) ;
    } 
}


function clear_pcr_sidebar () {
    div_load_ajax(viroverse.url_base + '/sidebar/pcr_clear/','sidebar');
    return false;
}

function clear_pcr_more_sidebar () {
    div_load_ajax(viroverse.url_base + '/sidebar/pcr_more_clear/','sidebar');
    return false;
}
