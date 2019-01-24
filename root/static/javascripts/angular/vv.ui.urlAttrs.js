(function(){
  'use strict';

  // vv-src, vv-srcset, vv-href are interpolated attributes which we handle
  // specially to prepend the base path.  The directive definition code
  // (property object + link function) below is modified from ngHref et al.
  // provided by Angular's core:
  //
  //    https://github.com/angular/angular.js/blob/v1.5.x/src/ng/directive/attrs.js#L402-L438
  //
  // -trs, 12 Dec 2016
  angular
    .module('vv.ui.urlAttrs', [])
    .directive({
      vvHref:   directive('href',   'vvHref'),
      vvSrc:    directive('src',    'vvSrc'),
      vvSrcset: directive('srcset', 'vvSrcset')
    });

  function directive(attrName, directiveName) {
    // Borrowed from core Angular:
    //    https://github.com/angular/angular.js/blob/v1.5.0/src/Angular.js#L167-L171
    //
    // documentMode is an IE-only property.
    var msie = document.documentMode;

    return function() {
      return {
        restrict: 'A',
        priority: 99, // it needs to run after the attributes are interpolated
        link: function(scope, element, attr) {
          attr.$observe(directiveName, function(value) {
            if (!value) {
              if (attrName === 'href') {
                attr.$set(attrName, null);
              }
              return;
            }

            // Prepend the Viroverse base path, replacing any optional
            // leading slash so we don't double up.
            if (value != null)
              value = value.replace(/^\/?/, viroverse.url_base);

            attr.$set(attrName, value);

            // Support: IE 9-11 only
            // On IE, if "ng:src" directive declaration is used and "src" attribute doesn't exist
            // then calling element.setAttribute('src', 'foo') doesn't do anything, so we need
            // to set the property as well to achieve the desired effect.
            // We use attr[attrName] value since $set can sanitize the url.
            if (msie) element.prop(attrName, attr[attrName]);
          });
        }
      };
    };
  }

})();
