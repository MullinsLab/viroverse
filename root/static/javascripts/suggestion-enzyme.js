//suggestion code to use Y!UI
//uses yahoo-dom-event, connection-min, and autocomplete-min

viroverse.enzymeDataSchema = {resultsList: 'Response', fields: ['name']};
viroverse.enzymeDataSource = new YAHOO.util.XHRDataSource(viroverse.url_base + "/enum/enzymes_y/")
viroverse.enzymeDataSource.responseSchema = viroverse.enzymeDataSchema;
viroverse.enzymeDataSource.responseType = YAHOO.util.DataSource.TYPE_JSON;
YAHOO.widget.AutoComplete.prototype.formatResult = function (aResultItem, sQuery) {
    return aResultItem[0];
}

YAHOO.util.Event.onAvailable ( 'enzyme_name_1_div',
function (){
    var autocomplete = new YAHOO.widget.AutoComplete('enzyme_name_1','enzyme_name_1_div',viroverse.enzymeDataSource);
}, this);
