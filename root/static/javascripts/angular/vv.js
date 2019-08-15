(function(){
  'use strict';

  // Overall app-level module which pulls in other things and sets up defaults.
  angular
    .module('vv', [
      'vv.http',
      'vv.filters',
      'vv.ui',
      'vv.ui.facetedSearch',
      'vv.ui.primerSearch',
      'vv.ui.gelSearch',
      'vv.ui.sampleSearch',
      'vv.ui.sequenceSearch',
      'vv.ui.sequenceDownloader',
      'vv.ui.logViewer',
      'vv.ui.labLines',
      'vv.ui.locationHash',
      'vv.ui.clipboard'
    ])
    .config(configure)
    .run(init);

  configure.$inject = ['$compileProvider', '$locationProvider', '$anchorScrollProvider'];

  function configure($compileProvider, $locationProvider, $anchorScrollProvider) {
    // Configure $location and $anchorScroll to stay out of the way of normal
    // URL and HTML anchors.  We use them only in a very limited fashion, not
    // as an app-wide link/routing mechanism.
    $locationProvider.html5Mode({
      enabled: true,
      requireBase: false,
      rewriteLinks: false
    });
    $anchorScrollProvider.disableAutoScrolling();
  }

  init.$inject = ['$log'];

  function init($log) {
    $log.debug("Starting up vv.js!");
  }

})();
