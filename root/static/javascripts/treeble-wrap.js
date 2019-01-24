/* Generic code used to produce treeble on search/summary pages. To create a treeble:
 *
 * 1) build treeble sort map via trblBuildSortMap(). This defines the type (and sorting functionality)
 *    of passed columns using trblSortEnum values.  The final argument provides the default sort colum
 *    for matching numeric entries:
 *
 *    trblBuildSortMap({date:     trblSortEnum.string,
 *                      tissue:   trblSortEnum.string,
 *                      labs:     trblSortEnum.string,
 *                      aliquots: trblSortEnum.integer,
 *                         vol:      trblSortEnum.float},
 *                       'date');
 *
 * 2) build treeble data source via trblBuildDataSource(). This creates a treeble data source using
 *       the list of data columns and location provided:
 *
 *    var dataFlds = ["date", "tissue", "aliquots", "vol", "status", "labs", "name", "additive"];
 *    var dataSrc = trblBuildDataSource(dataFlds, product_data.products);
 *
 * 3) build treeble via trblBuildTable().  Treeble is constructed using passed column definitions,
 *    treeble div and paginator id's and the number of rows to load.
 *
 *       var columnDefsArr = [
 *                {key:"date", label:"Date", resizeable:true, sortable:true},
 *                {key:"tissue", label:"Tissue", resizeable:true, sortable:true},
 *                {key:"labs", label:"Labs*", resizable:true, sortable:true},
 *                {key:"aliquots", label:"Aliquots**", resizeable:true, sortable:true, className:'align-right'},
 *                {key:"vol", label:"Vol", resizeable:true, sortable:true, className:'align-right'},
 *                {key: "status", label:"Status", resizable:true, sortable:false},
 *                {key:"name", label:"Name", resizable:true, sortable:false},
 *                {key:"additive", label:"Additive", resizable:true, sortable:false}
 *            ];
 *            trblBuildTable(columnDefsArr, dataSrc, 'treeble', 'table-pagination', product_data.products.length).load();
 *
 * Much of this code is based on/stolen from the treeble example at: http://jafl.github.com/yui2/treeble/
 */

/* taken from http://stackoverflow.com/questions/18082/validate-numbers-in-javascript-isnumeric */
function isNumber(n) {
    return !isNaN(parseFloat(n)) && isFinite(n);
}

var trblSortEnum = {"string":1, "integer":2, "float":3, "volume":4, "checkbox":5, "name":6, "link":7};

