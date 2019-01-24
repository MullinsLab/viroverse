window.UploadList = (function(){
  'use strict';

  // Implement the EventListener interface so we can register class instances
  // with the right methods as event handlers.
  //
  class EventListener {
    handleEvent(e) {
      return this[e.type](e);
    }
  }


  // A standard, basic drag-and-drop handler pattern for extending
  //
  class Droppable extends EventListener {
    constructor(container) {
      super();

      this.container = container;
      this.container.addEventListener("dragover",  this, false);
      this.container.addEventListener("dragenter", this, false);
      this.container.addEventListener("dragleave", this, false);
      this.container.addEventListener("drop",      this, false);
    }

    // Prevent default to allow drag
    //
    dragover(ev) {
      ev.preventDefault();
    }

    // Highlight the dropzone
    //
    dragenter(ev) {
      this.container.classList.add("active-dropzone");
    }

    // Remove dropzone highlight
    //
    dragleave(ev) {
      if (ev.target === this.container)
        this.container.classList.remove("active-dropzone");
    }

    // Prevent default to allow custom drop handling
    //
    drop(ev) {
      ev.preventDefault();
      this.container.classList.remove("active-dropzone");
    }
  }


  /* An Upload List (`.upload-list`) is a small widget containing an `<input
   * type="file">` element and an empty `<ul>` with a `data-for` attribute set to
   * the _name_ of the `<input>`.  The container (the `.upload-list` element)
   * becomes a dropzone for dragged files.  The `<ul>` will list the file names of
   * the local files currently selected by the input (either from drag and drop or
   * browsing using the file chooser).  The intent is a loosely coupled widget
   * providing nicer behaviour on top of standard form elements and form submission
   * behaviour.
   */
  class UploadList extends Droppable {
    constructor(container) {
      super(container);

      this.container.classList.add("upload-list");

      if (!this.inputs[0])
        throw 'UploadList ' + this.container + ' is missing an <input type="file">';

      // Our list of file names
      this.list = this.container.querySelector("ul[data-for=" + this.inputs[0].name + "]");

      // Watch the input for changes in case people use the file chooser
      // instead of drag-and-drop
      this.inputs[0].addEventListener("change", this, false);

      // Watch for a form reset so we can clear all files
      if (this.inputs[0].form)
        this.inputs[0].form.addEventListener("reset", this, false);

      // Register a handler for any (optional) add files buttons
      this.container.querySelectorAll(".upload-list-add").forEach(button => {
        button.addEventListener("click", ev => { this.openChooser(ev) }, false);
      });

      // Register a handler for any (optional) clear buttons
      this.container.querySelectorAll(".upload-list-clear").forEach(button => {
        button.addEventListener("click", ev => { this.clear(ev) }, false);
      });

      // Update on page shows (possibly back button nav) so our state is synced
      window.addEventListener("pageshow", this, false);
    }

    get inputs() {
      return Array.from( this.container.querySelectorAll("input[type=file]") );
    }

    get currentInput() {
      return this.inputs.slice(-1)[0];
    }

    // Keep the display of file names up-to-date.
    //
    update() {
      let files =
        this.inputs
          .map(input => Array.from(input.files))
          .reduce((a,b) => a.concat(b), []);

      this.container.classList.toggle("has-files", files.length > 0);

      // If there's no <ul> for filenames, we're done.
      if (!this.list)
        return;

      // Clear existing file list and regenerate items.  We could do this in a
      // template instead, but that would make for an HTML interface further
      // removed from the standard <input type="file"> elements.  We'd have to
      // support the various attributes that control the file selector, custom
      // labels, different list classes, etc.  This is a more loosely coupled
      // approach that's not hard to do with vanilla JS.
      //
      this.list.innerHTML = '';

      for (var file of files) {
        let li = document.createElement('li');
        li.textContent = file.name;
        this.list.appendChild(li);
      }
    }

    // Add dropped files to an <input type="file"> element
    //
    drop(ev) {
      super.drop(ev);

      let files = ev.dataTransfer.files;

      // Dropped text rather than files
      if (files.length === 0)
        return;

      this.createNewInputIfNecessary();
      this.currentInput.files = files;
      this.update();
    }

    // When an input changes, update ourselves, possibly removing the input
    // itself if it's now empty and it's not the only input we have.
    //
    change(ev) {
      let hasSiblingInputs = this.inputs.length > 1;

      if (ev.target.files.length === 0 && hasSiblingInputs)
        ev.target.remove();

      this.update();
    }

    // Clear this upload list of files.
    //
    clear(ev) {
      ev.preventDefault();
      this.inputs.slice(1).forEach(input => { input.remove() });
      this.inputs[0].value = null;
      this.update();
    }

    // On form reset, update ourselves on the "next tick", which ensures that
    // the input.files properties are actually cleared by the time our runs.
    //
    reset(ev) {
      setTimeout(() => { this.update() }, 1);
    }

    // Update ourselves on page shows so we stay in sync when, for example,
    // navigating back to cached pages.
    //
    pageshow(ev) {
      this.update();
    }

    // Open a file chooser on a new (or empty) input
    //
    openChooser(ev) {
      ev.preventDefault();
      this.createNewInputIfNecessary();
      this.currentInput.click();
    }

    // If the current input is empty, do nothing.  Otherwise, clone the element
    // and add it to the DOM.  It'll now be the new current input.
    //
    createNewInputIfNecessary() {
      let currentInput = this.currentInput;

      if (currentInput.files.length > 0) {
        let newInput = currentInput.cloneNode();
        newInput.removeAttribute("id");
        newInput.addEventListener("change", this, false);

        // Add the new input _after_ the last input, making it the new current input.
        currentInput.parentNode.insertBefore(newInput, currentInput.nextSibling);
      }
    }
  }

  return UploadList;

})();
// vim: set ts=2 sw=2 :
