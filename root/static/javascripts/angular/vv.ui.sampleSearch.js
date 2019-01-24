// vim: set sw=2 ts=2 :
(function(){
  'use strict';

  angular
    .module('vv.ui.sampleSearch', [
      'vv.ui'
    ])
    .directive('sampleSearch', directive)
    .directive('hasSequencesToggle', subdirective('has-sequences-toggle', { orientation: '@?' }))
    .directive('viralLoadToggle', subdirective('viral-load-toggle', { orientation: '@?' }))
    .directive('aliquotsInput', subdirective('aliquots-input', { orientation: '@?' }))
  ;

  directive.$inject = ['$log'];

  function directive($log) {
    return {
      restrict: 'A',
      require: 'facetedSearch',
      link: function(scope, element, attrs, ctrl) {
        $log.debug("Initializing sample search");

        scope.uiTemplate =
          "/static/partials/sample/search/"
            + (attrs.sampleSearchUi || "full-page")
            + ".html";

        // Configure our additional non-facet fields
        ctrl.nonFacetFields.push("has_sequences", "has_quantifiable_viral_load",
                                 "has_available_aliquots");
        ctrl.numericFields.push("has_available_aliquots");

        // Augment the parent controller with additional methods for our
        // template.
        ctrl.isCohortSelected    = ctrl.isFacetValueSelected.bind(ctrl, 'cohort');
        ctrl.isProjectSelected   = ctrl.isFacetValueSelected.bind(ctrl, 'project');
        ctrl.isScientistSelected = ctrl.isFacetValueSelected.bind(ctrl, 'scientist');
        ctrl.minAvailableAliquots = minAvailableAliquots;

        ctrl.init();
      },
      template: '<ng-include src="uiTemplate"></ng-include>'
    };
  }

  function minAvailableAliquots(value) {
    if (arguments.length === 1) {
      if (value === 0) {
        value = null;
      }
      return this.queryField('has_available_aliquots', value);
    } else {
      return this.queryField('has_available_aliquots');
    }
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
        templateUrl: viroverse.url_base + '/static/partials/sample/search/' + name + '.html'
      };
    }
    return subdir;
  }

})();
