// vim: set sw=2 ts=2 :
(function(){
  'use strict';

  angular
    .module('vv.ui.pacbioPoolSearch', [
      'vv.ui'
    ])
    .directive('pacbioPools', directive)
  ;

  directive.$inject = ['$window'];

  function directive($window) {
    return {
      restrict: 'A',
      require: 'facetedSearch',
      link: function(scope, element, attrs, ctrl) {

        scope.uiTemplate = "/static/partials/pacbio/search.html";

        ctrl.init();
      },
      template: '<ng-include src="uiTemplate"></ng-include>'
    };
  }

})();
