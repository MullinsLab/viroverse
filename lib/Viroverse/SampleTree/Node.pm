use strict;
use warnings;

package Viroverse::SampleTree::Node;

use Moose::Role;
use namespace::autoclean;

requires 'parent';
requires 'children';

1;
