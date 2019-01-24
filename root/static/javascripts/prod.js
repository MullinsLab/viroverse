function product_finder(find_a,finder_stem,error_div_id,add_fn) {
    this.DataSource = false;
    this.DataTable = false;
    this.add_multiple = false;

    this.DSmaxCacheEntries = 0; //disable local JS data cache and force server request for each load

    this.form_el = document.getElementById(finder_stem + "_finder");
    this.table_div_el = document.getElementById(finder_stem + "_table_replace");
    this.summary_el = document.getElementById(finder_stem + "_show");
    this.type_select_el = document.getElementById(finder_stem + "_product_type");
    this.btn_el = document.getElementById(finder_stem + "_btn"); 
    this.addl_buttons = new Array;
    this.error_div_el = document.getElementById(error_div_id);
    this.add_fn = add_fn;
    this.added_things = new Array(); // holds the dataSource "row" of all added objects, up to the consumer to clear if that's allowed

    if (find_a.length == 1) {
        this.single_type = find_a[0];
    } else {
        this.single_type = false;
    }

    this.to_find = find_a;

    //these can be overridden from the outside
    this.responseSchemaArr = {
    resultsList : "Response",
     fields : 
        [
            {key:'id'},
            {key:'name'},
            {key:'completed'},
            {key:'scientist_name' },
            {key:'sample_name'}
        ]
    };

    this.columnDefsArr = [
            {key:'id',sortable:true, className:'yHide'},
            {key:'name',sortable:true, className:'yHide'},
            {key:'completed',label:'Completed date',sortable:true },
            {key:'scientist_name',label:'Scientist Name',sortable:true,resizeable:true},
            {key:'sample_name',label:'Sample',sortable:true,resizeable:true}
    ];

    this.type_specific = {
        gel : {
            responseSchemaArr : {
                resultsList : "Response",
                fields : 
                [
                    {key:'id'},
                    {key:'name'},
                    {key:'entered'},
                    {key:'scientist_name' }
                ]
            },
            columnDefsArr : [
                {key:'id',sortable:true, className:'yHide'},
                {key:'name',sortable:true, sortable:true,resizeable:true },
                {key:'entered',label:'Date',sortable:true },
                {key:'scientist_name',label:'Scientist Name',sortable:true,resizeable:true}
            ]
        },
        pcr : {
            responseSchemaArr : {
                resultsList : "Response",
                fields : 
                [
                    {key:'id'},
                    {key:'name'},
                    {key:'nickname'},
                    {key:'completed'},
                    {key:'scientist_name' },
                    {key:'sample_name'},
                    {key:'round'},
                    {key:'reamp'},
                    {key:'replicate'},
                    {key:'primers'},
                    {key:'is_pool'},
                    {key:'desc_html'} //patched together by beforeParse fn below
                ]
            } ,
            columnDefsArr : [
                {key:'id',sortable:true, className:'yHide'},
                {key:'name',sortable:true, sortable:true,resizeable:true },
                {key:'nickname',sortable:true,resizeable:true,editor:new YAHOO.widget.TextboxCellEditor({ asyncSubmitter: cellEdit_nickname }), formatter: pcr_nickname_format, sortOptions: {sortFunction: alphanumsort_by_field, field: 'nickname'} },
                {key:'completed',label:'Completed date',sortable:true,resizeable:true },
                {key:'sample_name',label:'Specimen',sortable:true,resizeable:true },
                {key:'round',label:'rnd',sortable:true,resizeable:true},
                {key:'reamp',label:'re-amp',sortable:true,resizeable:true},
                {key:'replicate',label:'repl',sortable:true,resizeable:true},
                {key:'primers',sortable:true,resizeable:true},
                {key:'scientist_name',label:'Scientist Name',sortable:true,resizeable:true},
                {key:'desc_html',className:'yHide'}
            ],
            addl_filters : [
                { partial: "product_patient_filter" },
                '<label>Sample Name</label><span class="formw"><input name="sample_name" type="text" size="10" /></span>',
                '<label><abbr title="Used in sequence label, can accept % as a wildcard to search">PCR Nickname</abbr></label><span class="formw"><input name="pcr_name" type="text" size="10" /></span>',
                '<label>PCR Round</label><span class="formw"><input name="pcr_round" type="text" size="10" maxlength="1" /></span>',
                '<label>Pooled</label><span class="formw"><select name="pcr_pool"><option value=""></option><option value="yes">yes</option><option value="no">no</option></select></span>',
                // XXX FIXME: Searching by "Cleaned" currently doesn't work, see
                // corresponding comment in find_generic.  Until we fix it,
                // hide the UI so people don't try to use it.  When fixed,
                // please re-enable the disabled logic in find_generic as well.
                // -trs, 17 Dec 2014
                //'<label>Cleaned</label><span class="formw"><select name="pcr_cleaned"><option value=""></option><option value=1>yes</option><option value=0>no</option></select></span>',

                //'<label>Concentrated</label><span class="formw"><select name="pcr_conc"><option value=""></option><option value=1>yes</option><option value=0>no</option></select></span>',
                ],
            beforeParse : function (oReq, oResp, oCall) {
                for (i in oResp.Response) {
                    oResp.Response[i].desc_html = escapeHTML(oResp.Response[i].name);
                    if (oResp.Response[i].nickname) {
                        oResp.Response[i].desc_html += " <span class='nick_base'>"+escapeHTML(oResp.Response[i].nickname)+'</span>'
                    }
                }

                return oResp;
            }
        },
        extraction : {
            responseSchemaArr : {
                resultsList: "Response",
                fields: [
                    {key:'id'},
                    {key:'name'},
                    {key:'completed'},
                    {key:'scientist_name'},
                    {key:'sample_name'},
                    {key:'tissue'},
                    {key:'concentration'},
                    {key:'concentration_unit'},
                ]
            },
            columnDefsArr : [
                {key:'id',className:'yHide'},
                {key:'name',className:'yHide'},
                {key:'completed',sortable:true},
                {key:'scientist_name',label:'Scientist Name',sortable:true},
                {key:'sample_name',label:'Sample Name',resizeable:true, sortable: true },
                {key:'tissue',label:'Tissue',resizeable:true, sortable: true },
                {key:'concentration',label:'ng/ul',editor:new YAHOO.widget.TextboxCellEditor({ asyncSubmitter: cellEdit_conc}), sortable: true },
                {key:'concentration_unit',className:'yHide'},
            ]
        },
        sample : {
            responseSchemaArr : {
                resultsList: "Response",
                fields: [
                    {key:'id'},
                    {key:'name'},
                    {key:'sample_name'},
                    {key:'subject'},
                    {key:'collection_date'},
                    {key:'tissue'},
                    {key:'notes'},
                    {key:'scientist'},
                    {key:'viral_load'},
                ]
            },
            columnDefsArr : [
                {key:'id',className:'yHide'},
                {key:'name',className:'yHide'},
                {key:'sample_name',label:'Name',sortable:true,resizeable:true},
                {key:'subject',sortable:true,resizeable:true},
                {key:'collection_date',label:'Collection Date',sortable:true},
                {key:'tissue',sortable:true},
                {key:'viral_load',label:'RNA VL',resizeable:true},
                {key:'notes',sortable:false},
                {key:'scientist',label:'Assigned to',sortable:true}
            ],
            addl_filters: [
                { partial: "product_patient_filter", insertBefore: "date_filter" },
                { partial: "product_tissue_filter",  insertBefore: "date_filter" },
                { html: '<label>Sample Name</label><span class="formw"><input name="name" type="text" size="10" /></span>', insertBefore: "date_filter" }
            ]
        },
        chromat : {
            responseSchemaArr : {
                resultsList: "Response",
                fields: [
                    {key:'id'},
                    {key:'name'},
                    {key:'added'},
                    {key:'scientist_name'},
                    {
                        key:    'assigned_to_well',
                        parser: function(bool){ return bool ? "yes" : "no" }
                    }
                ]
            },
            columnDefsArr : [
                {key:'id',className:'yHide'},
                {key:'name',sortable:true},
                {key:'added',sortable:true},
                {key:'scientist_name',sortable:true, label:"scientist name"},
                { key: 'assigned_to_well', sortable: true, label: "Assigned to well?" }
            ],
            addl_filters : [
                '<label>Name</label><span class="formw"><input name="name" type="text" size="40"></span>',
            ]
        }
    };

    //copy pcr def to pos_pcr
    this.type_specific.pos_pcr = this.type_specific.pcr;

    var self = this;
    ["extraction", "sample"].forEach(function(product) {
        ["dna", "rna"].forEach(function(na) {
            self.type_specific[product + "." + na] = self.type_specific[product];
        });
    });

    this.dataTableArr = {
        scrollable:true,
        height:'20em',
        generateRequest:this.sort_state_string, 
        initialLoad:false,
        MSG_LOADING:'retrieving...',
        finder_obj:this
    };

    this.synch_filters();
}

