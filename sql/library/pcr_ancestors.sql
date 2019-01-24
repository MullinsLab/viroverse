WITH RECURSIVE pcr_product_parents (
    pcr_product_id,
    start_pcr,
<% IF gel_lanes %>
    gel_lane_id,
    pos_pcr,
<% END %>
    round,
    loop_calc,
    enzyme_id,
    pcr_template_id,
    volume,
    template_pcr_product_id,
    rt_product_id,
    extraction_id,
    bisulfite_converted_dna_id,
    sample_id
) AS (
    SELECT pcr_product.pcr_product_id,
           pcr_product.pcr_product_id as start_pcr,
<% IF gel_lanes %>
           gel_lane_id,
           NULLIF(pos_result, false) AS pos_pcr,
<% END %>
           pcr_product.round,
           1,
           enzyme_id,
           pcr_product.pcr_template_id,
           pcr_template.volume,
           pcr_template.pcr_product_id,
           pcr_template.rt_product_id,
           pcr_template.extraction_id,
           pcr_template.bisulfite_converted_dna_id,
           pcr_template.sample_id
      FROM viroserve.pcr_product
      JOIN viroserve.pcr_template USING (pcr_template_id)
<% IF pcrs %>
     WHERE pcr_product.pcr_product_id IN (<% pcrs.map(->{ "?" }).join(", ") %>)
<% ELSIF gel_lanes %>
      JOIN viroserve.gel_lane        ON (gel_lane.pcr_product_id = pcr_product.pcr_product_id)
     WHERE gel_lane_id IN (<% gel_lanes.map(->{ "?" }).join(", ") %>)
       AND gel_lane.pos_result IS NOT NULL
<% END %>
UNION
    SELECT parent.pcr_product_id,
           start_pcr,
<% IF gel_lanes %>
           gel_lane_id,
           pos_pcr,
<% END %>
           parent.round,
           loop_calc + 1,
           parent.enzyme_id,
           parent.pcr_template_id,
           parent_template.volume,
           parent_template.pcr_product_id,
           parent_template.rt_product_id,
           parent_template.extraction_id,
           parent_template.bisulfite_converted_dna_id,
           parent_template.sample_id
      FROM pcr_product_parents
      JOIN (     viroserve.pcr_template
            JOIN viroserve.pcr_product  AS parent USING (pcr_product_id)
            JOIN viroserve.pcr_template AS parent_template ON (parent.pcr_template_id = parent_template.pcr_template_id))
        ON (pcr_product_parents.pcr_template_id = pcr_template.pcr_template_id)
)
SELECT pcr_product_parents.*, primers
  FROM pcr_product_parents
  JOIN (SELECT string_agg(primer_id::text, '_') AS primers, pcr_product_id
          FROM (SELECT * FROM viroserve.pcr_product_primer ORDER BY pcr_product_id, primer_id) AS primer_sort
         GROUP BY pcr_product_id)
    AS primer_agg
    ON (pcr_product_parents.pcr_product_id = primer_agg.pcr_product_id)
 ORDER BY start_pcr, loop_calc

