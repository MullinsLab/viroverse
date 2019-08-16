-- Deploy pacbio_pools

BEGIN;

SET search_path TO viroserve;

CREATE OR REPLACE VIEW pacbio_pool AS (

SELECT sample.sample_id                   as sample_id,
       sample.name                        as sample_name,
       r2.pcr_product_id                  as pcr_product_id,
       r2.name                            as pcr_nickname,
       rt_primer.name                     as rt_primer,
       scientist.name                     as scientist,
       r2.date_completed                  as date_completed,
       array_agg(distinct r2_primer.name) as r2_pcr_primers

  FROM sample_first_pcr_template_path start_here
  JOIN sample USING (sample_id)
  JOIN rt_product USING (rt_product_id)
  JOIN rt_primer rt_primer_join USING (rt_product_id)
  JOIN primer rt_primer USING (primer_id)
  JOIN pcr_product r1 USING (pcr_template_id)
  JOIN pcr_pool_pcr_product pp
        ON (r1.pcr_product_id = pp.pcr_product_id)
  JOIN pcr_product pool_proxy
        ON (pp.pcr_pool_id = pool_proxy.pcr_pool_id)
  JOIN pcr_template r2t
        ON (r2t.pcr_product_id = pool_proxy.pcr_product_id)
  JOIN pcr_product r2
        ON (r2t.pcr_template_id = r2.pcr_template_id)
  JOIN pcr_product_primer r2_primer_join
        ON (r2.pcr_product_id = r2_primer_join.pcr_product_id)
  JOIN primer r2_primer
        ON (r2_primer_join.primer_id = r2_primer.primer_id)
  JOIN scientist
        ON (r2.scientist_id = scientist.scientist_id)

 GROUP BY 1, 2, 3, 4, 5, 6

);

GRANT SELECT ON pacbio_pool TO :ro_user;
GRANT SELECT ON pacbio_pool TO :rw_user;

COMMIT;
