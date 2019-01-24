function confirm_message (theText) {
    //'message' id div is in global header
    msg = document.getElementById('message');
    msg.style.display = 'block';
    msg.innerHTML = escapeHTML(theText);
    viroverse.messageAnimate.animate();
}
function clear_confirm () {
    document.getElementById('message').innerHTML = '';
}
function deleteThis(cull) {
    var match = document.getElementById( cull.id.substring(4) );
    if ( match && match.getAttribute('type') == 'checkbox' ) {
        match.checked= false
    }
    cull.parentNode.removeChild(cull);
}

function count_properties(object) {
    var count = 0; 
    for (var item in object) { 
        count +=1 ;
    }
    return count;
}

function removeChildNodes(parentNode) {
    var kids = parentNode.childNodes;    // Get the list of children
    var numkids = kids.length;  // Figure out how many children there are
    for(var i = numkids-1; i >= 0; i--) {  // Loop backward through the children
        var c = parentNode.removeChild(kids[i]);    // Remove a child
    }
}

function DOMswapParents (orig,dest) {
    //    document.getElementById('sidebar').appendChild(document.createTextNode(orig.id+"->"+dest.id+" "));
    var orig_parent = orig.parentNode;
    var dest_parent = dest.parentNode;
    var susp = dest_parent.replaceChild(orig,dest);
    orig_parent.appendChild(dest);
}

function setFormDisable(FormNode,bool) {
    for (var el_i = 0; el_i <  FormNode.elements.length; el_i++) {
        formElem = FormNode.elements.item(el_i);
        //alert(formElem);
        formElem.disabled = bool;
    }
}

function make_xmlhttp () {
   var http
    /*@cc_on @*/
    /*@if (@_jscript_version >= 5)
    try {
        http = new ActiveXObject("Msxml2.XMLHTTP")
    } catch (e) {
        try {
            http = new ActiveXObject("Microsoft.XMLHTTP")

        } catch (E) {
            http = false
        }
    }
    @else
    http = false
    @end @*/

    if (!http && document.createElement) {
        try {
            http = new XMLHttpRequest();
        } catch (e) {
            http = false
        }
    }

    if (http) {
        return http;
    } else {
        alert ("Unable to provide XMLHttp functionality");
    }
}

// modified from http://www.experts-exchange.com/Web/Web_Languages/JavaScript/Q_10095089.html
// changelog:
//   formatting
//   fixed v="on" to the .value of the element in the case of a checkbox
function form2url(f)
{
  var s = formfields2urlparams(f);
  var a = formaction2url(f)
  return a+'?'+s;
}

function formaction2url(f) {
    var loc=f.action+"";
    inx=loc.indexOf("?");
    if(inx!=-1) loc=loc.substring(0,inx);
    return loc;
}

function formfields2urlparams (f) {
  var s="";
  var i;
  for(i=0; i<f.length; i++)
  {
    var n=f.elements[i].name;
    var v=f.elements[i].value;
    var t=f.elements[i].type;

    if((t=="text") || (t=="hidden") || (t=="password") || (t=="textarea"))
    {
      v=f.elements[i].value;
      s+=encodeURIComponent(n)+"="+encodeURIComponent(v)+"&";
    }
    else if(t=="select-one" && f.elements[i].selectedIndex!=-1)
    {
      v=f.elements[i].options[f.elements[i].selectedIndex].value;
      s+=encodeURIComponent(n)+"="+encodeURIComponent(v)+"&";
    }
    else if(t=="checkbox")
    {
      if(f.elements[i].checked)
      {
        v = v || "on";
        s+=encodeURIComponent(n)+"="+encodeURIComponent(v)+"&";
      }
    }
    else if(t=="select-multiple")
    {
      if(f.elements[i].selectedIndex!=-1)
      {
        l=f.elements[i].options.length;
        //if(f.elements[i].selectedIndex>=0)
        //{
        //  s+=encodeURIComponent(n)+"=";
        //}
        vsel="";
        for(j=f.elements[i].selectedIndex;j<l;j++)
        {
          if(f.elements[i].options[j].selected)
          {
            v=f.elements[i].options[j].value;
            // escape , or not?
            vsel+="&"+encodeURIComponent(n)+'='+encodeURIComponent(v);
          }
          
        }
        if(f.elements[i].selectedIndex>=0)
        {
          // escape , or not?        
          vsel=vsel.substring(1);
          s+=vsel+"&"
        }
      }
    }

    else if(t=="radio")
    {
      if(f.elements[i].checked)
      {
         v=f.elements[i].value;
         s+=encodeURIComponent(n)+"="+encodeURIComponent(v)+"&";
      }
    }
  }
  s=s.substring(0,s.length-1);

  while((inx=s.indexOf("%20"))!=-1)
  {
    //check for %%20
    if(inx>0)
    {
      if(s.charAt(inx-1)=='%')
      { //do nothing
      }
      else
      {
        s=s.substring(0,inx)+"+"+s.substring(inx+3);
      }
    }
    else
    {
      s=s.substring(0,inx)+"+"+s.substring(inx+3);
    }
  }

    return s;
}

