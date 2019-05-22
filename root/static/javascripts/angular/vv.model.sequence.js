(function(){
  'use strict';

  angular
    .module('vv.model.sequence', [
      'ngResource'
    ])
    .factory('Sequence', factory);

  factory.$inject = ['$resource'];

  function factory($resource) {
    return $resource(viroverse.url_base + '/sequence/:id', {}, {
        delete: { method: 'DELETE', url: viroverse.url_base + '/sequence/:id?reason=:reason' },
    });
  }

})();
