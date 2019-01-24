(function(){
  'use strict';

  // A thin wrapper around Sortable.js, which must be loaded before this
  // module.  Usage is as follows:
  //
  //    <ul sortable="{ sortable: "li", ghostClass: "ghost" }">
  //      <li ng-repeat="item in ['apples', 'pears', 'oranges', 'figs', 'dates']">
  //        {{ item }}
  //      </li>
  //    </ul>
  //
  // Where the "sortable" attribute takes an optional expression which should
  // evaluate to a configuration object to pass into Sortable.js's constructor.
  //
  // Be warned that this doesn't currently rebind Sortable.js if sortable
  // elements are added/removed dynamically, so if you do that it probably
  // won't work correctly.¹  It is currently intended only for static sortable
  // lists (like the example above, where the output set ng-repeat produces is
  // static).
  //
  // ¹ Though depending on Sortable.js's implementation, it might!  Try it out. :-)
  angular
    .module('vv.ui.sortable', [])
    .directive('sortable', directive);

  directive.$inject = ['$parse', '$log'];

  function directive($parse, $log) {
    return {
      restrict: 'A',
      link: function (scope, element, attrs) {
        // Optional config on same attribute that triggers this directive
        var config = $parse(attrs.sortable)(scope) || {};

        if (!angular.isObject(config) || angular.isArray(config)) {
          $log.error("Attribute 'sortable' on element ", element[0], " should be an Object.  Ignoring value: ", angular.copy(config));
          config = {};
        } else {
          $log.debug("Making Sortable with: ", config);
        }

        scope.$sortable = new Sortable(element[0], angular.copy(config));
      }
    };
  }

})();