//makes all descdent spans into yahoo DD objects
// see http://developer.yahoo.com/yui/docs/YAHOO.util.DD.html

function make_draggable (div_id) {
    holder = document.getElementById(div_id) 
    //targets[div_id] = new YAHOO.util.DDTarget(div_id)

    list = holder.getElementsByTagName('span')
    for ( var i=0; i< list.length;i++) {
        var new_thing = new drag_label(list[i])
        in_drag[list[i].id] = new_thing
    }
}

function make_img_targets (div_id) {
    holder = document.getElementById(div_id) 
    list = holder.getElementsByTagName('img')
    for ( var i=0; i< list.length;i++) {
        //alert(i+" "+list[i].id);
        targets[list[i].id] = new YAHOO.util.DDTarget(list[i])
    }
}

function submit_form_ajax(source_form_id,to_do,error_div_id) {
    source = document.getElementById(source_form_id);
    var body = '';
    if (!source) {
        alert(source_form_id+" could not be found");
    }

    if (source.onsubmit) {
        source.onsubmit();
    }

    if (source.method.toUpperCase() == 'POST') {
        form_get = formaction2url(source)
        body = formfields2urlparams(source)
    } else {
        form_get = form2url(source);
    }

    load_url_ajax(form_get,to_do,error_div_id,source.id,source.method,body)
}

function div_load_ajax (url,target_div_id,error_div_id) {
    var to_do = function (resp) {
        var target = document.getElementById(target_div_id);
        target.innerHTML = resp;
        evalScripts(target);
    };
    load_url_ajax(url,to_do,error_div_id,target_div_id);

}

function load_url_ajax (url,to_do,error_div_id,to_gray_id,method,body) {
    if (!method) {
        method = 'GET'
    }
    var http = make_xmlhttp();
    var source = document.getElementById(to_gray_id);
    var overlay;
    if (source) {
        // grey out and tick over form div
        //setFormDisable(source,true)
        overlay = gray_overlay(source);
    }
    http.open(method,url,true);
    http.onreadystatechange = function() {
        if (source) {
            overlay.className='loading'+http.readyState;
        }
        if (http.readyState == 4) {
            if (source) {
                deleteThis(overlay);
            }
            if (error_div_id)  {
                if (http.responseText.substring(0,5) == 'Error' ) {
                    show_error(error_div_id,http.responseText);
                } else if (http.responseText.indexOf('Caught Exception') != '-1') {
                    alert(http.responseText.indexOf('Caught Exception'));
                    show_error(error_div_id,'Unknown Form Error: see administrator');
                } else {
                    document.getElementById(error_div_id).style.display = 'none';
                    to_do(http.responseText);
                }
                //setFormDisable(source,false)
            } else {
                to_do(http.responseText);
                //setFormDisable(source,false)
            } 
        }
    }
    if (method.toUpperCase() == 'POST' && body) {
        http.setRequestHeader('Content-type','application/x-www-form-urlencoded');
        http.send(body);
    } else {
        http.send(null);
    }
}

function gray_overlay (target_node) {
    overlay = document.createElement('div');
    overlay.id = 'overlay';
    overlay.className = 'loading1';
    overlay.style.left = target_node.offsetLeft+'px';
    overlay.style.top = target_node.offsetTop+'px';
    overlay.style.width = target_node.offsetWidth+'px';
    overlay.style.height = target_node.offsetHeight+'px';
    overlay.innerHTML = "<img src='"+viroverse.url_base+"static/images/spinner.gif' /> <span>transmitting<blink>...</blink></span>"

    target_node.parentNode.insertBefore(overlay,target_node)
    return overlay;
}

