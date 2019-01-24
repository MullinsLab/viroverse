// based on http://developer.yahoo.com/yui/examples/dragdrop/js/DDPlayer.js
var in_drag = new Array;
var targets = new Array;

drag_label = function (id, sGroup, config, orig_parent_id) {
    this.init_label(id, sGroup, config, orig_parent_id)
}

YAHOO.extend(drag_label, YAHOO.util.DD);

drag_label.prototype.init_label = function(id, sGroup, config, orig_parent_id) {
    if (!id) { return; }

    this.init(id, sGroup, config);
    this.startPos = YAHOO.util.Dom.getXY(this.getEl());
    this.orig_parent_id = orig_parent_id;

    inp = document.createElement('input');
    inp.setAttribute('type','hidden');
    inp.setAttribute('name','label-'+this.id);

    this.input_el = inp;
};

drag_label.prototype.startDrag = function(x,y) {
    for (var i; i< targets.length; i++) {
        targets[i].getEl().className = "targetActive"
    }
}

drag_label.prototype.endDrag = function(x,y) {
    for (var i; i< targets.length; i++) {
        targets[i].getEl().className = "targetInactive"
    }

}

drag_label.prototype.onDragDrop = function (e,id) {
     // get the drag and drop object that was targeted
    var oDD;
    
    if ("string" == typeof id) {
        oDD = YAHOO.util.DDM.getDDById(id);
    } else {
        oDD = YAHOO.util.DDM.getBestMatch(id);
    }

    //calculate and store relative coordinates
    this_el = this.getEl();
    oDD_el = oDD.getEl();
    this.saveCoords(oDD.id, this_el.offsetLeft - oDD_el.offsetLeft, this_el.offsetTop - oDD_el.offsetTop);

}

drag_label.prototype.onInvalidDrop = function (e,id) {
// animation from http://developer.yahoo.com/yui/examples/dragdrop/circle.html?mode=dist
     new YAHOO.util.Motion( 
          this.id, { 
                points: { 
                     to: this.startPos
                }
          }, 
          0.3, 
          YAHOO.util.Easing.easeOut 
     ).animate();

    this.input_el.setAttribute('value','');
}

drag_label.prototype.saveCoords = function (img_id, x, y) {
    this.input_el.setAttribute('value',img_id+'='+x+','+y);
    list = document.getElementsByTagName('form');

    //sloppy here to use 1st form...
    //switching to last form still sloppy but
    //1st form is now reserved and I'm too lazy / tired of fixing what I break
    //to do this properly
    if (list.length) {
        list[list.length - 1].appendChild(this.input_el);
    }
}

drag_label.prototype.onDragOver = function (e, id) {};
drag_label.prototype.onDrag = function (e, id) {};

