function noenter(event) {
    if(event && event.which == 13) {
        getSamples(); 
        return false;
    }
}

function getSelectedCheckbox(buttonGroup) {
   // Go through all the check boxes. return an array of all the ones
   // that are selected (their position numbers). if no boxes were checked,
   // returned array will be empty (length will be zero)
   var retArr = new Array();
   var lastElement = 0;
   if (buttonGroup[0]) { // if the button group is an array (one check box is not an array)
      for (var i=0; i<buttonGroup.length; i++) {
         if (buttonGroup[i].checked) {
            retArr[lastElement] = i;
            lastElement++;
         }
      }
   } else { // There is only one check box (it's not an array)
      if (buttonGroup.checked) { // if the one check box is checked
         retArr.length = lastElement;
         retArr[lastElement] = 0; // return zero as the only array value
      }
   }
   return retArr;
} // Ends the "getSelectedCheckbox" function

function getSelectedCheckboxValue(buttonGroup) {
   // return an array of values selected in the check box group. if no boxes
   // were checked, returned array will be empty (length will be zero)
   var retArr = new Array(); // set up empty array for the return values
   var selectedItems = getSelectedCheckbox(buttonGroup);
   if (selectedItems.length != 0) { // if there was something selected
      for (var i=0; i<selectedItems.length; i++) {
          retArr[i] = new Array(2);
         if (buttonGroup[selectedItems[i]]) { 
            retArr[i][0] = buttonGroup[selectedItems[i]].value; //sample id
            retArr[i][1] = buttonGroup[selectedItems[i]].innerHTML; // sample.to_string
            } else {
            retArr[i][0] = buttonGroup.value; //sample id
            retArr[i][1] = buttonGroup.innerHTML; // sample.to_string
            }
      }
   }
   return retArr;
} // Ends the "getSelectedCheckBoxValue" function

function addExtraction() {
    if (document.extraction_build.samplebox) {
        var checkBoxArr = getSelectedCheckboxValue(document.extraction_build.samplebox);
        if (checkBoxArr.length == 0) { 
            alert("No check boxes selected"); 
        }else {
            showExtractedSamples(checkBoxArr);
        }
    }else {alert("No check box");}
}

function deleteSample(delSample) {
    var toDelete = document.getElementById(delSample);
//    if (!document.samples.sampleArr.length) {    // for the case that there is only one sample in sampleList
//        var removedNode = sampleDiv.removeChild(document.getElementById(delSample));
//        document.samples.sampleArr = null;
//        alert("no length?");
//    }else {
    toDelete.parentNode.removeChild(toDelete);
}

function showExtractedSamples(checkBoxArr) {
    var sampleTable = document.getElementById("extractionList");

    for (var i = 0; i < checkBoxArr.length; i++) {
        newTR = sampleTable.insertRow(-1);
        newTR.id = checkBoxArr[i][0];

        var delDiv = document.createElement("th");

        var alink = document.createElement("a");
        alink.setAttribute("href", "#");
        alink.setAttribute("onclick", "deleteSample("+checkBoxArr[i][0]+")");
        alink.appendChild(document.createTextNode("del"));
        delDiv.appendChild(alink);

        var ext_id = Date.now();
        var input = document.createElement("input");
        input.setAttribute("type", "hidden");
        input.setAttribute("name", "extraction_unique");
        input.setAttribute("value", ext_id);
        delDiv.appendChild(input);

        var input = document.createElement("input");
        input.setAttribute("type", "hidden");
        input.setAttribute("name", ext_id + "_extracted_samples");
        delDiv.appendChild(input);
        input.setAttribute("value", checkBoxArr[i][0]);
        var newTD = document.createElement("td");
        newTD.appendChild(document.createTextNode( checkBoxArr[i][1] ));
        newTR.appendChild(delDiv);
        newTR.appendChild(newTD);

        for (var element_i = 0 ; element_i < document.extraction_build.elements.length; element_i++) {
            var element  = document.extraction_build.elements[ element_i ];
            if (element.name == 'samplebox') { //handled by checkBox functions
                continue;
            }
            var input = document.createElement("input");
            input.setAttribute("type", "hidden");
            input.setAttribute("name", ext_id + '_' + element.name);
            input.setAttribute("value", element.value);
            delDiv.appendChild(input);
            var newTD = document.createElement("td");
            newTD.appendChild( document.createTextNode( element.value ) );
            newTR.appendChild(newTD);

        }


        // delDiv.appendChild(document.createTextNode(checkBoxArr[i][1]));
    }

    var sidebar = document.getElementById('extractions_form');

    if (! document.getElementById('sideSpanButton') ) {
        var spanButton = document.createElement("span");
        spanButton.setAttribute("class", "formbutton");
        spanButton.setAttribute("id", "sideSpanButton");
        var submitButton = document.createElement("input");
        submitButton.setAttribute("type", "submit");
        submitButton.setAttribute("value", "Submit");
        submitButton.setAttribute("id", "sampleSubmit");
    // submitButton.setAttribute("onclick", "gotoExtraction()");
        spanButton.appendChild(submitButton);
        sidebar.appendChild(spanButton);
    }
}

function transSample() {
    var sampleObj = document.getElementById('sampleList');

        if (sampleObj.rows < 1) {
            alert("There is only one sample selected. value: "+sampleObj.value);
        }else {
            for (var i = 0; i < sampleObj.rows; i++) {
                alert("Sample "+i+": "+sampleObj[i].value);
            }
        }
}

function newPatient (newId) {
    viroverse.updatePatientInput.value = newId;
}
