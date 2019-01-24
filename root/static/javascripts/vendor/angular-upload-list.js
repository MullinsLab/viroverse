(function(){
  'use strict';

  angular
    .module('upload-list', [])
    .directive('uploadList', [() => ({
      restrict: 'C',
      controller: ['$element', $element => new UploadList($element[0])]
    })]);

})();
// vim: set ts=2 sw=2 :