product_finder.prototype.which_kind = function () {
    if (this.single_type) {
        return this.single_type
    } else {
        return this.type_select_el.value
    }
}

product_finder.prototype.clear_added_things = function () {
    this.added_things = new Array();
}

product_finder.prototype.product_filter = function () {
    var this_obj = this;

    this.summary_el.innerHTML = 'Click a product on the left to see a description here.';

    this_obj.rebuildTable( this.which_kind() );
}

product_finder.prototype.findable_type = function(type) {
    for (var i = 0; i < this.to_find.length; i++) {
        if (type === this.to_find[i])
            return true;
    }
    return false;
};

product_finder.prototype.from_ids = function(type, ids){
    if(! Array.isArray(ids) ) {
      ids = [ ids ];
    }
    if (!(type && ids && ids.length && this.findable_type(type))) return;

    if (this.type_select_el) {
        this.type_select_el.value = type;
        this.ontypechange();
    }

    finder.rebuildTable(type, ids);
    this.summary_el.innerHTML = 'Click a product on the left to see a description here.';
}

product_finder.prototype.rebuildTable = function(product_type, ids) {
    if (!product_type)
        product_type = this.which_kind();

    if (!this.findable_type(product_type)) return;

    if (!this.DataTable) { //first time
        this.DataSource = new YAHOO.util.DataSource( formaction2url(this.form_el) ); //for some reason a 'null' gets stuck on the end by yahoo so a & at the end makes that legal
        this.DataSource.responseType = YAHOO.util.DataSource.TYPE_JSON;
        this.DataSource.maxCacheEntries = this.DSmaxCacheEntries;
        this.DataSource.connMethodPost = true;
        this.DataSource.connXhrMode    = 'cancelStaleRequests';
        if (this.type_specific[product_type] && this.type_specific[product_type].responseSchemaArr) {
            this.DataSource.responseSchema = this.type_specific[product_type].responseSchemaArr
        } else {
            this.DataSource.responseSchema = this.responseSchemaArr; 
        }
        if (this.type_specific[product_type] && this.type_specific[product_type].beforeParse) {
            this.DataSource.doBeforeParseData = this.type_specific[product_type].beforeParse;
        }

        var relevantColumnsDefArr;
        if (this.type_specific[product_type] && this.type_specific[product_type].columnDefsArr) {
            relevantColumnDefsArr = this.type_specific[product_type].columnDefsArr ;
        } else {
            relevantColumnDefsArr = this.columnDefsArr;
        }

        this.DataTable = new YAHOO.widget.ScrollingDataTable(this.table_div_el, relevantColumnDefsArr, this.DataSource, this.dataTableArr)
        this.DataTable.subscribe('rowClickEvent',this.DataTable.onEventSelectRow);

        var self = this;
        this.DataTable.subscribe('rowClickEvent',function () { self.show_product() });// have to pass in this bc context will be not obj

        this.DataTable.subscribe('editorSaveEvent',function () { this.configs.finder_obj.product_filter() });


        this.btn_el.style.visibility = 'visible';

        for (var i=0;i<this.addl_buttons.length;i++) {
                document.getElementById(this.addl_buttons[i]).style.visibility = 'visible';
        }

        this.DataTable.doBeforeLoadData= function( sRequest ,oResponse, oPayload ) {
            oPayload = oPayload || {};
            if(oResponse.results.length && oResponse.results.length > viroverse.max_results_json) {
                this.showTableMessage("The finder returned " + oResponse.results.length + " products.<br />This tool can't handle more than " + escapeHTML(viroverse.max_results_json) + ".<br />Please refine your parameters.");
                return false;
            }
            return true;
        }

        this.DataSource.subscribe('dataErrorEvent', function(state) {
            // Generic error handling if we want json but got text/plain:
            // assume it's an error message from the server and display it.
            var res = state.response;
            if (res
                && res.getResponseHeader
                && res.getResponseHeader["Content-Type"].indexOf("text/plain") === 0
                && res.responseText
                && this.responseType === YAHOO.util.DataSource.TYPE_JSON)
            {
                // Pass the error message to the request's failure handler; see afterSend below
                state.callback.argument.message = res.responseText;
            }
        });

        this.DataTable.subscribe("cellClickEvent", this.DataTable.onEventShowCellEditor);
    } 

    var afterSend = {
        success : this.DataTable.onDataReturnInitializeTable,
        failure : function(req, parsedResponse, data) {
            if (data.message)
                this.showTableMessage(escapeHTML( data.message ));
            else
                this.showTableMessage("Server error");
        },
        argument : {
            state: this.DataTable.getState(),
            message: null
        },
        scope : this.DataTable
    };

    this.DataTable.getRecordSet().reset();
    this.DataTable.render();
    this.DataTable.showTableMessage('Retrieving...');
    req = this.DataTable.get('generateRequest')(this.DataTable, product_type, ids);
    this.DataSource.sendRequest(req,afterSend);
};


