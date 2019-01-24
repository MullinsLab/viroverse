(function(){

/**
 * This will hopefully be obsolete when YUI 2.9 is released.
 *
 * @module Treeble
 * @namespace YAHOO.widget
 * @class YAHOO.widget.DataSource,YAHOO.widget.DataTable
 */

	var lang   = YAHOO.lang,
		util   = YAHOO.util,
		widget = YAHOO.widget,
		ua     = YAHOO.env.ua,

		Dom    = util.Dom,
		Ev     = util.Event,
		DS     = util.DataSourceBase,
		DT     = widget.DataTable;

	/*
	 * Fix scope when calling parsers.
	 */
	DS.prototype.parseJSONData = function(oRequest, oFullResponse) {
		var oParsedResponse = {results:[],meta:{}};

		if(lang.isObject(oFullResponse) && this.responseSchema.resultsList) {
			var schema = this.responseSchema,
				fields          = schema.fields,
				resultsList     = oFullResponse,
				results         = [],
				metaFields      = schema.metaFields || {},
				fieldParsers    = [],
				fieldPaths      = [],
				simpleFields    = [],
				bError          = false,
				i,len,j,v,key,parser,path;

			// Function to convert the schema's fields into walk paths
			var buildPath = function (needle) {
				var path = null, keys = [], i = 0;
				if (needle) {
					// Strip the ["string keys"] and [1] array indexes
					needle = needle.
						replace(/\[(['"])(.*?)\1\]/g,
						function (x,$1,$2) {keys[i]=$2;return '.@'+(i++);}).
						replace(/\[(\d+)\]/g,
						function (x,$1) {keys[i]=parseInt($1,10)|0;return '.@'+(i++);}).
						replace(/^\./,''); // remove leading dot

					// If the cleaned needle contains invalid characters, the
					// path is invalid
					if (!/[^\w\.\$@]/.test(needle)) {
						path = needle.split('.');
						for (i=path.length-1; i >= 0; --i) {
							if (path[i].charAt(0) === '@') {
								path[i] = keys[parseInt(path[i].substr(1),10)];
							}
						}
					}
					else {
					}
				}
				return path;
			};


			// Function to walk a path and return the pot of gold
			var walkPath = function (path, origin) {
				var v=origin,i=0,len=path.length;
				for (;i<len && v;++i) {
					v = v[path[i]];
				}
				return v;
			};

			// Parse the response
			// Step 1. Pull the resultsList from oFullResponse (default assumes
			// oFullResponse IS the resultsList)
			path = buildPath(schema.resultsList);
			if (path) {
				resultsList = walkPath(path, oFullResponse);
				if (resultsList === undefined) {
					bError = true;
				}
			} else {
				bError = true;
			}

			if (!resultsList) {
				resultsList = [];
			}

			if (!lang.isArray(resultsList)) {
				resultsList = [resultsList];
			}

			if (!bError) {
				// Step 2. Parse out field data if identified
				if(schema.fields) {
					var field;
					// Build the field parser map and location paths
					for (i=0, len=fields.length; i<len; i++) {
						field = fields[i];
						key    = field.key || field;
						parser = ((typeof field.parser === 'function') ?
							field.parser :
							DS.Parser[field.parser+'']) || field.converter;
						path   = buildPath(key);

						if (parser) {
							fieldParsers[fieldParsers.length] = {key:key,parser:parser};
						}

						if (path) {
							if (path.length > 1) {
								fieldPaths[fieldPaths.length] = {key:key,path:path};
							} else {
								simpleFields[simpleFields.length] = {key:key,path:path[0]};
							}
						} else {
						}
					}

					// Process the results, flattening the records and/or applying parsers if needed
					for (i = resultsList.length - 1; i >= 0; --i) {
						var r = resultsList[i], rec = {};
						if(r) {
							for (j = simpleFields.length - 1; j >= 0; --j) {
								// Bug 1777850: data might be held in an array
								rec[simpleFields[j].key] =
										(r[simpleFields[j].path] !== undefined) ?
										r[simpleFields[j].path] : r[j];
							}

							for (j = fieldPaths.length - 1; j >= 0; --j) {
								rec[fieldPaths[j].key] = walkPath(fieldPaths[j].path,r);
							}

							for (j = fieldParsers.length - 1; j >= 0; --j) {
								var p = fieldParsers[j].key;
								rec[p] = fieldParsers[j].parser.call(this, rec[p]);
								if (rec[p] === undefined) {
									rec[p] = null;
								}
							}
						}
						results[i] = rec;
					}
				}
				else {
					results = resultsList;
				}

				for (key in metaFields) {
					if (lang.hasOwnProperty(metaFields,key)) {
						path = buildPath(metaFields[key]);
						if (path) {
							v = walkPath(path, oFullResponse);
							oParsedResponse.meta[key] = v;
						}
					}
				}

			} else {

				oParsedResponse.error = true;
			}

			oParsedResponse.results = results;
		}
		else {
			oParsedResponse.error = true;
		}

		return oParsedResponse;
	};

	/*
	 * DT overrides are only needed for local data sources or when
	 * paginating only top-level nodes.
	 */

	DT.prototype.load = function(oConfig) {
		oConfig = oConfig || {};

		(oConfig.datasource || this._oDataSource).sendRequest(
			oConfig.request || this.get('initialRequest'),
			oConfig.callback || {
				success: this.onDataReturnInitializeTable,
				failure: this.onDataReturnInitializeTable,
				scope: this,
				argument: this.getState()
			}
		);
	};

	var origInitAttributes = DT.prototype.initAttributes;
	DT.prototype.initAttributes = function()
	{
		origInitAttributes.apply(this, arguments);

		/**
		 * @attribute displayAllRecords
		 * @description Set to true if you want to show all the records that were
		 * returned, not just the records that fall inside the paginator window.
		 * @type Boolean
		 * @default 0
		 */
		this.setAttributeConfig("displayAllRecords", {
			value: false,
			validator: lang.isBoolean
		});
	};

	/*
	 * Override to provide option to display all returned records, even if
	 * that is more than what paginator says is visible.
	 */
	DT.prototype.render = function() {

		this._oChainRender.stop();

		this.fireEvent("beforeRenderEvent");

		var i, j, k, len, allRecords;

		var oPaginator = this.get('paginator');
		// Paginator is enabled, show a subset of Records and update Paginator UI
		if(oPaginator && this.get('displayAllRecords')) {
			allRecords = this._oRecordSet.getRecords(
							oPaginator.getStartIndex());
		}
		else if(oPaginator) {
			allRecords = this._oRecordSet.getRecords(
							oPaginator.getStartIndex(),
							oPaginator.getRowsPerPage());
		}
		// Not paginated, show all records
		else {
			allRecords = this._oRecordSet.getRecords();
		}

		// From the top, update in-place existing rows, so as to reuse DOM elements
		var elTbody = this._elTbody,
			loopN = this.get("renderLoopSize"),
			nRecordsLength = allRecords.length;

		// Table has rows
		if(nRecordsLength > 0) {
			elTbody.style.display = "none";
			while(elTbody.lastChild) {
				elTbody.removeChild(elTbody.lastChild);
			}
			elTbody.style.display = "";

			// Set up the loop Chain to render rows
			this._oChainRender.add({
				method: function(oArg) {
					if((this instanceof DT) && this._sId) {
						var i = oArg.nCurrentRecord,
							endRecordIndex = ((oArg.nCurrentRecord+oArg.nLoopLength) > nRecordsLength) ?
									nRecordsLength : (oArg.nCurrentRecord+oArg.nLoopLength),
							elRow, nextSibling;

						elTbody.style.display = "none";

						for(; i<endRecordIndex; i++) {
							elRow = Dom.get(allRecords[i].getId());
							elRow = elRow || this._addTrEl(allRecords[i]);
							nextSibling = elTbody.childNodes[i] || null;
							elTbody.insertBefore(elRow, nextSibling);
						}
						elTbody.style.display = "";

						// Set up for the next loop
						oArg.nCurrentRecord = i;
					}
				},
				scope: this,
				iterations: (loopN > 0) ? Math.ceil(nRecordsLength/loopN) : 1,
				argument: {
					nCurrentRecord: 0,//nRecordsLength-1,  // Start at first Record
					nLoopLength: (loopN > 0) ? loopN : nRecordsLength
				},
				timeout: (loopN > 0) ? 0 : -1
			});

			// Post-render tasks
			this._oChainRender.add({
				method: function(oArg) {
					if((this instanceof DT) && this._sId) {
						while(elTbody.rows.length > nRecordsLength) {
							elTbody.removeChild(elTbody.lastChild);
						}
						this._setFirstRow();
						this._setLastRow();
						this._setRowStripes();
						this._setSelections();
					}
				},
				scope: this,
				timeout: (loopN > 0) ? 0 : -1
			});

		}
		// Table has no rows
		else {
			// Set up the loop Chain to delete rows
			var nTotal = elTbody.rows.length;
			if(nTotal > 0) {
				this._oChainRender.add({
					method: function(oArg) {
						if((this instanceof DT) && this._sId) {
							var i = oArg.nCurrent,
								loopN = oArg.nLoopLength,
								nIterEnd = (i - loopN < 0) ? -1 : i - loopN;

							elTbody.style.display = "none";

							for(; i>nIterEnd; i--) {
								elTbody.deleteRow(-1);
							}
							elTbody.style.display = "";

							// Set up for the next loop
							oArg.nCurrent = i;
						}
					},
					scope: this,
					iterations: (loopN > 0) ? Math.ceil(nTotal/loopN) : 1,
					argument: {
						nCurrent: nTotal,
						nLoopLength: (loopN > 0) ? loopN : nTotal
					},
					timeout: (loopN > 0) ? 0 : -1
				});
			}
		}
		this._runRenderChain();
	};

})();