function trblBuildSortMap(colSpec, defaultSortCol){

    var trblSortFuncs = new Array();
    trblSortFuncs[trblSortEnum.string] = function(key, dir, a, b) {
        var s1 = typeof a[key] === 'undefined' || a[key] === null ? '' : a[key]; // first string to compare
        var s2 = typeof b[key] === 'undefined' || b[key] === null ? '' : b[key]; // second string to compare
        var result;

        // handle arrays
        s1 = (s1 instanceof Array ? s1.join(' ') : s1).toLowerCase();
        s2 = (s2 instanceof Array ? s2.join(' ') : s2).toLowerCase();
        result = trblAlphaSort(dir, s1, s2);

        // if strings are equal, sort by default sort column
        if (!result && key !== defaultSortCol && defaultSortCol in a && defaultSortCol in b)
            result = trblSortFuncs[trblSortEnum.name](defaultSortCol, +1, a, b);
        return result;
    }

    trblSortFuncs[trblSortEnum.integer] = function(key, dir, a, b) {
        var i1;     // first int to compare
        var i2;     // second int to compare
        var result; // return value

        i1 = (a[key] && parseInt(a[key], 10)) || 0;
        i2 = (b[key] && parseInt(b[key], 10)) || 0;

        // sort by int
        result = trblNumericSort(dir, i1, i2);

        // if ints are equal, sort by default sort column
        if (!result && key !== defaultSortCol && defaultSortCol in a && defaultSortCol in b)
            result = trblSortFuncs[trblSortEnum.name](defaultSortCol, +1, a, b);
        return result;
    }

    trblSortFuncs[trblSortEnum.float] = function(key, dir, a, b) {
        var i1;     // first int to compare
        var i2;     // second int to compare
        var result; // return value

        i1 = (a[key] && parseFloat(a[key], 10)) || 0;
        i2 = (b[key] && parseFloat(b[key], 10)) || 0;

        // sort by int
        result = trblNumericSort(dir, i1, i2);

        // if floats are equal, sort by default sort column
        if (!result && key !== defaultSortCol && defaultSortCol in a && defaultSortCol in b)
            result = trblSortFuncs[trblSortEnum.name](defaultSortCol, +1, a, b);
        return result;
    }

    trblSortFuncs[trblSortEnum.volume] = function(key, dir, a, b) {
        var v1;     // first volume to compare
        var v2;     // second volume to compare
        var result; // return value

        // break out volume and unit
        if ('unit' in a) {
            v1 = (a[key] && a['unit']) ? [a[key], a['unit']] : [0, ''];
            v2 = (b[key] && b['unit']) ? [b[key], b['unit']] : [0, ''];
        }
        else {
            v1 = (a[key] && a[key].split(' ', 2)) || [0, ''];
            v2 = (b[key] && b[key].split(' ', 2)) || [0, ''];
        }

        // if only unit appears, set volume to 0 and move unit
        if (v1.length < 2) {
            v1 = [0, ''];
        }
        if (v2.length < 2) {
            v2 = [0, ''];
        }

        // sort by unit
        var result = trblAlphaSort(dir, v1[1].toLowerCase(), v2[1].toLowerCase());

        // if units are equal, sort by volume
        if (!result)
            result = trblNumericSort(dir, parseInt(v1[0], 10), parseInt(v2[0], 10));

        // if vols are equal, sort by default sort column
        if (!result && key !== defaultSortCol && defaultSortCol in a && defaultSortCol in b)
            result = trblSortFuncs[trblSortEnum.name](defaultSortCol, +1, a, b);
        return result;
    }

    trblSortFuncs[trblSortEnum.checkbox] = function(key, dir, a, b) {
        var c1;
        var c2;
        var result; // return value

        c1 = a[key] || 0;
        c2 = b[key] || 0;

        // sort by int
        result = trblNumericSort(dir, c1, c2);

        // if floats are equal, sort by default sort column
        if (!result && key !== defaultSortCol && defaultSortCol in a && defaultSortCol in b)
            result = trblSortFuncs[trblSortEnum.name](defaultSortCol, +1, a, b);
        return result;
    }

    trblSortFuncs[trblSortEnum.name] = function(key, dir, a, b) {
        var n1 =  a[key] == null ? '' : a[key]; // first name to compare
        var n2 =  b[key] == null ? '' : b[key]; // second name to compare
        var result; // return value

        // handle arrays
        n1 = (n1 instanceof Array ? n1.join(' ') : n1).toLowerCase();
        n2 = (n2 instanceof Array ? n2.join(' ') : n2).toLowerCase();

        // compare 
        result = trblNameSort(dir, n1, n2);

        // if values are equal, sort by default sort column
        if (!result && key !== defaultSortCol && defaultSortCol in a && defaultSortCol in b)
            result = trblSortFuncs[trblSortEnum.name](defaultSortCol, +1, a, b);
        return result;
    }

    trblSortFuncs[trblSortEnum.link] = function(key, dir, a, b) {

        // pull link text
        var l1 = typeof a[key] === 'undefined' ? '' : a[key]; // first name to compare
        var l2 = typeof b[key] === 'undefined' ? '' : b[key]; // second name to compare

        var m1 = l1.match(/<a.*?>(.*)<\/a>/i)[1]||'';
        var m2 = l2.match(/<a.*?>(.*)<\/a>/i)[1]||'';

        // compare 
        result = trblNameSort(dir, m1, m2);

        // if values are equal, sort by default sort column
        if (!result && key !== defaultSortCol && defaultSortCol in a && defaultSortCol in b)
            result = trblSortFuncs[trblSortEnum.name](defaultSortCol, +1, a, b);
        return result;
    }

    function trblNumericSort(dir, n1, n2) {
        return result = (n1 - n2) * dir;
    }

    function trblAlphaSort(dir, a1, a2) {
        return (a1 < a2 ? -1 * dir : (a1 > a2 ? + 1 * dir : 0));
    }

    function trblNameSort(dir, n1, n2) {
        var m1 = n1.match(/(\d+|\D+)/g);
        var m2 = n2.match(/(\d+|\D+)/g);
        var idx = 0;

        // test for matches
        if (!m1 || !m2)
            return (!m1 && m2 ? -1 * dir : (m1 && !m2 ? +1 * dir : 0));

        // compare matches
        while (m1[idx] != null && m2[idx] != null) {
            if (isNumber(m1[idx]) && isNumber(m2[idx])) {
                result = trblNumericSort(dir, m1[idx], m2[idx]);
            }
            else {
                result = trblAlphaSort(dir, m1[idx], m2[idx]);
            }

            // get out early if possible
            if (result) return result;
            idx++;
        }

        // see if one value has fewer matches than the other
        return (!m1[idx] && m2[idx] ? -1 * dir : (m1[idx] && !m2[idx] ? + 1 * dir : 0));
    }

    function bind(f) {
        var args = Array.prototype.slice.call(arguments, 1);
        return function() {
            return f.apply(window, args.concat(Array.prototype.slice.call(arguments, 0)));
        };
    }

    var map = new Object();
    for (col in colSpec) {
        if (colSpec.hasOwnProperty(col)) {
            map[col] = {
                asc:  bind(trblSortFuncs[colSpec[col]], col, +1),
                desc: bind(trblSortFuncs[colSpec[col]], col, -1)
            }
        }
    }

    var makeConnection = YAHOO.util.LocalDataSource.prototype.makeConnection;
    YAHOO.util.LocalDataSource.prototype.makeConnection = function(oRequest, oCallback, oCaller) {
        if (!this.origLiveData) {
            this.origLiveData = this.liveData;
        }
        this.liveData = this.origLiveData.slice(0);

        if (oRequest.sort && map[ oRequest.sort ]) {
            this.liveData.sort(map[ oRequest.sort ][ oRequest.dir ]);
        }

        return makeConnection.apply(this, arguments);
    }
}

