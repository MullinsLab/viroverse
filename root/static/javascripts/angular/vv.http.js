(function(){
  'use strict';

  // Viroverse-specific HTTP transforms for talking to our API endpoints.
  angular
    .module('vv.http', [
      'ngResource'
    ])
    .config(configure);

    configure.$inject = ['$httpProvider'];

    function configure($httpProvider) {
      if (!$httpProvider.defaults.headers.get)
          $httpProvider.defaults.headers.get = {};
      $httpProvider.defaults.headers.get['Cache-Control'] = 'no-cache';
      $httpProvider.defaults.headers.get['Pragma']        = 'no-cache';
    }

})();
