(function(){
  'use strict';

  let module = angular.module('vv.ui');

  // A controller handling the parsing of provided FASTA file for the sequence
  // revision interface.
  //
  class ReviseSequence {
    get name() {
      let sequence = this.fasta[0];
      return sequence ? sequence.id : null;
    }

    get sequence() {
      let sequence = this.fasta[0];
      return sequence ? sequence.seq : null;
    }

    // The .fasta property returns an array of sequence objects after being set
    // to a string representing a FASTA file.
    //
    get fasta()     { return this._fasta || [] }
    set fasta(text) {
      this._fasta = this.parseFasta(text);
    }

    // Parse a FASTA file.
    //
    // This is copied, with some trimming, from Methylation Station (which does
    // some additional description line parsing that we don't need here).¹  It
    // didn't seem worth packaging this up and contributing to the plethora of
    // JS FASTA parsers out there, nor did it seem useful to import one of said
    // plethora as they often bring much more baggage than we need.
    //
    // ¹ https://github.com/MullinsLab/Methylation-Station/blob/master/js/alignment.js#L40-L98
    //
    parseFasta(text) {
      var fasta = [],
          index = 0,
          sequence;

      text.split(/\r\n|\r|\n/).forEach(line => {
        if (line.match(/^>/)) {
          if (sequence)
            fasta.push(sequence);

          var name = line
            .replace(/^>/, '')
            .split(/\s+/);

          var id          = name[0];
          var description = name.slice(1).join(" ");

          sequence = {
            id:          id,
            description: description,
            index:       index++,
            seq:         ""
          };
        }
        else if (sequence) {
          if (line.match(/\S/))
            sequence.seq += line.replace(/\s+/, '', 'g');
        }
        else {
          throw "No sequence name found";
        }
      });

      if (sequence)
        fasta.push(sequence);

      return fasta;
    }
  }

  module.controller('ReviseSequence', [ReviseSequence]);

})();
// vim: set ts=2 sw=2 :