function trblBuildDataSource(fieldArr, srcArr, pagChildren, sChildNode, id) {

    function localGenerateRequest(state, path)
    {
        return state;
    };

    // Create new (treeble) data source
    if (typeof sChildNode === 'undefined')
        sChildNode = 'kids';
    fieldArr.push({key: sChildNode, parser: 'datasource'})
    var responseSchemaArr = {fields: fieldArr};

    var treebleConfigArr = {
        paginateChildren: pagChildren // if false, paginate top level only
    }
    if (typeof id !== 'undefined')
        treebleDSConfigArr[uniqueIdKey] = id; // setting this prevents children from folding on sort

    var ds = new YAHOO.util.TreebleDataSource(
                new YAHOO.util.DataSource(
                    srcArr,
                    {
                        responseType: YAHOO.util.DataSource.TYPE_JSARRAY,
                        responseSchema: { fields: fieldArr },
                        treebleConfig:
                        {
                            generateRequest:        localGenerateRequest,
                            totalRecordsReturnExpr: '.meta.totalRecords'
                        }
                    }
                ),
                treebleConfigArr
            );
    ds.child = sChildNode;
    return ds;
}

function trblBuildTable (colArr, src, tableDiv, pagDiv, pageSize, pagSizeOptions, pagFormat) {

    var sChildNode = src.child;

    // custom row formatter to marked nested (depth > 0) rows
    var rowFormatter = function(tr, rec) {
        if (rec.getData('_yui_node_depth') != 0) {
            YAHOO.util.Dom.addClass(tr, 'nested');
        }
        return true;
    };

    // custom formatter for cells containing array data
    YAHOO.widget.DataTable.Formatter.freezerArray = function (cell, rec, col, data) {
        if (data instanceof Array) {
            cell.innerHTML = data.join('<br />');
        }
        else {
            cell.innerHTML = data;
        }
    };

    // custom checkbox formatter (only add checkbox to rows with children)
    YAHOO.widget.DataTable.Formatter.freezerCheckBox = function (cell, rec, col, data) {
        var oData = rec.getData(sChildNode);
        if (rec.getData('_yui_node_depth') > 0 || (oData && oData.liveData.length)) {
            if (data) {
                cell.innerHTML = '<input class="yui-dt-checkbox" type="checkbox" checked="checked">';
            }
            else {
                cell.innerHTML = '<input class="yui-dt-checkbox" type="checkbox">';
            }
        }
    }

    // custom formatter to format aliquot volumes
    YAHOO.widget.DataTable.Formatter.freezerVol = function (cell, rec, col, data) {
            var unit = rec.getData('unit');
            if (unit == 'pellet' && isNumber(data) && data > 1) {
              unit = 'pellets';
            }

            cell.innerHTML = isNumber(data) && unit ? data + ' ' + unit : 'Unk';
    };

    // custom formatter to transform aliquot counts
    YAHOO.widget.DataTable.Formatter.freezerCnt = function (cell, rec, col, data) {
            cell.innerHTML = isNumber(data) && data > 0 ? data : 'Unk';
    };

    YAHOO.widget.DataTable.Formatter.sampleworkHref = function (cell, rec, col, data) {
            cell.innerHTML = data > 0 ? '<a href="'+viroverse.url_base +'sample/'+data+'">'+ data + '</a>' : ''
    };


    // add nub column
    var idColumnFormatter = function (cell, rec, col, data) {
        YAHOO.util.Dom.addClass(cell.parentNode, 'treeble-nub');
        var oData = rec.getData(sChildNode);
        if (oData && oData.liveData.length)
        {
            var path  = rec.getData('_yui_node_path');
            var open  = this.rowIsOpen(path);
            var clazz = open ? 'row-open' : 'row-closed';

            YAHOO.util.Dom.addClass(cell, 'row-toggle');
            YAHOO.util.Dom.replaceClass(cell, /row-(open|closed)/, clazz);
            cell.innerHTML = '<a class="treeble-collapse-nub" href="javascript:void(0);"></a>';

            YAHOO.util.Event.on(cell, 'click', function(e, path) {
                this.toggleRow(path);
            },
            path, this);
        }
    }
    colArr.unshift({key:"toggle_column", label:"", formatter: idColumnFormatter, child_only:true});

    if (typeof pagSizeOptions === 'undefined') {
        pagSizeOptions = ['All', 100, 50, 40, 30, 20, 10];
    }

    if (typeof pagFormat === 'undefined') {
        pagFormat = '{FirstPageLink}{PreviousPageLink}{PageLinks}{NextPageLink}{LastPageLink}{RowsPerPageDropdown}'
    }

    var table = new YAHOO.widget.DataTable (
        tableDiv,
        colArr,
        src,
        {
            paginator: new YAHOO.widget.Paginator({
                rowsPerPage:        pageSize,
                rowsPerPageOptions: pagSizeOptions,
                containers:         pagDiv,
                template:           pagFormat
            }),
            initialLoad:       true,
            initialRequest:    {startIndex:0, results: pageSize},
            dynamicData:       true,
            displayAllRecords: !src.paginateChildren,
            generateRequest:   YAHOO.widget.DataTable.generateTreebleDataSourceRequest,
            formatRow: rowFormatter,
        }
    );

    table.subscribe("checkboxClickEvent", function(oArgs) {

        // get checkbox, containing record and dataset
        var elCheckbox = oArgs.target;
        var rec  = this.getRecord(elCheckbox);
        var ds   = rec.getData('_yui_node_ds')
        var path = rec.getData('_yui_node_path');
        var kids;

        // set check item value in dataset
        ds.liveData[ path[ path.length-1 ] ].checked = elCheckbox.checked;

        // if record has children, set their status as well
        if (kids = rec.getData(sChildNode)) {

            // update data
            var data = kids.liveData;
            for (var j = 0, len = data.length; j < len; j++) {
                data[j].checked = elCheckbox.checked;
            }
            refreshTreeble(path);
        }

        // unset parent if child is unset
        else if (path.length > 1 && !elCheckbox.checked) {
            var parentPath = path[path.length - 2];
            var parent = src.liveData.liveData[parentPath];
            if (parent.checked) {
                parent.checked = elCheckbox.checked;
                refreshTreeble(parentPath);
            }
        }

        // set parent if all children are set
        else if (path.length > 1 && elCheckbox.checked) {
            var parentPath = path[path.length - 2];
            var parent = src.liveData.liveData[parentPath];
            if (!parent.checked) {
                var allChecked = true;
                var kids = parent[sChildNode];
                for (var j = 0, len = kids.length; j < len; j++) {
                    if (!kids[j].checked) {
                        allChecked = false;
                        break;
                    }
                }
                if (allChecked) {
                    parent.checked = true;
                    refreshTreeble(parentPath);
                }
            }
        }
    });

    function refreshTreeble (path) {
        if (table.rowIsOpen(path)) {
            var oState = table.getState();
            var oRequest = table.get("generateRequest")(oState, table);
            var callback =
            {
                success  : table.onDataReturnSetRows,
                failure  : table.onDataReturnSetRows,
                argument : oState, // Pass along the new state to the callback
                scope    : table
            };
            src.sendRequest(oRequest, callback);
        }
    }

    table.handleDataReturnPayload = function(oRequest, oResponse, oPayload)
    {
        oPayload.totalRecords = oResponse.meta.totalRecords;
        return oPayload;
    };

    table.getChecked = function() {
        var data = src.liveData.liveData;
        var checkedKids = new Array();
        var kids;

        // loop through data (number of rows will change depending on expansion row state)
        for (var i = 0, len = data.length; i < len; i++) {

            // Only pull status of children/vials contained in top level record
            if (kids = data[i][sChildNode]) {
                for (var j = 0, kLen = kids.length; j < kLen; j++) {
                    if (kids[j].checked)
                        checkedKids.push(kids[j].id);
                }
            }
        }
        return checkedKids;
    }

    table.hasChildren = function() {
        var data = src.liveData.liveData;
        var hasKids = false;

        for (var i = 0, len = data.length; i < len; i++) {
            if (data[i][sChildNode]) {
                hasKids = true;
                break;
            }
        }
        return hasKids;
    }

    table.setAllChecked = function(checked) {
        var data = src.liveData.liveData;
        var changed = false;
        var kids;

        for (var i = 0, len = data.length; i < len; i++) {
            if (data[i].checked != checked) {
                data[i].checked = checked;
                changed = true;
                if (kids = data[i][sChildNode]) {
                    for (var j = 0, kLen = kids.length; j < kLen; j++)
                        kids[j].checked = checked;
                }
            }
        }
        if (changed) {
            refreshTreeble(0);
        }
    }

    // hide child_only columns
    if (!table.hasChildren()) {
        for (var i = 0, len = colArr.length; i < len; i++) {
            if (colArr[i].child_only)
                table.hideColumn(i);
        }
    }
    return table;
}