function show_error (error_div_id,error_html) {
    ediv = document.getElementById(error_div_id);
    ediv.style.display = 'block';
    ediv.innerHTML = error_html;
    viroverse.errorAnimate.animate();
}

// Array.unique(my_array), a la Object.keys(my_object)
Array.unique = function(a) {
    var seen = {};
    return a.filter(function(x){
        // seen[x]++ produces NaN when seen[x] is undef
        return seen[x] ? false : seen[x] = 1;
    });
};

function showLoadingBox(parentDiv, text, divWidth, divHeight){
    text = text || "Loading Results...";
    divWidth = divWidth || "500px";
    divHeight = divHeight || "150px";
    divPadding = (parseInt(divHeight.replace(/px/, "")) / 2) - 25
    var loadingDiv = document.createElement("div");
    loadingDiv.id = "loadDiv";
    var header = document.createElement("h2");
    header.innerHTML = text;
    header.style.paddingTop = divPadding + "px";
    var loadGif = document.createElement('img');
    loadGif.src = viroverse.url_base + "/static/images/spinner2.gif";
    with (loadGif.style){
        width = "25px",
        height = "25px"
    }

    loadingDiv.appendChild(header);
    loadingDiv.appendChild(loadGif);
    with (loadingDiv.style){
        width = divWidth,
        height = divHeight,
        textAlign = 'center',
        backgroundColor = "#EEEEEE"

    }
    parentDiv.appendChild(loadingDiv);
}


//stolen from post in thread at http://bytes.com/topic/javascript/answers/635488-prevent-text-selection-after-double-click
function clearSelection() {
    var sel ;
    if(document.selection && document.selection.empty){
        document.selection.empty() ;
    } else if(window.getSelection) {
        sel=window.getSelection();
    if(sel && sel.removeAllRanges)
        sel.removeAllRanges() ;
    }
}


//returns the datastructure inside of Viroverse::View::JSON2's Response object.
function evalJSON(http){
       if(http.status == 500){
             writeError("Server Error");
             return -1;
       }
        return evalJSON_response(http.responseText);
}

function evalJSON_response (json) {
    if(json == ""){return ""};//not much you can do with that
    try{
        var ret = eval ( "("  + json + ")" );
        if(ret.error){
            handleAjaxError(json)
        }
    }catch(e){
        writeError("Error:  " + e);
    }
    return ret.Response?ret.Response:ret;

}

//Takes JSON string form Viroverse::Controller::ajax_error evals it to an object and handles it
// currently this just contains a msg string but that may change;
function handleAjaxError(responseText) {
    if(responseText == ""){return};//not much you can do with that
    try{
        var response = eval( "(" + responseText + ")");
        if(response.error){
            writeError(response.error.msg);
        }
    }catch(e){
        writeError("Unknown Error " + e + "<br/>From:  " + responseText);
    }
}

//looks for div with id=error creates it if not found
//and writes error message e to it
function writeError(e){
    var errorDiv = document.getElementById("error");
    if(!errorDiv){
        errorDiv = document.createElement("div");
        errorDiv.id = "error";
        errorDiv.className = "error";
        var formBody = document.getElementsByClassName("formBody");
        formBody.item(0).insertBefore(errorDiv, formBody.item(0).firstChild);
    }
    errorDiv.innerHTML = e;
    errorDiv.style.display = "block";
}

function clearError(){
    var errorDiv = document.getElementById("error");
    if(errorDiv){
        errorDiv.innerHTML = "";
        errorDiv.style.display = "none";
    }
}

function mark_all (root,val) {
    var r = document.getElementById(root);
    var is = r.getElementsByTagName('input');
    for (var i=0;i<is.length;i++) {
        if (is[i].type=='radio' && is[i].value == val && !is[i].checked) {
            is[i].checked = true;
            if(is[i].onchange){
                is[i].onchange();
            }
        } 
    }

    return false;
}

function clearAll(ctr, name){ //will deselect all radio/checkboxes in the provided container with the provided name
    var inputs = ctr.getElementsByTagName('input');
    for (var i =0 ; i < inputs.length ; i++){
        if(inputs.item(i).name == name && inputs.item(i).checked){
            inputs.item(i).checked = false;
            if(inputs.item(i).onchange){
                inputs.item(i).onchange();
            }
        }
    }
}

