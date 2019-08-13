// vim: set sw=2 ts=2 :
(function(){
  'use strict';

  angular
    .module('vv.ui.gelSearch', [
      'vv.ui'
    ])
    .directive('gelSearch', directive)
  ;

  directive.$inject = ['$window'];

  function directive($window) {
    return {
      restrict: 'A',
      require: 'facetedSearch',
      link: function(scope, element, attrs, ctrl) {

        scope.uiTemplate =
          "/static/partials/gel/search/"
            + (attrs.sequenceSearchUi || "full-page")
            + ".html";

        ctrl.init();
      },
      template: '<ng-include src="uiTemplate"></ng-include>'
    };
  }

})();
