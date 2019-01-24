//suggestion code to use Y!UI
//uses yahoo-dom-event, connection-min, and autocomplete-min

viroverse.scientistDataSchema = {resultsList: 'Response', fields: ['name','scientist_id'] };
viroverse.sciDataSource = new YAHOO.util.XHRDataSource(viroverse.url_base + "/enum/scientists_y/");
viroverse.sciDataSource.responseSchema = viroverse.scientistDataSchema;
viroverse.sciDataSource.responseType = YAHOO.util.DataSource.TYPE_JSON;
YAHOO.widget.AutoComplete.prototype.formatResult = function (aResultItem, sQuery) {
    return aResultItem[0];
}

viroverse.suggests = new Array;

function activate_sci_ac () {
    var sci_ac = document.getElementsByClassName('sci_ac');
    for (var i = 0; i < sci_ac.length; i++) {
        var ac     = sci_ac[i];
        var divs   = ac.getElementsByTagName('div');
        var inputs = ac.getElementsByTagName('input');
        viroverse.suggests.push(new YAHOO.widget.AutoComplete(inputs[0], divs[0], viroverse.sciDataSource));
    }

}

YAHOO.util.Event.onDOMReady(activate_sci_ac);
