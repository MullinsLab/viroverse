(function(){
  'use strict';

  // This module is a collection point for pulling in UI-related dependencies,
  // usually external.
  angular
    .module('vv.ui', [
      'angular.filter',
      'ui.bootstrap',
      'upload-list',
      'file-model',
      'vv.ui.selectOnFocus',
      'vv.ui.modalOnClick',
      'vv.ui.sortable',
      'vv.ui.urlAttrs'
    ]);

})();
