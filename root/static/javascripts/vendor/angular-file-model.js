(function(){
  'use strict';

  angular
    .module('file-model', [])
    .directive('fileModel', fileModel)
    .directive('fileDrop', fileDrop);


  fileModel.$inject = ['$parse', '$log'];

  function fileModel($parse, $log) {
    return {
      restrict: 'A',
      link: function (elementScope, element, attrs, ctrl) {
        let update = generateUpdater("file-model", attrs, $parse, $log);

        element.bind('change', () => {
          // Do nothing if we have no files, else update.
          if (!element[0].files)
            return;

          update(elementScope, element[0].files);

          // Reset the input value so the event is triggered on every file
          // selection, not just if the filename changed.  This is
          // important for two reasons:
          //
          // 1. The file may have changed on disk, behooving us to reload
          //    it, and since we're rendering locally there's little penalty
          //    in re-reading and rendering the file.
          //
          // 2. With the addition of another file selection method (drag
          //    and drop), this input may be seen as unchanged even if the
          //    currently loaded file in the app doesn't match the input
          //    value.  For example, try loading file A with the file chooser,
          //    then file B with drag and drop, and then reloading file A
          //    again with the file chooser.  Without this reset, nothing
          //    would happen.
          //
          element[0].value = null;
        });
      }
    }
  }


  fileDrop.$inject = ['$parse', '$log'];

  function fileDrop($parse, $log) {
    return {
      restrict: 'A',
      link: function (elementScope, element, attrs, ctrl) {
        let update = generateUpdater("file-drop", attrs, $parse, $log);

        // Prevent default to allow drag
        element.bind("dragover", (ev) => { ev.preventDefault() });

        // Highlight the dropzone
        element.bind("dragenter", (ev) => {
          ev.currentTarget.classList.add("file-drop-hover");
        });

        // Remove dropzone highlight when we leave the dropzone for good.  If
        // we're leaving a child element or leaving the dropzone but entering a
        // child element, then we're not actually leaving in the sense we care
        // about.
        element.bind("dragleave", (ev) => {
          let leaving  = ev.target,
              entering = ev.relatedTarget,
              dropzone = ev.currentTarget;

          if (leaving === dropzone && !dropzone.contains(entering))
            dropzone.classList.remove("file-drop-hover");
        });

        // Handle drop
        element.bind("drop", (ev) => {
          ev.preventDefault();
          ev.currentTarget.classList.remove("file-drop-hover");
          update(elementScope, ev.dataTransfer.files);
        });
      }
    }
  }


  function generateSetter(expr, valueName) {
    if (expr)
      if (expr.assign)
        return expr.assign;
      else
        return (scope, value) => { expr(scope, { [valueName]: value }) };
    else
      return null;
  }


  function generateUpdater(directiveName, attrs, $parse, $log) {
    var directiveAttr   = attrs.$normalize(directiveName);
    var fileModel       = attrs[directiveAttr] ? $parse(attrs[directiveAttr]) : null;
    var nameModel       = attrs.fileName       ? $parse(attrs.fileName)       : null;
    var dataModel       = attrs.fileData       ? $parse(attrs.fileData)       : null;
    var dataAs          = attrs.fileDataAs || "DataURL";
    var fileModelSetter = generateSetter(fileModel, "file");
    var nameModelSetter = generateSetter(nameModel, "name");
    var dataModelSetter = generateSetter(dataModel, "data");

    if (!fileModelSetter && !nameModelSetter && !dataModelSetter) {
      $log.error("<input " + directiveName + "> without binding a model to any supported attribute is useless; ignoring this element");
      return;
    }

    if ('multiple' in attrs)
      $log.warn("<input " + directiveName + "> doesn't support the 'multiple' attribute; using the first file");

    return function update(elementScope, files) {
      var file = files[0];

      function updateModel(scope, data) {
        if (fileModelSetter)
          fileModelSetter(scope, file);
        if (nameModelSetter)
          nameModelSetter(scope, file ? file.name : null);
        if (dataModelSetter)
          dataModelSetter(scope, data);
      }

      if (dataModelSetter && file) {
        // Read the file and then set the model only on success
        var reader = new FileReader();
        reader.onloadend = function(){
          var data = this.result;
          elementScope.$apply(function(scope){
            updateModel(scope, data);
          });
        };
        reader.onerror = function(){
          $log.error("Error reading file upload: ", this.error);
        };

        reader["readAs" + dataAs](file);
      } else {
        // No need to read the File object
        elementScope.$apply(updateModel);
      }
    }
  }

})();
// vim: set ts=2 sw=2 :
