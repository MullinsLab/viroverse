
/**
 * @class
 * @scope public
 */
function RemoteSuggestions(whichType) {

    if (typeof XMLHttpRequest != "undefined") {
        this.http = new XMLHttpRequest();
    } else if (typeof ActiveXObject != "undefined") {
        this.http = new ActiveXObject("MSXML2.XmlHttp");
    } else {
        alert("No XMLHttpRequest object available. This functionality will not work.");
    }

    this.kind = whichType;

    this.suggestionTypes = {
        patient: function (oHttp, oAutoSuggestControl /*:AutoSuggestControl*/, bTypeAhead /*:boolean*/) {

            var cohort = document.getElementById("cohort");
            var coId = cohort.value;
            log = document.getElementById('log');              
             
             //build the URL
             var sURL = url_base + "/enum/patients/" + coId + "/" + encodeURIComponent(oAutoSuggestControl.textbox.value);
             //entry = log.appendChild(document.createElement('p'));
             //entry.appendChild(document.createTextNode(Date.now() + ' ' + sURL));
             //open connection to states.txt file
             oHttp.open("get", sURL , true);
             oHttp.onreadystatechange = function () {
                  if (oHttp.readyState == 4) {
                        //evaluate the returned text JavaScript (an array)
                        eval(oHttp.responseText);
                        var taSuggestions = json_result;

                 /*     if(aSuggestions.length > 0) {
                            aSuggestions.splice(0, aSuggestions.length);
                        }*/

                    var aSuggestions_temp = new Array();
                    var aSuggestionsAsoc_temp = new Array();
                    for (var i in json_result) {
                        aSuggestions_temp.push(json_result[i].external_patient_id);
                        aSuggestionsAsoc_temp[json_result[i].external_patient_id] = json_result[i].patient_id;
                    }

                    aSuggestions = aSuggestions_temp.sort();
                    aSuggestionsAsoc = aSuggestionsAsoc_temp;
                  
                        //provide suggestions to the control
                        oAutoSuggestControl.autosuggest(aSuggestions, bTypeAhead);        
                  }    
             };
             oHttp.send(null);
        },
        primer: function (oHttp, oAutoSuggestControl /*:AutoSuggestControl*/, bTypeAhead /*:boolean*/) {
         //build the URL
            var sURL = url_base + "/enum/primers/" + oAutoSuggestControl.textbox.value;
         
         oHttp.open("get", sURL, true);
         oHttp.onreadystatechange = function () {
              if (oHttp.readyState == 4) {
                    var aSuggestions= new Array();
                    //evaluate the returned text as JavaScript (should define json_result)
                    eval(oHttp.responseText);
                    for (var i in json_result) {
                        to_display = json_result[i].name;
                        if (json_result[i].lab_common) {
                            to_display = "<strong>" + to_display + "</strong>";
                        }
                        aSuggestions.push(to_display);
                    }
                    aSuggestions.sort();
                    oAutoSuggestControl.autosuggest(aSuggestions, bTypeAhead);        
              }    
         };
         oHttp.send(null);

        },
        scientist: function (oHttp, oAutoSuggestControl /*:AutoSuggestControl*/, bTypeAhead /*:boolean*/) {

         //build the URL
            var sURL = url_base + "/enum/scientists/" + oAutoSuggestControl.textbox.value;
         
         oHttp.open("get", sURL, true);
         oHttp.onreadystatechange = function () {
              if (oHttp.readyState == 4) {
                    var aSuggestions= new Array();
                    //evaluate the returned text as JavaScript (should define json_result)
                    eval(oHttp.responseText);
                    for (var i in json_result) {
                        aSuggestions.push(json_result[i].name);
                    }
                    aSuggestions.sort();
                    oAutoSuggestControl.autosuggest(aSuggestions, bTypeAhead);        
              }    
         };
         oHttp.send(null);

        },
        pept_name: function (oHttp, oAutoSuggestControl /*:AutoSuggestControl*/, bTypeAhead /*:boolean*/) {
         //build the URL
            var sURL = viroverse.url_base + "/enum/pept_names/" + oAutoSuggestControl.textbox.value;
         
         oHttp.open("get", sURL, true);
         oHttp.onreadystatechange = function () {
              if (oHttp.readyState == 4) {
                    var aSuggestions= new Array();
                    //evaluate the returned text as JavaScript (should define json_result)
                    eval(oHttp.responseText);
                    for (var i in json_result) {
                        to_display = json_result[i].name;
                        aSuggestions.push(to_display);
                    }
                    aSuggestions.sort();
                    oAutoSuggestControl.autosuggest(aSuggestions, bTypeAhead);        
              }    
         };
         oHttp.send(null);

        },
        pept_seq: function (oHttp, oAutoSuggestControl /*:AutoSuggestControl*/, bTypeAhead /*:boolean*/) {
         //build the URL
            var sURL = viroverse.url_base + "/enum/pept_seqs/" + oAutoSuggestControl.textbox.value;
         
         oHttp.open("get", sURL, true);
         oHttp.onreadystatechange = function () {
              if (oHttp.readyState == 4) {
                    var aSuggestions= new Array();
                    //evaluate the returned text as JavaScript (should define json_result)
                    eval(oHttp.responseText);
                    for (var i in json_result) {
                        to_display = json_result[i].sequence;
                        aSuggestions.push(to_display);
                    }
                    aSuggestions.sort();
                    oAutoSuggestControl.autosuggest(aSuggestions, bTypeAhead);        
              }    
         };
         oHttp.send(null);

        },
        pool_name: function (oHttp, oAutoSuggestControl /*:AutoSuggestControl*/, bTypeAhead /*:boolean*/) {
         //build the URL
            var sURL = viroverse.url_base + "/enum/pool_names/" + oAutoSuggestControl.textbox.value;
         
         oHttp.open("get", sURL, true);
         oHttp.onreadystatechange = function () {
              if (oHttp.readyState == 4) {
                    var aSuggestions= new Array();
                    //evaluate the returned text as JavaScript (should define json_result)
                    eval(oHttp.responseText);
                    for (var i in json_result) {
                        to_display = json_result[i].name;
                        aSuggestions.push(to_display);
                    }
                    aSuggestions.sort();
                    oAutoSuggestControl.autosuggest(aSuggestions, bTypeAhead);        
              }    
         };
         oHttp.send(null);

        },
    }
}

function RemotePoolSuggestions() {

    if (typeof XMLHttpRequest != "undefined") {
        this.http = new XMLHttpRequest();
    } else if (typeof ActiveXObject != "undefined") {
        this.http = new ActiveXObject("MSXML2.XmlHttp");
    } else {
        alert("No XMLHttpRequest object available. This functionality will not work.");
    }

}

RemoteSuggestions.prototype.requestSuggestions = function (oAutoSuggestControl /*:AutoSuggestControl*/, bTypeAhead /*:boolean*/) {

    //if there is already a live request, cancel it
    if (this.http.readyState != 0) {
            // this freaks out the catalyst built-in test http server, haven't verified with apache
        //oHttp.abort(); 
        //alert("abortion is wrong!");
    }

    this.suggestionTypes[this.kind](this.http, oAutoSuggestControl, bTypeAhead )

}


/**
 * Request suggestions for the given autosuggest control. 
 * @scope protected
 * @param oAutoSuggestControl The autosuggest control to provide suggestions for.
 */
aSuggestions = new Array();
aSuggestionsAsoc = new Array();
aSample = new Array();


