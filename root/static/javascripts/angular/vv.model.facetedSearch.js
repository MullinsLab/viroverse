// Use the $resource-like pattern of returning an empty object and filling it
// in after the response comes back, but provide a way to cancel previous
// requests unlike $resource.
//
// vim: set sw=2 ts=2 :
(function(){
  'use strict';

  angular
    .module('vv.model.facetedSearch', [])
    .factory('FacetedSearch', factory);

  factory.$inject = ['$http', '$q', '$log'];

  // The factory produces a FacetedSearch constructor which can be instantiated
  // to produce a FacetedSearch result object for a given endpoint.  The result
  // object has methods and properties on it similar to $resource.
  function factory($http, $q, $log) {

    function FacetedSearch(endpoint) {
      this.$resolved = false;
      this.endpoint  = endpoint.match(/^https?:/i)
        ? endpoint
        : viroverse.url_base + endpoint;
      return this;
    }


    // $get method takes a query object and an optional callback to receive the
    // current object on success (imitating $resource).  Any outstanding
    // requests are cancelled before making a new one (unlike $resource).
    FacetedSearch.prototype.$get = function(query, success) {
      var result = this;
      this.$cancelRequest();

      var options = {
        params: angular.copy(query),
        timeout: this.$canceller.promise
      };

      this.$promise = $http.get(this.endpoint, options).then(
        function(response) {
          result.$resolved = true;

          // Extend ourselves with the new data
          angular.extend(result, response.data);

          if (success)
            success(result);

          return response;
        },
        function(response) {
          // Cancelled requests are status === -1
          if (response.status !== -1) {
            $log.error("Failed to perform faceted search: ", response);
            result.$resolved = true;
          }
          return $q.reject(response);
        }
      );
    };


    // $cancelRequest method to explicitly end any outstanding request.
    FacetedSearch.prototype.$cancelRequest = function() {
      if (this.$canceller)
        this.$canceller.resolve();
      this.$canceller = $q.defer();
    };

    return FacetedSearch;
  }

})();
