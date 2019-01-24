(function(){
  'use strict';

  angular
    .module('vv.model.sequence', [
      'ngResource'
    ])
    .factory('Sequence', factory);

  factory.$inject = ['$resource'];

  function factory($resource) {
    return $resource(viroverse.api_base + '/sequence/:id', {}, {
        delete: { method: 'DELETE', url: viroverse.api_base + '/sequence/:id?reason=:reason' },
    });
  }

})();
