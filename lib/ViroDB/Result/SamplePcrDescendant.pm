use strict;
use warnings;
use utf8;
use 5.018;

package ViroDB::Result::SamplePcrDescendant;

use base 'ViroDB::Result';

__PACKAGE__->table_class("DBIx::Class::ResultSource::View");
__PACKAGE__->table("sample_pcr_descendants");
__PACKAGE__->result_source_instance->is_virtual(1);
__PACKAGE__->result_source_instance->view_definition(
    "SELECT sample_id, pcr_product_id FROM viroserve.pcr_descendants_for_sample(?)"
);

__PACKAGE__->add_columns(
    'sample_id'      => { data_type => 'integer', is_foreign_key => 1, is_nullable => 0 },
    'pcr_product_id' => { data_type => 'integer', is_foreign_key => 1, is_nullable => 0 },
);

__PACKAGE__->belongs_to(
    "pcr_product",
    "ViroDB::Result::PolymeraseChainReactionProduct",
    { pcr_product_id => "pcr_product_id" },
    { is_deferrable => 0, },
);


1;