product_finder.prototype.confirm_delete = function () {
    var it = this;
    var d = new YAHOO.widget.SimpleDialog('dlg', {
        fixedcenter:true,
        close:false,
        modal:true,
        draggable:true
    });
    d.setHeader('Confirm Delete');
    d.setBody("Are you sure you want to irretrievably delete from the database?");
    d.cfg.queueProperty('buttons',[
        { text: "DELETE", handler: function () { d.hide(); it.delete_product() } },
        { text: "cancel", handler: d.hide, isDefault:true }
    ]);
    YAHOO.util.Dom.addClass(d.element, "overlay");
    d.render(document.body);
    d.show();

}

product_finder.prototype.add_product = function () {
    var trs = this.DataTable.getSelectedTrEls();
    var is_a = this.which_kind();
    var selRecs = this.DataTable.getSelectedRows();
    var multiple_ids = new Array;
    for (var tri =0;tri< selRecs.length;tri++ ) {
        // Make a poor man's clone to avoid modifying the DataTable's
        var rec = JSON.parse(JSON.stringify(this.DataTable.getRecord(selRecs[tri]).getData()));
        var id  = rec.id;

        rec.type = is_a;

        this.added_things.push(rec);

        if (!this.add_multiple) {
            var html;
            if (rec.desc_html != null) {
                html = rec.desc_html;
            } else {
                html = escapeHTML(rec.name);
            }
            this.add_fn(is_a,id,html,this.add_fn_arguments);
        } else {
            multiple_ids.push(id);
        }
    }

    if (this.add_multiple) {
            this.add_fn(is_a,multiple_ids,'many',this.add_fn_arguments);
    }

    if (this.all_clear_fn) {
        this.all_clear_fn();
    }
}

