///////////////////////////////////////
// drag_util.js
// Utility functions for YUI darg and drop applications
///////////////////////////////////////
// Dependencies from YUI
// yahoo-min.js
// dom-min.js
// event-min.js
//////////////////////


//////////////////////////////
//  selectMultiple Event Handeler
//  Uses Shift or Cmd/Ctrl click to select multiple items in a supplied container element
/////// Variables ////////////
// ev       JS Event  
// use_parent   Bool      apply selected class to the clicked element or it's parent (e.g. for tables event is fired by td but selected class is applied to tr);
///////////////////////////////////////////////////////////////
function selectMultiple(ev, use_parent){
    var Dom = YAHOO.util.Dom,
        Event = YAHOO.util.Event;
  
    var dd = null;
    var tar = Event.getTarget(ev);
    if(use_parent){
        tar = tar.parentNode;
    } 
    var kids = tar.parentNode.getElementsByTagName(tar.tagName);
    //Event.stopEvent(ev);
    //If the shift key is pressed, add it to the list
    if (ev.metaKey || ev.ctrlKey) {
    if (tar.className.search(/selected/) > -1) {
        Dom.removeClass(tar, 'selected');
    } else {
        Dom.addClass(tar, 'selected');
    }
    }else if(ev.shiftKey) {
    var sel = false;
    for (var i = 0 ; i < kids.length ; i++){
        if(!sel && kids.item(i).className.search(/selected/) > -1){
        sel = true;
        }
        if(sel){
        Dom.addClass(kids.item(i), 'selected');
        }
        if(kids.item(i) == tar){ // shift clicked elem reached
            if(!sel){ //selection either below or no other row selected
                    for (var ii = i ; ii < kids.length ; ii++){
                        if(!sel && kids.item(ii).className.search(/selected/) > -1){
                            sel = true;
                        }else if(sel && kids.item(ii).className.search(/selected/) == -1){
                            break;
                        }
                        Dom.addClass(kids.item(ii), 'selected');
                    }
                    if(!sel){ //no second row selected
                        for (var ii = i + 1 ; i < kids.length ; i++){
                            Dom.removeClass(kids.item(ii), 'selected');
                        }
                    }
                }
                    break; 
            }
    }
    }else {
    for (var i = 0 ; i < kids.length ; i++){
        kids.item(i).className = '';
    }
    Dom.addClass(tar, 'selected');
    }
    
    //clear any highlighted text from the defualt shift-click functionality
    clearSelection();
}