// function to calculate aliquot total counts 
// (used on array prior to creating data source)
function load_aliquot_count_totals(arrProducts, sChildNode) {

    if (typeof sChildNode === 'undefined')
        sChildNode = 'kids';

    for (var i = 0, l = arrProducts.length; i < l; i++) {
        var count = 0;
        if (arrProducts[i][sChildNode]) {
            for (var j = 0, l2 = arrProducts[i][sChildNode].length; j < l2; j++) {
                var kid = arrProducts[i][sChildNode][j];
                if (kid && isNumber(kid.count)) {
                    count += (+ kid.count);
                }
                else {
                    count = 0;
                    break;
                }
            }
        }
        arrProducts[i].count = count;
    }
    return;
}

// function to calculate aliquot total volumes
// (used on array prior to creating data source)
function load_aliquot_vol_totals(arrProducts, sChildNode) {

    if (typeof sChildNode === 'undefined')
        sChildNode = 'kids';

    for (var i = 0, l = arrProducts.length; i < l; i++) {
        var vol = null, unit = null;
        if (arrProducts[i][sChildNode]) {
            for (var j = 0, l2 = arrProducts[i][sChildNode].length; j < l2; j++) {
                var kid = arrProducts[i][sChildNode][j];
                if (kid) {
                    if (isNumber(kid.vol)) {
                        vol += (+ kid.vol);
                    }
                    else {
                        vol = null;
                        break;
                    }
                    if (!j && kid.unit) {
                        unit = kid.unit;
                    }
                    else if (kid.unit != unit) {
                        unit = null;
                        break;
                    } 
                }
            }
        }
        // chop off floating point rounding errors
        arrProducts[i].vol  = vol != null ? parseFloat(vol.toPrecision(14)) : null;
        arrProducts[i].unit = unit;
    }
    return;
}
