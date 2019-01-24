(function(){
  'use strict';

  // The goal of this directive is to enable views (templates) to use simple
  // Bootstrap modals without cooperation from their controller.  This frees
  // the controller from shim functions which don't directly pertain to its
  // business logic.
  //
  // The modal-on-click attributes serves to both bind this directive and
  // specify the template to use for the modal.  It is an expression, so static
  // strings should be enclosed in single quotes.  If the template path starts
  // with a /, then the global Viroverse base path will be prepended.  This
  // frees templates from hard-coding the base path.
  //
  // Basic usage:
  //
  //   <a modal-on-click="'download-modal.html'">
  //     <span class="glyphicon glyphicon-save"></span>
  //     Download results
  //
  //     <script type="text/ng-template" id="download-modal.html">
  //       <div class="modal-header">
  //         <h3 class="modal-title">Download</h3>
  //       </div>
  //       <div class="modal-body" id="modal-body">
  //         ...
  //       </div>
  //       <div class="modal-footer">
  //         <button class="btn btn-primary" type="submit" ng-click="$close()">Download</button>
  //         <button class="btn btn-link btn-sm" ng-click="$dismiss()">Close</button>
  //       </div>
  //     </script>
  //   </a>
  //
  // The scope of the modal is determined/augmented by $uibModal.  You likely
  // want to read its docs.
  angular
    .module('vv.ui.modalOnClick', [
      'ui.bootstrap'
    ])
    .directive('modalOnClick', directive);

  directive.$inject = ['$uibModal', '$parse', '$log'];

  function directive($uibModal, $parse, $log) {
    return {
      restrict: 'A',
      link: function (scope, element, attrs) {
        var modalUrl = $parse(attrs.modalOnClick);

        // Guarantee that the modal will be under a .bootstrapped element so
        // things work.
        var appendTo = document.createElement("div");
        appendTo.classList.add("bootstrapped", "modal-on-click");
        document.body.appendChild(appendTo);
        appendTo = angular.element(appendTo);

        element.on('click', function(){
          var templateUrl = modalUrl(scope);
          if (templateUrl.match(/^\//))
            templateUrl = viroverse.url_base + templateUrl;

          $log.debug("Opening modal for: ", templateUrl);
          $uibModal.open({
            templateUrl: templateUrl,
            appendTo: appendTo
          });
        });
      }
    };
  }

})();
