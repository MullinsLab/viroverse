RemoteStateSuggestions.prototype.requestScientists = function () {

    var oHttp = this.http;
                                                             
    //if there is already a live request, cancel it
    if (oHttp.readyState != 0) {
        //oHttp.abort();
            //alert("abortion is wrong!");
    }                 
    
    var sci_field = document.getElementById("patient");
    var patient_id = aSuggestionsAsoc[patient.value];
    
    //build the URL
       var sURL = "/enum/scientist/" + sci_field.value;
    
    //open connection to states.txt file
    oHttp.open("get", sURL, true);
    oHttp.onreadystatechange = function () {
        if (oHttp.readyState == 4) {
                var aSuggestions= new Array();
            //evaluate the returned text as JavaScript (should define json_result)
                eval(oHttp.responseText);
                for (var i in json_result) {
                    aSuggestions.push(json_result[i].EXTERNAL_PATIENT_ID);
                }
            oAutoSuggestControl.autosuggest(aSuggestions, bTypeAhead);        
        }    
    };
    oHttp.send(null);

};

