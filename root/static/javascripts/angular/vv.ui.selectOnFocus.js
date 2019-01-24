(function(){
  'use strict';

  angular
    .module('vv.ui.selectOnFocus', [])
    .directive('selectOnFocus', directive);

  directive.$inject = ['$window'];

  function directive($window) {
    return {
      restrict: 'A',
      link: function (scope, element, attrs) {
        element.on('focus', function(){
          this.select();
        });
      }
    };
  }

})();
