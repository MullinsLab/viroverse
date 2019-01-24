// vim: set sw=2 ts=2 :
(function(){
  'use strict';

  angular
    .module('vv.ui.facetedSearch', [
      'vv.model.facetedSearch',
      'vv.ui'
    ])
    .directive('facetedSearch', directive)
    .directive('freeformInput', subdirective('freeform-input', { placeholder: '@' }))
    .directive('clearSearchButton', subdirective('clear-search-button'))
    .directive('shareButton', subdirective('share-button'))
    .directive('facetWidget', subdirective('facet-widget', { name: '@', nullLabel: '@?' }))
    .directive('resultSummary', subdirective('result-summary', { noun: '@', population: '@?' }))
    .directive('resultPager', subdirective('result-pager'))
    .directive('resultPagination', subdirective('result-pagination'))
  ;

  directive.$inject = [];

  function directive() {
    return {
      restrict: 'E',
      controller: controller,
      controllerAs: 'search',
      bindToController: {
        endpoint: '@',
        rowsPerPage: '=?'
      },
      scope: true
    };
  }

  function subdirective(name, scope) {
    subdir.$inject = ['$log'];

    function subdir($log) {
      return {
        restrict: 'E',
        require: '^facetedSearch',
        scope: scope || {},
        link: function(scope, element, attrs, ctrl) {
          $log.debug("Registering " + name + " element");

          // Pass the parent controller into our isolate scope
          scope.search = ctrl;
        },
        templateUrl: viroverse.url_base + '/static/partials/faceted-search/' + name + '.html'
      };
    }
    return subdir;
  }


  controller.$inject = ['FacetedSearch', '$location', '$log'];

  function controller(FacetedSearch, $location, $log) {
    // This is our API.
    this.query  = { };
    this.result = null;
    this.run    = run;
    this.reset  = reset;

    this.rowRange = [];

    this.newQuery           = newQuery;
    this.queryField         = queryField;
    this.queryFieldAccessor = queryFieldAccessor;
    this.nonFacetFields     = ["freeform", "page", "rows"];
    this.numericFields      = [];

    this.toggleFacetValue     = toggleFacetValue;
    this.isFacetValueSelected = isFacetValueSelected;
    this.isRegionSelected     = isFacetValueSelected.bind(this, "region");

    this.sortFacet        = sortFacet;
    this.switchFacetSort  = switchFacetSort;
    this.nextFacetSort    = nextFacetSort;

    this.permalink        = null;

    this.init = init;


    // Implementations
    function newQuery() {
      return {
        rows: this.rowsPerPage || 12
      }
    }

    function init() {
      $log.debug("Initializing the faceted search controller");

      this.result = new FacetedSearch( this.endpoint );
      this.query  = this.newQuery();

      var query = angular.copy( $location.search() );

      if (query && Object.keys(query).length) {
        $log.debug("Loading initial query from URL params: ", query);

        // Force all parameter values into arrays, except single value fields
        // like freeform, page, and rows.
        for (var k in query) {
          if (this.nonFacetFields.includes(k) && this.numericFields.includes(k))
            query[k] = parseInt(query[k], 10);
          else if (!Array.isArray(query[k]) && !this.nonFacetFields.includes(k))
            query[k] = [ query[k] ];
        }
        this.query = query;
      }
      this.run();
    }

    function run() {
      var self  = this;
      var query = angular.copy(this.query);

      $log.debug("Running query: ", query);
      $location.search(query);
      $location.replace();

      this.permalink = $location.absUrl();

      return this.result.$get( query, function(result){

        Object.keys(result.facets).forEach(function(facet){
          // Ensure our currently active facet values are always included in
          // the UI, for a better UX.  If they're missing from the response, it
          // means they have a count of 0 and are no longer present in the
          // matched rows.
          if (query[facet]) {
            query[facet].forEach(function(queryValue) {

              var hasValue = 0 < result.facets[facet].values
                .filter(function(tuple){ return tuple[0] === queryValue })
                .length;

              if (!hasValue)
                result.facets[facet].values.push([queryValue, 0]);

            });
          }

          // Re-sort new facet values to keep a stable UI.
          self.sortFacet(facet);
        });

        self.hasQuery = 0 < Object.keys(query)
          .filter(function(k){ return k !== "rows" && k !== "page" })
          .map(function(k){ return query[k] })
          .filter(function(v){ return v != null && (Array.isArray(v) ? v : (v + "")).length > 0 })
          .length;

        self.hasFacets = 0 < Object.keys(result.facets)
          .map(function(k){ return result.facets[k].values })
          .filter(function(v){ return v != null && v.length > 0 })
          .length;

        // The UI doesn't currently allow you to change the number of
        // rows requested page, but it can be set as a URL parameter.
        // The current perPage also isn't equal to the length of
        // result.rows, because that number will be different on the
        // last page.
        var page      = query.page || 1;
        var perPage   = query.rows;
        var rowsStart = (page - 1) * perPage;
        self.rowRange = [
            rowsStart + 1,
            rowsStart + result.rows.length
        ];

      });
    }

    function reset() {
      this.query = this.newQuery();
      this.run();
    }

    function queryField(field, value) {
      if (arguments.length === 2 && value !== this.query[field]) {
        if (value == null || value === "")
          delete this.query[field];
        else
          this.query[field] = value;

        // reset to page 1 for new query
        delete this.query.page;
        this.run();
      }
      return (field in this.query)
        ? this.query[field]
        : null;
    }

    function queryFieldAccessor(field) {
      return this.queryField.bind(this, field);
    }

    function isFacetValueSelected(facet, value) {
      if (!this.query[facet])
        return false;

      // No value, so just "Is _any_ value for this facet selected?"
      if (arguments.length === 1)
        return this.query[facet].length > 0;

      // Are we currently limiting on this facet value?
      return this.query[facet].indexOf(value) >= 0;
    }

    function toggleFacetValue(facet, value) {
      if (!this.query[facet])
        this.query[facet] = []

      var values = this.query[facet];
      var idx    = values.indexOf(value);

      if (idx >= 0)
        values.splice(idx, 1);
      else
        values.push(value);

      // reset to page 1 for new query
      delete this.query.page;
      this.run();
    }

    // Sorting
    var sortState  = { };
    var sortFields = [
      { key: 1, reverse: true,  label: 'count' },
      { key: 0, reverse: false, label: 'name' }
    ];

    function nextFacetSort(facet) {
      var current = sortState[facet];
      if (!current)
        return sortFields[0];

      // Advance to next sortFields element, wrapping back to start at end
      var next = sortFields.indexOf( current ) + 1;
      return sortFields[ next % sortFields.length ];
    }

    function switchFacetSort(facet) {
      sortState[facet] = this.nextFacetSort(facet);
      this.sortFacet(facet);
    }

    function sortFacet(facet) {
      if (!sortState[facet])
        sortState[facet] = this.nextFacetSort(facet);

      var state = sortState[facet];

      this.result.facets[facet].values.sort(function(A,B){
        // A and B are (value, count) tuples and state.key determines which
        // element of the tuple to sort against.
        var a = A[state.key],
            b = B[state.key];

        if (typeof a === 'string') a = a.toLowerCase();
        if (typeof b === 'string') b = b.toLowerCase();

        // Empty values and nulls always go at end (or start if state.reverse)
        var cmp =
          (a === "" || a == null) ?  1 :
          (b === "" || b == null) ? -1 :
                            a < b ? -1 :
                            b < a ?  1 :
                                     0 ;

        return state.reverse ? cmp * -1 : cmp;
      });
    }
  }

})();