function checkAll(ctr){//will select all checkboxes in the provided container
       var inputs = ctr.getElementsByTagName('input');
       for (var i =0 ; i < inputs.length ; i++){
             if(inputs.item(i).type == 'checkbox'){
                    var isChecked = inputs.item(i).checked;
                    inputs.item(i).checked = 'checked';
                    if(!isChecked && inputs.item(i).onchange){
                          inputs.item(i).onchange();
                    }
             }
       }       
}

function selectedOptions (selectObj) {
    var selOpts = new Array();
    for (var i=0;i < selectObj.options.length ; i++) {
        if (selectObj.options[i].selected) {
            selOpts.push(selectObj.options[i]);
        }
    }

    return selOpts;
}

function disenable_children (parentNode,disenable_b) {
    var count = 0
    var inputs = parentNode.getElementsByTagName('input');
    for (var i=0; i< inputs.length; i++) {
        inputs.item(i).disabled = disenable_b;
    }
    inputs = parentNode.getElementsByTagName('select');
    for (var i=0; i< inputs.length; i++) {
        inputs.item(i).disabled = disenable_b;
    }

}

// from http://my.opera.com/GreyWyvern/blog/show.dml/1671288
function alphanumsort(a,b) {
    function chunkify(t) {
        var tz = [], x = 0, y = -1, n = 0, i, j;
        while (i = (j = t.charAt(x++)).charCodeAt(0)) {
            var m = (i == 46 || (i >=48 && i <= 57));
            if (m !== n) {
                tz[++y] = "";
                n = m;
            }
            tz[y] += j;
        }
        return tz;
    }

    a = a.replace(/(^\s+|\s+$)/g, '').toLowerCase();
    b = b.replace(/(^\s+|\s+$)/g, '').toLowerCase();

    var aa = chunkify(a);
    var bb = chunkify(b);

    for (x = 0; aa[x] && bb[x]; x++) {
        if (aa[x] !== bb[x]) {
            var c = Number(aa[x]), d = Number(bb[x]);
            if (c == aa[x] && d == bb[x]) {
                return c - d;
            } else return (aa[x] > bb[x]) ? 1 : -1;
        }
    }
    return aa.length - bb.length;
}

// YAHOO.util.escapeHTML() doesn't exist until 2.9.x. :(
// -trs, 25 Oct 2013
function escapeHTML(text) {
    return ("" + text).replace(/[<>'"&]/g, function(c){
        return "&#x" + c.charCodeAt(0).toString(16) + ";"
    });
}

function generateRandomId() {
    var d = new Date();
    return d.getTime() + Math.floor(Math.random() * 1000).toString();
}

function generateUniqueId(prefix, tries) {
    if (prefix == null) prefix = ""
    if (!tries)         tries  = 3

    for (var i = 1; i <= tries; i++) {
        var id = prefix + generateRandomId();
        if (!document.getElementById(id))
            return id;
    }
    return null;
}

// Eventually this function should vanish as we move more and more client-side
// code to Angular or other frameworks.  Its existence is solely to support
// co-operation during the (long) transitional period between the homegrown
// mess of vanilla JS + YUI and things more structured and modern (like Angular
// or Elm).
//   -trs, 6 December 2016
function evalScripts(root) {
    // Evaluate any <script>s in global context; useful when root is a node
    // which had <script>s inserted via innerHTML.
    var scripts = Array.apply(null, root.getElementsByTagName("script"));
    scripts.forEach(function(s){
        var script = document.createElement("script");
        script.type = s.type;
        if (s.src)         script.src         = s.src;
        if (s.textContent) script.textContent = s.textContent;
        s.parentNode.replaceChild(script, s);
    });

    // Compile and link any Angular directives in the returned snippet.  This
    // is a terrible thing needed as long as we're doing both vanilla JS DOM
    // manip and Angular in the same components.
    var ngApp = document.querySelector("[ng-app]");
    if (ngApp && window.angular) {
        angular.element(root).injector().invoke(function($compile) {
            // Use of .scope() requires that $compileProvider.debugInfoEnabled
            // isn't set to false.
            var scope = angular.element(ngApp).scope();
            $compile(root)(scope);
            scope.$apply();
        });
    }
}
