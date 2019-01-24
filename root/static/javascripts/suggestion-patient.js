//suggestion code to use Y!UI
//uses yahoo-dom-event, connection-min, and autocomplete-min

YAHOO.namespace("viroverse");
viroverse.patientDataSchema = {resultsList: 'Response',fields: ['external_patient_id','patient_id']};
viroverse.patientDataSource = new YAHOO.util.XHRDataSource(viroverse.url_base + "enum/patients_y/");
viroverse.patientDataSource.responseSchema = viroverse.patientDataSchema;
viroverse.patientDataSource.responseType = YAHOO.util.DataSource.TYPE_JSON;
YAHOO.widget.AutoComplete.prototype.formatResult = function (aResultItem, sQuery) {
    return aResultItem[0];
}

// callbacks for enabling/disabling submit button on bare patient finders

function registerPatientInput(input_id, container_id, cohort_id) {
    function submitEnable() {
        viroverse.patientSubmitButton.disabled = false;
    }

    function submitDisable() {
        viroverse.patientSubmitButton.disabled = true;
    }
    YAHOO.util.Event.onAvailable(
        container_id,
        function() {
            if (!document.getElementById(input_id) || !document.getElementById(cohort_id))
                return;

            /* If submitting this form requires a specific patient ID to be 
             * selected, trigger client-side validation
             */
            if (document.getElementById(input_id).required) {
                viroverse.patientSubmitButton = document.querySelector("#" + input_id)
                    .form.querySelector("input[type=submit], input[type=button]");
            }

            YAHOO.viroverse.patAutocomplete = new YAHOO.widget.AutoComplete(
                input_id,
                container_id,
                viroverse.patientDataSource
            );
            if (viroverse.patientSubmitButton) {
                submitDisable();
                YAHOO.viroverse.patAutocomplete.itemSelectEvent.subscribe(submitEnable);
                YAHOO.viroverse.patAutocomplete.selectionEnforceEvent.subscribe(submitDisable);
            }
            YAHOO.viroverse.patAutocomplete.itemSelectEvent.subscribe(viroverse.onPatSelect_f);
            YAHOO.viroverse.patAutocomplete.containerExpandEvent.subscribe(viroverse.onPatExpand_f);
            YAHOO.viroverse.patAutocomplete.selectionEnforceEvent.subscribe(viroverse.onPatEnforceSelection);
            YAHOO.viroverse.patAutocomplete.forceSelection = true;

            var cohort = document.getElementById(cohort_id);
            if (cohort.selectedIndex < 1) { // if not selected or blank option selected hide patient_id box
                document.getElementById(input_id).parentNode.style.display = 'none';
                cohort.selectedIndex = 0;
            } else {                        // set autosuggest datasource for defeult cohort
                viroverse.patientDataSource.scriptQueryAppend = 'cohort='+cohort.value;
            }
            cohort.onchange = function() {
                var inp = document.getElementById(input_id);
                var parent = inp.parentNode;
                var cohort = this;
                parent.style.display = 'block';

                viroverse.patientDataSource.scriptQueryAppend = 'cohort='+cohort.value;

                if (viroverse.patientSubmitButton) {
                    submitDisable();
                }
                inp.value='';
                inp.focus();
            };
        }
    );
}

//var viroverse.ajax_patient_id; //gets the real patient id when an alias is selected (don't need to declare when an object property)

//holds fn reference for when patient is clicked to look up just patient_id instead of cohort/patient
viroverse.onPatSelect_f = function (sType,aArgs) { 
    viroverse.ajax_patient_id = aArgs[2][1]
    if (viroverse.onNewPatientid) {
        viroverse.onNewPatientid(viroverse.ajax_patient_id);
    }
} 

viroverse.onPatExpand_f = function () {};
viroverse.onPatEnforceSelection = function() {
    if (viroverse.onInvalidPatient) {
        viroverse.onInvalidPatient.apply(this, arguments);
    }
};
//var onCohortLoad_f = function () {};

registerPatientInput('patientInput', 'patient_name_div', 'cohort');
