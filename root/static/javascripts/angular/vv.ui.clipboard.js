(function(){
  'use strict';

  angular
    .module('vv.ui.clipboard', [
      'vv.ui'
    ])
    .directive('clipboardTarget', directive);

  directive.$inject = ['$timeout', '$log'];

  function directive($timeout, $log) {
    return {
      restrict: 'A',
      scope: true,
      link: function (scope, element, attrs) {
        // Unwrap Angular's jqLite layer
        element = element[0];

        // Copy attribute values into corresponding data-* attributes, which
        // Clipboard.js reads.
        element.dataset.clipboardTarget        = attrs.clipboardTarget;
        element.dataset.clipboardStripNewlines = attrs.clipboardStripNewlines;

        // Register Clipboard.js handler.
        let handler = new Clipboard(
          element, {
            text: function(trigger) {
              let text = this.target(trigger).textContent;

              if (trigger.dataset.clipboardStripNewlines != null)
                text = text.replace(/[\r\n]+/g, '');

              return text;
            }
          }
        );

        // Set status variable on our scope after copy
        handler.on("success", setStatus.bind(null, "success"));
        handler.on("error",   setStatus.bind(null, "error"));

        let pendingTimeout;

        function setStatus(status) {
          scope.$apply((scope) => {
            // Indicate status to our scope…
            scope.$copyStatus = status;

            // …but only temporarily
            $timeout.cancel(pendingTimeout);
            pendingTimeout = $timeout(() => { scope.$copyStatus = null }, 5000);
          });
        }

        $log.debug("Registered clipboard handler for ", element);
      }
    };
  }

})();
// vim: set ts=2 sw=2 :
