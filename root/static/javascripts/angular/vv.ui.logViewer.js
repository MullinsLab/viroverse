(function(){
  'use strict';

  angular
    .module('vv.ui.logViewer', [
      'vv.ui'
    ])
    .component('logViewer', {
      templateUrl: viroverse.url_base + '/static/partials/log-viewer.html',
      controller: controller,
      controllerAs: '$ctrl',
      bindings: {
        messages: '<?',
        url: '@?'
      }
    });

  controller.$inject = ['$http', '$log'];

  function controller($http, $log) {
    this.$onInit = function() {
      if (!this.messages)
        this.messages = [];

      if (this.url) {
        $http.get(this.url).then(
          r => { this.messages = r.data },
          r => { $log.error("Failed to fetch " + this.url + ":", r) }
        );
      }
    }
  }

})();
