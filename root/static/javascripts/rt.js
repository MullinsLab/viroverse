function addPrimer(button) 
{
    var parentDiv = document.getElementById('primers'); // this should be the primergroup div
    //var buttonSpan = button.parentNode.parentNode.removeChild(button.parentNode); //remove button span and hold onto reference


    var newPrimerDiv = document.createElement("div");
    //formSpan.setAttribute("class","formw");
    var input = document.createElement("input");
    input.setAttribute("type","text");
    //    parentDiv.getElementsByTagName("div")
    unique = "primer:" + (parentDiv.getElementsByTagName("div").length +1)
    input.setAttribute("name", unique);
    input.setAttribute("id",unique );
    input.setAttribute("size","40");
    input.setAttribute("class","auto");
    newPrimerDiv.appendChild(input);
    //aDiv.appendChild(buttonSpan);
    parentDiv.appendChild(newPrimerDiv);
    var resultDiv = document.createElement('div');
    resultDiv.className = 'primer_auto y_auto';
    resultDiv.id = unique + 'result'
    newPrimerDiv.appendChild(resultDiv);
    new YAHOO.widget.AutoComplete(input.id, resultDiv.id, viroverse.primerDataSource);
}

function removePrimer(button) {
    var primerDiv = document.getElementById('primers');
    primerDiv.removeChild(primerDiv.lastChild);
}
