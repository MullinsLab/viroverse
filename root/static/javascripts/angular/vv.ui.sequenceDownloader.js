(function(){
  'use strict';

  // A widget for downloading sequences.  It interfaces with the server
  // endpoints /download/sequences and /download/sidebar/sequences.
  //
  // The latter endpoint is used if the "sidebar" attribute is an expression
  // which evalutes truthily.  In this case, the server endpoint returns the
  // sequences saved in the current session's sidebar cart.
  //
  // The former endpoint expects an seq_ids form input is associated with the
  // form.  This parameter may be specified more than once and/or be
  // comma-separated.  The sequence IDs listed will be the ones returned.
  //
  // Use the "form" attribute of this component to set the id of the produced
  // form.  You may then link in other related form inputs and buttons by
  // specifying the same "form" attribute on them.
  //
  // Basic usage:
  //
  //   <sequence-downloader form="sequence-downloader"></sequence-downloader>
  //   <input type="hidden" form="sequence-downloader" name="seq_ids" value="...">
  //   <button type="submit" form="sequence-downloader">
  //     Download
  //   </button>
  //
  angular
    .module('vv.ui.sequenceDownloader', [
      'vv.ui',
      'vv.http'
    ])
    .component('sequenceDownloader', {
      templateUrl: viroverse.url_base + '/static/partials/sequence/downloader.html',
      controller: controller,
      controllerAs: '$ctrl',
      bindings: {
        form: '@',
        sidebar: '<?'
      }
    });

  controller.$inject = ['$resource', '$log'];

  function controller($resource, $log) {
    this.endpoint = function(){
      return viroverse.url_base + 'download/' + (
        this.sidebar
          ? 'sidebar/sequences'
          : 'sequences'
      );
    };

    var SequenceNameParts = $resource(
      viroverse.url_base + 'sequence/name_parts', {}, {
        get: { method: 'GET', isArray: true }
      }
    );

    this.nameParts = SequenceNameParts.get();
  }

})();