function getSelectedTrProductIds (theTable) {
    var trs = theTable.getSelectedTrEls();
    var ids = new Array;

    for (var tri =0;tri< trs.length;tri++ ) {
            ids.push(trs[tri].childNodes[0].textContent);
    }

    return ids;
}

product_finder.prototype.show_product = function () {
    var product_type = this.which_kind();
    var sel_tr = this.DataTable.getSelectedTrEls();
    if (sel_tr.length == 1) {
        var first_tr = sel_tr[0];
        var load_id = first_tr.firstChild.textContent; // want text node of inner div
        div_load_ajax(viroverse.url_base + 'summary/mini/' + product_type.replace(/\.[rd]na$/i, '') + '/'+load_id,this.summary_el.id,null);
    }     else {
        this.summary_el.innerHTML= sel_tr.length + ' items selected. (select a single product to view summary here)';
    }

}

product_finder.prototype.ontypechange = function () {
    this.synch_filters();

    if (this.DataTable) {
        this.DataTable.destroy();
        this.DataTable = null;
    }
}

product_finder.prototype.synch_filters = function () {
    var self = this;
    var product_type = this.which_kind();

    // Clear existing
    var addl_filters = this.form_el.getElementsByClassName("addl_filter");
    while (addl_filters.length) { // NodeLists reflect live DOM changes
        addl_filters[0].parentNode.removeChild(addl_filters[0]);
    }

    var filters = this.form_el.getElementsByClassName("filter");
    var find_button = filters[ filters.length - 1 ]; // last "filter" is find button
    var date_filter = Array.apply(null, filters).filter(function(f){ return !!f.querySelector("input.date") })[0];

    if (this.type_specific[product_type] && this.type_specific[product_type].addl_filters) {
        this.type_specific[product_type].addl_filters
            .map(function(filter) {
                return typeof filter === 'object'
                    ? filter
                    : { html: filter };
            })
            .forEach(function(filter) {
                var handler = [];
                var placeholder;

                if (filter.html) {
                    placeholder = document.createElement('div');
                    placeholder.className = 'filter addl_filter';
                    placeholder.innerHTML = filter.html;
                }
                else if (filter.partial) {
                    // Fetch partials, setup callback chain to insert them and run any scripts
                    placeholder = document.createElement("span");
                    placeholder.id = "partial_" + filter.partial;
                    placeholder.className = 'addl_filter';

                    // don't add a partial more than once!
                    if (document.getElementById(placeholder.id)) return;

                    handler.push(function() {
                        load_url_ajax(viroverse.url_base + "/partials/" + filter.partial, function(data){
                            placeholder.innerHTML = data;
                            evalScripts(placeholder);
                        });
                    });
                }

                if (filter.insertBefore === "date_filter") {
                    self.form_el.insertBefore(placeholder, date_filter || find_button);
                } else {
                    self.form_el.insertBefore(placeholder, find_button);
                }

                // Run handlers after insertion so that any ajax callbacks they
                // create are guaranteed that the placeholder they use is already
                // inserted into the document.  Otherwise inline scripts may trip
                // up when they go to find elements that aren't yet in the
                // document.
                handler.forEach(function(h){ h() });
            });
    }
}

