/////////////////////////////////////////////////////////////
//sets up a YUI Drag/Drop Object on the supplied table or tbody
//where multiple rows can be selected via Shift or Cmd/Ctrl click and
//dragged to the new location
///////////////////////////////////
//
//  REQUIRES
// drag_util.js
// YUI yahoo-dom-event.js
// YUI animation-min.js
// YUI dragdrop-min.js
/////////////////////
//Constructor Vars
///////////////////
// String parent_id the id of the  table or tbody element which contains the draggable rows
// String handle_className optional apply a class to tds you want to use as handles for highlighting and DD  if blank the whole row will be active.  This can reak havoc with form elements inside of active tds
function multiDDTable(parent_className, handle_className, config) {

var Dom = YAHOO.util.Dom;
var Event = YAHOO.util.Event;
var DDM = YAHOO.util.DragDropMgr;
var selrows = new Array();
var containers = document.getElementsByClassName(parent_className);
this.containers = containers;
this.parent_className = parent_className;
this.handle_className = handle_className;
 if(config){
    //rows marked with data-keep_in_table="true" attribute will be limited to thier source table this allows for a custum message to display in the drag proxy
    var keep_in_table_msg = config.keep_in_table_msg?config.keep_in_table_msg:"Rows Limited to Source Table";
 }

this.foo = 'bar';



//////////////////////////////////////////////////////////////////////////////
// Specify Target Table or Tbody and Load rows into the application
//////////////////////////////////////////////////////////////////////////////
    this.DDApp = {
        init: function() {
            for(var i = 0 ; i < containers.length ; i++){
                var container = containers.item(i);
                new YAHOO.util.DDTarget(container);           
                for (var idx = 0; idx < container.rows.length ; idx++) {
                    var id = container.rows[idx].id
                    if(!container.rows[idx].id || container.rows[idx].id == ""){
                        Dom.generateId(container.rows[idx]);
                    }
                    new YAHOO.MuiltiRowDD.DDList(container.rows[idx].id);
                }
            }
            
        },
    };
    
    //////////////////////////////////////////////////////////////////////////////
    // set up custom drag and drop implementation
    //////////////////////////////////////////////////////////////////////////////
    YAHOO.namespace("MuiltiRowDD");
    
    YAHOO.MuiltiRowDD.DDList = function(id, sGroup, config) {
    
        YAHOO.MuiltiRowDD.DDList.superclass.constructor.call(this, id, sGroup, config);
    
        this.logger = this.logger || YAHOO;
        this.goingUp = false;
        this.lastY = 0;
        this.srcCtr; //stores the container for the rows when they were grabbed
        this.remIdx //stores the indexes of the rows in the same order as the selrows array
        this.stayInSrcCtr = false; //boolian requiring that row collection remain in origional container;
        var el = this.getDragEl();
        
        if(handle_className && handle_className != ""){ // if classname of handle row passed then set it up
            var drag_head = this.getEl().getElementsByClassName(handle_className)[0];
           if(!drag_head.id){
               YAHOO.util.Dom.generateId(drag_head);
           }
           
           this.setHandleElId(drag_head.id);
        }
       
        Dom.setStyle(el, "opacity", 0.67); // The proxy is slightly transparent
    
    };
    
    YAHOO.extend(YAHOO.MuiltiRowDD.DDList, YAHOO.util.DDProxy, {
    
        startDrag: function(x, y) {
            this.logger.log(this.id + " startDrag");
            // make the proxy look like the source element
            var dragEl = this.getDragEl();
            var clickEl = this.getEl();
            this.srcCtr = clickEl.parentNode;
            var clickY = Dom.getY(clickEl);
            var dragElTxt = "<table>"; //must use string if you try and set innerHTML FF will append closing table tag and ignore tr and td tags below.
            this.remIdx = new Array();
            var constrain_movement = false;
            for (var i =0 ; i < this.srcCtr.rows.length ; i++){ //loop through table and grab all selected rows. 
                      if (this.srcCtr.rows[i].className.search(/selected/) > -1){
                            dragElTxt += "<tr>" + this.srcCtr.rows[i].innerHTML + "</tr>"; //append 'selected' row's contents to mobile element's table
                            YAHOO.util.Dom.removeClass(this.srcCtr.rows[i], 'selected');
                            selrows.push(this.srcCtr.rows[i]); //save rows for later
                            this.remIdx.push(i);
                            if (this.srcCtr.rows[i].getAttribute('data-keep_in_table')){
                                constrain_movement = true;
                            }
                      }
            }
            for(var i = 0 ; i < selrows.length ; i++){//remove rows from table;
                      //this.srcCtr.deleteRow(this.remIdx[i]);
                      this.srcCtr.removeChild(selrows[i]);
            }
               
           dragElTxt += "</table>";
              dragEl.innerHTML = dragElTxt;
    
            if(constrain_movement && containers.length > 1){ //keep rows in src table if required and more than one table is present
                    var maxUp = clickY - Dom.getY(this.srcCtr);
                    var maxDown = (Dom.getY(this.srcCtr) + this.srcCtr.offsetHeight) - clickY;
                    this.setYConstraint(maxUp, maxDown);
                    var caption = document.createElement('caption');
                    caption.innerHTML = keep_in_table_msg;
                    with (caption.style){
                        fontWeight = 'bold',
                        fontSize = '1.5em',
                        opacity = 1.0,
                        color = 'White',
                        backgroundColor = '#1f669b';
                    }
                    var proxyTable = dragEl.getElementsByTagName('table').item(0);
                    proxyTable.insertBefore(caption, proxyTable.firstChild );
            }
             
            Dom.setStyle(clickEl, "visibility", "hidden");
            Dom.setStyle(dragEl, "color", Dom.getStyle(clickEl, "color"));
            Dom.setStyle(dragEl, "backgroundColor", Dom.getStyle(clickEl, "backgroundColor"));
            Dom.setStyle(dragEl, "border", "2px solid gray");
            
        },
    
        endDrag: function(e) {
    
            var srcEl = this.getEl();
            var proxy = this.getDragEl();
            var refRow = document.getElementById(this.id);
    
            // Show the proxy element and animate it to the src element's location
            Dom.setStyle(proxy, "visibility", "");
            var a = new YAHOO.util.Motion( 
                proxy, { 
                    points: { 
                        to: Dom.getXY(srcEl)
                    }
                }, 
                0.2, 
                YAHOO.util.Easing.easeOut 
            )
            var proxyid = proxy.id;
            var thisid = this.id;
    
            // Hide the proxy and show the source element when finished with the animation
            a.onComplete.subscribe(function() {
                    Dom.setStyle(proxyid, "visibility", "hidden");
                    Dom.setStyle(thisid, "visibility", "");
                });
            a.animate();
            if(refRow){
                var holder = refRow.nextSibling;
                while(selrows.length > 0){
                    srcEl.parentNode.insertBefore(selrows.shift(), holder);
               }
               
               if(srcEl.parentNode.id != this.srcCtr.id){
                    renumberLanes(this.srcCtr);
               }
               renumberLanes(srcEl.parentNode);
            }else{
                while(selrows.length > 0){
                    var idx = this.remIdx.shift();
                    YAHOO.util.Dom.addClass(selrows[0], 'selected');
                    if(idx < this.srcCtr.rows.length){
                        this.srcCtr.insertBefore(selrows.shift(), this.srcCtr.rows[idx]);
                    }else{ //was last row
                        this.srcCtr.appendChild(selrows.shift());
                    }
               }
            }   
               
               proxy.innerHTML = "";
              
        },
    
        onDragDrop: function(e, id) {
    
            // If there is one drop interaction, the tr was dropped either on the table,
            // or it was dropped on the current location of the source element.
            if (DDM.interactionInfo.drop.length === 1) {
    
                // The position of the cursor at the time of the drop (YAHOO.util.Point)
                var pt = DDM.interactionInfo.point; 
    
                // The region occupied by the source element at the time of the drop
                var region = DDM.interactionInfo.sourceRegion; 
    
                // Check to see if we are over the source element's location.  We will
                // append to the bottom of the table once we are sure it was a drop in
                // the negative space (the area of the table without any rows)
                if (!region.intersect(pt)) {
                    var destEl = Dom.get(id);
                    var destDD = DDM.getDDById(id);
                    destEl.appendChild(this.getEl());
                    destDD.isEmpty = false;
                    DDM.refreshCache();
                }
    
            }
        },
    
        onDrag: function(e) {
    
            // Keep track of the direction of the drag for use during onDragOver
            var y = Event.getPageY(e);
    
            if (y < this.lastY) {
                this.goingUp = true;
            } else if (y > this.lastY) {
                this.goingUp = false;
            }
            this.lastY = y;
        },
    
        onDragOver: function(e, id) {
        
            var srcEl = this.getEl();
            var destEl = Dom.get(id);
    
            // We are only concerned with table rows, we ignore the dragover
            // notifications for other parts of the table.
            if (destEl && destEl.nodeName.toLowerCase() == "tr") {
                var orig_p = srcEl.parentNode;
                var p = destEl.parentNode;
    
                if (this.goingUp || destEl.sectionRowIndex == 0) {
                    p.insertBefore(srcEl, destEl); // insert above
                } else {
                    p.insertBefore(srcEl, destEl.nextSibling); // insert below
                }
    
                DDM.refreshCache();
            }
        }
    });
    this.DDApp.init();
    this.activateHandles();
}


//automatically add onclick eventhandle to mark lanes with the given class name;
 multiDDTable.prototype.activateHandles = function(ctr){
    var handles;
    var mDDTable = this;
    if(!this.handle_className || this.handle_className == ''){  //if no handle className stored use the rows for drag/drop
        if(ctr && ctr.tagName && ctr.tagName.toLowerCase() == 'tr'){ //if tr passed (e.g. via addRow() ) just activate it;
            handles = new NodeList(ctr);
        }else{ //need to deal with multiple tables but for now just grab first one
            handles = this.containers[0].rows; 
        }
    }else{ // activae TDs with handle_ClassName
        if(!ctr){
            handles = document.getElementsByClassName(this.handle_className);
        }else{
             handles = ctr.getElementsByClassName(this.handle_className);
        }
    }
    for(var i = 0 ; i < handles.length ; i++){
            handles.item(i).addEventListener("click" , function (e){selectMultiple(e, true);}, false);
    }
 };
 
 //add a newly created row to the table/tbody
multiDDTable.prototype.addRow = function(row, tbod){
    document.getElementById(tbod).appendChild(row);
    this.activateHandles(row);
    new YAHOO.MuiltiRowDD.DDList(row.id);  
};
