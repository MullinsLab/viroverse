-- We can't use our refresh_*() functions because they use CONCURRENTLY, which
-- isn't valid for the initial view population.

REFRESH MATERIALIZED VIEW viroserve.sequence_search;
REFRESH MATERIALIZED VIEW viroserve.distinct_sample_search;
REFRESH MATERIALIZED VIEW viroserve.project_material_scientist_progress;
