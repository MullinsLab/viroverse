(function(){
  'use strict';

  angular
    .module('vv.filters', [])

    // Map over an array selecting properties from an Object.  It's crazy to me
    // that the standard lib of filters and even angular-filter don't provide a
    // way to do this out of the box.  The "map" filter would work as-is if
    // there was a native function (instead of only operators) for retreiving
    // an Object property value.
    // -trs, 9 March 2016
    //
    // Copied from TCozy.
    // -trs, 30 November 2016
    .filter('selectFrom', [function() {
      return function (array, object) {
        if (object == undefined)
          return undefined;

        return array.map(function(k) {
          return object[k];
        });
      }
    }]);

})();
