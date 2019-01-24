// vim: set sw=2 ts=2 :
(function(){
  'use strict';

  angular
    .module('vv.ui.sequenceSearch', [
      'vv.ui'
    ])
    .directive('sequenceSearch', directive)
  ;

  directive.$inject = ['$window'];

  function directive($window) {
    return {
      restrict: 'A',
      require: 'facetedSearch',
      link: function(scope, element, attrs, ctrl) {

        scope.uiTemplate =
          "/static/partials/sequence/search/"
            + (attrs.sequenceSearchUi || "full-page")
            + ".html";

        // Augment the parent controller with an additional method for our
        // template.
        ctrl.isRegionSelected = ctrl.isFacetValueSelected.bind(ctrl, 'region');
        ctrl.addToSidebar = function(ids) {
          $window.sidebar_add('dna_sequence', ids, null, []);
        };

        ctrl.init();
      },
      template: '<ng-include src="uiTemplate"></ng-include>'
    };
  }

})();