product_finder.prototype.sort_state_string  = function (DT, product_type, ids) {
    var state = DT.getState();

    var sort = (state.sortedBy) ? state.sortedBy.key : DT.getColumnSet().keys[0].getKey();
    var dir = (state.sortedBy && state.sortedBy.dir == DT.CLASS_DESC) ? "desc" : "asc";
    var search = formfields2urlparams(DT.configs.finder_obj.form_el);

    // This used to come from up to two places:
    //   1) a hidden form field (find_a) set by product_filter()
    //   2) the first element of a "preload" array set by from_ids()
    //
    // The issue is that preload was sticky on the object and so two find_a
    // values could be submitted (one from preload, the other from the
    // hidden field).  To make matters worse, preload was never unset but
    // always shift()'d, so subsequent loads grabbed object ids from the
    // array!  Instead, expect any request generation to provide it, or
    // default to which_kind().
    // -trs, 28 Oct 2013
    if (!product_type) product_type = DT.configs.finder_obj.which_kind();
    search = search + "&find_a=" + product_type;

    if (ids && ids.length) {
        search = search + "&" + product_type + "s=" + ids.join("&" + product_type + "s=");
    }
    return "sort=" + sort + "&direction=" + dir + "&" + search;
}

//actually interact with DOM external to this object, usally set as add_fn (at least in simple cases)
function add_product_box (product_type,product_id,product_text,prev_args) { //(targetDiv,name,value,label) {

    var targetDiv = document.getElementById(prev_args[0]);
    var errorDiv = document.getElementById(prev_args[1]);
    var noticeDiv = document.getElementById("notice");

    var theInput = document.createElement('input');
    theInput.setAttribute('name',product_type.replace(/\.[rd]na$/i, '')+'box');
    theInput.setAttribute('value',product_id);
    theInput.setAttribute('type','checkbox');
    theInput.setAttribute('checked',true);
    theLabel = document.createElement('label');
    theLabel.setAttribute('class', 'check');
    theLabel.innerHTML = product_text;

    // XXX TODO: Move the input inside the label for easier selecting:
    //
    //      theLabel.insertBefore(theInput, theLabel.firstChild);
    //
    // Lots of product finders use this function, however, so check that they
    // all still work when the input is inside the label.
    // -trs, 26 Nov 2013
    targetDiv.appendChild(theInput);
    targetDiv.appendChild(theLabel);
    theBr = document.createElement('br');
    theBr.setAttribute('clear','all');
    targetDiv.appendChild(theBr);
    if(errorDiv){
        errorDiv.style.display = 'none';
    }
    if(noticeDiv){
        noticeDiv.style.display = 'none';
    }

    setFormDisable(theInput.form,false);
}

