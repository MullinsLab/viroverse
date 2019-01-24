(function(){
  'use strict';

  angular
    .module('vv.ui.locationHash', [
      'vv.ui'
    ])
    .controller('LocationHash', controller);

  controller.$inject = ['$scope', '$location', '$log'];

  function controller($scope, $location, $log) {
    // Update our own property when the location changes, normalizing the empty
    // string to null for more reasonable semantics by consumers of this
    // controller.  $location.hash() returns the empty string even when there
    // is no hash and we don't care to distinguish between no hash and an empty
    // hash.
    $scope.$watch(
      ()      => $location.hash().length > 0 ? $location.hash() : null,
      (value) => {
        // Treat undefined and null as equal by using != instead of !==.  Our
        // property starts off as undefined.
        if (this.value != value)
          this.value = value;
      }
    );

    // Update the location when our property changes, normalizing null and
    // undefined to the empty string for easier comparison to the current
    // $location.hash().  Setting the hash to null or undefined is the same as
    // setting it to the empty string.
    $scope.$watch(
      ()      => this.value != null ? this.value : '',
      (value) => {
        // $location won't use the History API's replaceState() if only the
        // hash has changed (in order to avoid a bug on IE); instead it uses
        // location.replace().¹  This has the side effect of reloading the page
        // when we clear the hash (i.e. set it to the empty string) instead of
        // just removing the hash without a reload.  By forcing the state to
        // change as well (which we luckily don't care about), we can force it
        // to use the History API.  An alternative workaround would be to use
        // $location for reading values but write values directly using the
        // History API ourselves.  That seemed slightly worse than this
        // workaround, but maybe the future will tell otherwise.
        //
        // ¹ https://github.com/angular/angular.js/blob/v1.5.8/src/ng/browser.js#L146-L169
        if (value !== $location.hash())
          $location.replace().hash(value).state(value);
      }
    );
  }

})();
// vim: set ts=2 sw=2 :
