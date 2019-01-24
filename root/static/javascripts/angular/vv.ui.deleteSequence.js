(function(){
  'use strict';

  angular
    .module('vv.ui.deleteSequence', [
      'vv.ui',
      'vv.model.sequence'
    ])
    .controller('DeleteSequence', controller);

  controller.$inject = ['$scope', 'Sequence', '$log'];

  function controller($scope, Sequence, $log) {
    $scope.delete = function() {
      Sequence.delete(
        { id: $scope.id, reason: $scope.reason },
        null,
        function(value, getHeaders) {
          var container = document.querySelector('main.bootstrapped');
          if (container) {
            gray_overlay(container);
          }
          document.body.scrollTop = 0;
          document.location.reload();
        },
        function(response) {
          $scope.error = response.data.message;
          $log.error(response);
        }
      );
    };
  }

})();