function cellEdit_nickname (fnCallback, oNewValue) {

    var r = this.getRecord();

    var u = viroverse.url_base + 'input/edit/pcr/nickname/'+r.getData('id')+'/'+oNewValue

    var after_load = function (text) {
        var b = false;
        if (text.substring(0,2) == 'OK') {
            b = true;
        }
        fnCallback(b,oNewValue);
    }

    load_url_ajax(u,after_load, false, false, 'POST');

}

product_finder.prototype.delete_product = function () {
    var u = viroverse.url_base + 'input/delete/'+this.which_kind()+'/'+getSelectedTrProductIds(this.DataTable).join('/');

    var dt = this.DataTable;
    var after_load = function (text) {
        if (text.substring(0,2) == 'OK') {
            var rows = dt.getSelectedRows();
            for (var r=0;r<rows.length;r++) {
                dt.deleteRow(rows[r]);
            }
            confirm_message('Delete successful');
        } else {
            clear_confirm();
            show_error('error','Delete failed');
        }
    }

    load_url_ajax(u,after_load,'error', false, 'POST');

}

function cellEdit_conc (fnCallback, oNewValue) {
    var r = this.getRecord();

    var u = viroverse.url_base + 'input/edit/extraction/concentration/'+r.getData('id')+'/'+oNewValue;

    var after_load = function (text) {
        var b = false;
        if (text.substring(0,2) == 'OK') {
            b = true;
        }
        fnCallback(b,oNewValue);
    }

    load_url_ajax(u,after_load, false, false, 'POST');
}

function pcr_nickname_format (elCell, oRecord, oColumn, oData) {
    if (oRecord.getData('nickname') != null ) {
        elCell.innerHTML = '<span class="nick_base">' + oRecord.getData('nickname') + '</span> '
        if (oRecord.getData('is_pool')) {
            elCell.innerHTML += '<span class="nick_auto">pool</span>'
        } else {
            elCell.innerHTML += '<span class="nick_auto">r' + oRecord.getData('round')+'x'+oRecord.getData('replicate')+'</span>';
        }
    }
}

function alphanumsort_by_field (a,b,desc,field) {
    astr = a.getData(field);
    bstr = b.getData(field)
    if (astr == null && bstr == null) {
        return 0
    }
    if ( astr == null ) {
        return 1
    } else if ( bstr == null ) {
        return -1
    }

    if (desc) {
        return alphanumsort( bstr, astr);
    } else {
        return alphanumsort( astr,bstr );
    }
}

function reload_with (type,ids,mult,args) {
    var url = args[0];
    if (url.slice(-1) != '/') {
        url += '/'
    }
    window.location = url + ids.join('/');
}
