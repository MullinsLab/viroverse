//suggestion code to use Y!UI
//uses yahoo-dom-event, connection-min, and autocomplete-min

viroverse.primerDataSchema = {resultsList: 'Response', fields: ['name','lab_common']};
viroverse.primerDataSource = new YAHOO.util.XHRDataSource(viroverse.url_base + "/enum/primers_y/")
viroverse.primerDataSource.responseSchema = viroverse.primerDataSchema;
viroverse.primerDataSource.responseType = YAHOO.util.DataSource.TYPE_JSON;
YAHOO.widget.AutoComplete.prototype.formatResult = function (aResultItem, sQuery) {
    if (aResultItem[1] == 1) {
        return '<b>'+aResultItem[0]+'</b>';
    } else {
        return aResultItem[0];
    }
}
