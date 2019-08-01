--
-- PostgreSQL database dump
--

-- Dumped from database version 9.4.11
-- Dumped by pg_dump version 10.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: delta; Type: SCHEMA; Schema: -; Owner: :owner
--

CREATE SCHEMA delta;


ALTER SCHEMA delta OWNER TO :owner;

--
-- Name: epitope; Type: SCHEMA; Schema: -; Owner: :owner
--

CREATE SCHEMA epitope;


ALTER SCHEMA epitope OWNER TO :owner;

--
-- Name: freezer; Type: SCHEMA; Schema: -; Owner: :owner
--

CREATE SCHEMA freezer;


ALTER SCHEMA freezer OWNER TO :owner;

--
-- Name: sqitch; Type: SCHEMA; Schema: -; Owner: :owner
--

CREATE SCHEMA sqitch;


ALTER SCHEMA sqitch OWNER TO :owner;

--
-- Name: SCHEMA sqitch; Type: COMMENT; Schema: -; Owner: :owner
--

COMMENT ON SCHEMA sqitch IS 'Sqitch database deployment metadata v1.0.';


--
-- Name: viroserve; Type: SCHEMA; Schema: -; Owner: :owner
--

CREATE SCHEMA viroserve;


ALTER SCHEMA viroserve OWNER TO :owner;


--
-- Name: enzyme_type; Type: DOMAIN; Schema: viroserve; Owner: :owner
--

CREATE DOMAIN viroserve.enzyme_type AS text NOT NULL
	CONSTRAINT valid_enzyme_type CHECK ((VALUE = ANY (ARRAY['reverse transcriptase'::text, 'polymerase'::text])));


ALTER DOMAIN viroserve.enzyme_type OWNER TO :owner;

--
-- Name: gender_code; Type: DOMAIN; Schema: viroserve; Owner: :owner
--

CREATE DOMAIN viroserve.gender_code AS character(1)
	CONSTRAINT gender_code CHECK ((VALUE = ANY (ARRAY['M'::bpchar, 'F'::bpchar])));


ALTER DOMAIN viroserve.gender_code OWNER TO :owner;

--
-- Name: hla_genotype_ambiguity_code; Type: DOMAIN; Schema: viroserve; Owner: :owner
--

CREATE DOMAIN viroserve.hla_genotype_ambiguity_code AS character(1)
	CONSTRAINT valid_hla_genotype_ambiguity_code CHECK ((VALUE = ANY (ARRAY['P'::bpchar, 'G'::bpchar])));


ALTER DOMAIN viroserve.hla_genotype_ambiguity_code OWNER TO :owner;

--
-- Name: na_type; Type: DOMAIN; Schema: viroserve; Owner: :owner
--

CREATE DOMAIN viroserve.na_type AS character varying(10)
	CONSTRAINT valid_na_type CHECK (((VALUE)::text = ANY (ARRAY[('DNA'::character varying)::text, ('RNA'::character varying)::text])));


ALTER DOMAIN viroserve.na_type OWNER TO :owner;

--
-- Name: patient_alias_type; Type: DOMAIN; Schema: viroserve; Owner: :owner
--

CREATE DOMAIN viroserve.patient_alias_type AS text
	CONSTRAINT patient_alias_type_check CHECK ((VALUE = ANY (ARRAY['primary'::text, 'alias'::text, 'publication'::text])));


ALTER DOMAIN viroserve.patient_alias_type OWNER TO :owner;

--
-- Name: scientist_role; Type: DOMAIN; Schema: viroserve; Owner: :owner
--

CREATE DOMAIN viroserve.scientist_role AS text NOT NULL DEFAULT 'scientist'::text
	CONSTRAINT valid_role_name CHECK ((VALUE = ANY (ARRAY['scientist'::text, 'supervisor'::text, 'admin'::text, 'retired'::text])));


ALTER DOMAIN viroserve.scientist_role OWNER TO :owner;

--
-- Name: pool_response_result(integer, integer); Type: FUNCTION; Schema: epitope; Owner: :owner
--

CREATE FUNCTION epitope.pool_response_result(id integer, bg_id integer) RETURNS character
    LANGUAGE plpgsql
    AS $$
DECLARE
pool_avg numeric;
cells integer;
bg_avg numeric;
sfc numeric;
BEGIN
SELECT avg, cell_num INTO pool_avg, cells
FROM epitope.pool_response_avg
JOIN epitope.pool_response USING (measure_id)
WHERE measure_id=id;

SELECT avg INTO bg_avg
FROM epitope.pept_response_avg
WHERE measure_id = bg_id;

sfc := (pool_avg - bg_avg) * 1000000 / cells;

IF sfc >= 50 AND pool_avg >= bg_avg * 2
THEN
RETURN 'P';
ELSE
RETURN 'N';
END IF;
END
$$;


ALTER FUNCTION epitope.pool_response_result(id integer, bg_id integer) OWNER TO :owner;

--
-- Name: hla_designation(); Type: FUNCTION; Schema: viroserve; Owner: :owner
--

CREATE FUNCTION viroserve.hla_designation() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
	designation varchar;
BEGIN
	SELECT INTO designation
		replace(locus||  
        workshop||  
        '*'||  
        to_char(type,'09')||  
        to_char(subtype,'09')||  
        to_char(synonymous_polymorphism,'09')||  
        to_char(utr_polymorphism,'09')||  
        to_char(expression_level,'09')  
        , ' ')  
		 FROM viroserve.hla_genotype 
		WHERE hla_genotype_id = p_gt_id;

RETURN designation;
END;
$$;


ALTER FUNCTION viroserve.hla_designation() OWNER TO :owner;

--
-- Name: hla_designation(integer); Type: FUNCTION; Schema: viroserve; Owner: :owner
--

CREATE FUNCTION viroserve.hla_designation(patient_hla_genotype_id integer) RETURNS text
    LANGUAGE plpgsql STABLE STRICT
    AS $$
DECLARE
	designation varchar;
BEGIN
	SELECT INTO designation
               COALESCE(locus, '')
            || COALESCE(workshop, '')
            || COALESCE('*' || CASE WHEN type    BETWEEN 1 AND 9 THEN '0' || type    ELSE type::text    END, '')
            || COALESCE(':' || CASE WHEN subtype BETWEEN 1 AND 9 THEN '0' || subtype ELSE subtype::text END, '')
            || COALESCE(':' || CASE WHEN synonymous_polymorphism BETWEEN 1 AND 9 THEN '0' || synonymous_polymorphism ELSE synonymous_polymorphism::text END, '')
            || COALESCE(':' || CASE WHEN utr_polymorphism        BETWEEN 1 AND 9 THEN '0' || utr_polymorphism        ELSE utr_polymorphism::text        END, '')
            || COALESCE(expression_level, '')
            || COALESCE(ambiguity_group, '')
      FROM viroserve.hla_genotype
     WHERE hla_genotype_id = patient_hla_genotype_id;

RETURN designation;
END;
$$;


ALTER FUNCTION viroserve.hla_designation(patient_hla_genotype_id integer) OWNER TO :owner;

--
-- Name: patient_name(integer); Type: FUNCTION; Schema: viroserve; Owner: :owner
--

CREATE FUNCTION viroserve.patient_name(p_patient_id integer) RETURNS text
    LANGUAGE sql STABLE
    AS $$
    SELECT viroserve.patient_name_by_cohort(p_patient_id, c.cohort_id)
      FROM (
        SELECT min(cohort_id) AS cohort_id
          FROM viroserve.patient_cohort
         WHERE patient_id = p_patient_id
      ) c;
$$;


ALTER FUNCTION viroserve.patient_name(p_patient_id integer) OWNER TO :owner;

--
-- Name: patient_name_by_cohort(integer, smallint); Type: FUNCTION; Schema: viroserve; Owner: :owner
--

CREATE FUNCTION viroserve.patient_name_by_cohort(p_patient_id integer, c_cohort_id smallint) RETURNS text
    LANGUAGE sql STABLE
    AS $$
   SELECT cohort.name || ' ' || external_patient_id
     FROM viroserve.patient_alias
     JOIN viroserve.cohort USING (cohort_id)
    WHERE patient_alias.type = 'primary'
      AND patient_id = p_patient_id
      AND cohort_id = c_cohort_id
 ORDER BY external_patient_id;
$$;


ALTER FUNCTION viroserve.patient_name_by_cohort(p_patient_id integer, c_cohort_id smallint) OWNER TO :owner;

--
-- Name: pcr_descendants_for_sample(numeric); Type: FUNCTION; Schema: viroserve; Owner: :owner
--

CREATE FUNCTION viroserve.pcr_descendants_for_sample(sample numeric) RETURNS TABLE(sample_id integer, extraction_id integer, rt_product_id integer, bisulfite_converted_dna_id integer, primogenitor_pcr_template_id integer, primogenitor_pcr_product_id integer, pcr_template_id integer, pcr_product_id integer, round integer)
    LANGUAGE sql STABLE STRICT
    AS $_$
    WITH RECURSIVE sample_to_pcr( -- {{{2
        sample_id,
        extraction_id,
        rt_product_id,
        bisulfite_converted_dna_id,
        primogenitor_pcr_template_id,
        primogenitor_pcr_product_id,
        pcr_template_id,
        pcr_product_id,
        round
    ) AS (
        SELECT sample_id,
               extraction_id,
               rt_product_id,
               bisulfite_converted_dna_id,
               pcr_product.pcr_template_id AS primogenitor_pcr_template_id,
               pcr_product.pcr_product_id  AS primogenitor_pcr_product_id,
               pcr_product.pcr_template_id,
               pcr_product.pcr_product_id,
               pcr_product.round
          FROM viroserve.sample_first_pcr_template_path
          JOIN viroserve.pcr_product USING (pcr_template_id)
         WHERE sample_id = $1
        UNION
        /* The recursive case is easy! PCR templates from round > 1 just have PCR
         * products as their input.
         */
        SELECT sample_to_pcr.sample_id,
               sample_to_pcr.extraction_id,
               sample_to_pcr.rt_product_id,
               sample_to_pcr.bisulfite_converted_dna_id,
               sample_to_pcr.primogenitor_pcr_template_id,
               sample_to_pcr.primogenitor_pcr_product_id,
               pcr_template.pcr_template_id,
               pcr_product.pcr_product_id,
               pcr_product.round
          FROM sample_to_pcr
          JOIN viroserve.pcr_template USING (pcr_product_id)
          JOIN viroserve.pcr_product     ON (pcr_product.pcr_template_id = pcr_template.pcr_template_id)
    ) -- }}}2
    SELECT * FROM sample_to_pcr
;
$_$;


ALTER FUNCTION viroserve.pcr_descendants_for_sample(sample numeric) OWNER TO :owner;

--
-- Name: refresh_distinct_sample_search(); Type: FUNCTION; Schema: viroserve; Owner: :owner
--

CREATE FUNCTION viroserve.refresh_distinct_sample_search() RETURNS void
    LANGUAGE sql SECURITY DEFINER
    AS $$
        REFRESH MATERIALIZED VIEW CONCURRENTLY viroserve.distinct_sample_search;
    $$;


ALTER FUNCTION viroserve.refresh_distinct_sample_search() OWNER TO :owner;

--
-- Name: refresh_project_material_scientist_progress(); Type: FUNCTION; Schema: viroserve; Owner: :owner
--

CREATE FUNCTION viroserve.refresh_project_material_scientist_progress() RETURNS void
    LANGUAGE sql SECURITY DEFINER
    AS $$
        REFRESH MATERIALIZED VIEW CONCURRENTLY viroserve.project_material_scientist_progress;
    $$;


ALTER FUNCTION viroserve.refresh_project_material_scientist_progress() OWNER TO :owner;

--
-- Name: refresh_sequence_search(); Type: FUNCTION; Schema: viroserve; Owner: :owner
--

CREATE FUNCTION viroserve.refresh_sequence_search() RETURNS void
    LANGUAGE sql SECURITY DEFINER
    AS $$
        REFRESH MATERIALIZED VIEW CONCURRENTLY viroserve.sequence_search;
    $$;


ALTER FUNCTION viroserve.refresh_sequence_search() OWNER TO :owner;

--
-- Name: array_accum(anyelement); Type: AGGREGATE; Schema: public; Owner: :owner
--

CREATE AGGREGATE public.array_accum(anyelement) (
    SFUNC = array_append,
    STYPE = anyarray,
    INITCOND = '{}'
);


ALTER AGGREGATE public.array_accum(anyelement) OWNER TO :owner;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: derivation; Type: TABLE; Schema: delta; Owner: :owner
--

CREATE TABLE delta.derivation (
    derivation_id integer NOT NULL,
    protocol_id integer,
    input_sample_id integer,
    uri text,
    date_completed date NOT NULL,
    scientist_id integer NOT NULL
);


ALTER TABLE delta.derivation OWNER TO :owner;

--
-- Name: derivation_derivation_id_seq; Type: SEQUENCE; Schema: delta; Owner: :owner
--

CREATE SEQUENCE delta.derivation_derivation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE delta.derivation_derivation_id_seq OWNER TO :owner;

--
-- Name: derivation_derivation_id_seq; Type: SEQUENCE OWNED BY; Schema: delta; Owner: :owner
--

ALTER SEQUENCE delta.derivation_derivation_id_seq OWNED BY delta.derivation.derivation_id;


--
-- Name: protocol; Type: TABLE; Schema: delta; Owner: :owner
--

CREATE TABLE delta.protocol (
    protocol_id integer NOT NULL,
    name text NOT NULL
);


ALTER TABLE delta.protocol OWNER TO :owner;

--
-- Name: protocol_output; Type: TABLE; Schema: delta; Owner: :owner
--

CREATE TABLE delta.protocol_output (
    protocol_id integer,
    tissue_type_id integer
);


ALTER TABLE delta.protocol_output OWNER TO :owner;

--
-- Name: protocol_protocol_id_seq; Type: SEQUENCE; Schema: delta; Owner: :owner
--

CREATE SEQUENCE delta.protocol_protocol_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE delta.protocol_protocol_id_seq OWNER TO :owner;

--
-- Name: protocol_protocol_id_seq; Type: SEQUENCE OWNED BY; Schema: delta; Owner: :owner
--

ALTER SEQUENCE delta.protocol_protocol_id_seq OWNED BY delta.protocol.protocol_id;


--
-- Name: blcl_blcl_id_seq; Type: SEQUENCE; Schema: epitope; Owner: :owner
--

CREATE SEQUENCE epitope.blcl_blcl_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE epitope.blcl_blcl_id_seq OWNER TO :owner;

--
-- Name: blcl; Type: TABLE; Schema: epitope; Owner: :owner
--

CREATE TABLE epitope.blcl (
    blcl_id integer DEFAULT nextval('epitope.blcl_blcl_id_seq'::regclass) NOT NULL,
    name character varying(50)
);


ALTER TABLE epitope.blcl OWNER TO :owner;

--
-- Name: epitope_epit_id_seq; Type: SEQUENCE; Schema: epitope; Owner: :owner
--

CREATE SEQUENCE epitope.epitope_epit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE epitope.epitope_epit_id_seq OWNER TO :owner;

--
-- Name: epitope; Type: TABLE; Schema: epitope; Owner: :owner
--

CREATE TABLE epitope.epitope (
    epit_id integer DEFAULT nextval('epitope.epitope_epit_id_seq'::regclass) NOT NULL,
    pept_id integer NOT NULL,
    source_id integer
);


ALTER TABLE epitope.epitope OWNER TO :owner;

--
-- Name: epitope_mutant; Type: TABLE; Schema: epitope; Owner: :owner
--

CREATE TABLE epitope.epitope_mutant (
    epit_id integer NOT NULL,
    mutant_id integer NOT NULL,
    patient_id integer NOT NULL,
    note character varying(20) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE epitope.epitope_mutant OWNER TO :owner;

--
-- Name: epitope_sequence; Type: TABLE; Schema: epitope; Owner: :owner
--

CREATE TABLE epitope.epitope_sequence (
    pept_id integer NOT NULL,
    na_sequence_id integer NOT NULL,
    na_sequence_revision integer NOT NULL
);


ALTER TABLE epitope.epitope_sequence OWNER TO :owner;

--
-- Name: epitope_source_source_id_seq; Type: SEQUENCE; Schema: epitope; Owner: :owner
--

CREATE SEQUENCE epitope.epitope_source_source_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE epitope.epitope_source_source_id_seq OWNER TO :owner;

--
-- Name: epitope_source; Type: TABLE; Schema: epitope; Owner: :owner
--

CREATE TABLE epitope.epitope_source (
    source_id integer DEFAULT nextval('epitope.epitope_source_source_id_seq'::regclass) NOT NULL,
    source character varying(20)
);


ALTER TABLE epitope.epitope_source OWNER TO :owner;

--
-- Name: experiment_exp_id_seq; Type: SEQUENCE; Schema: epitope; Owner: :owner
--

CREATE SEQUENCE epitope.experiment_exp_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE epitope.experiment_exp_id_seq OWNER TO :owner;

--
-- Name: experiment; Type: TABLE; Schema: epitope; Owner: :owner
--

CREATE TABLE epitope.experiment (
    exp_date date,
    note text,
    plate_no character varying(2),
    exp_id integer DEFAULT nextval('epitope.experiment_exp_id_seq'::regclass) NOT NULL
);


ALTER TABLE epitope.experiment OWNER TO :owner;

--
-- Name: gene_gene_id_seq; Type: SEQUENCE; Schema: epitope; Owner: :owner
--

CREATE SEQUENCE epitope.gene_gene_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE epitope.gene_gene_id_seq OWNER TO :owner;

--
-- Name: gene; Type: TABLE; Schema: epitope; Owner: :owner
--

CREATE TABLE epitope.gene (
    gene_id integer DEFAULT nextval('epitope.gene_gene_id_seq'::regclass) NOT NULL,
    gene_name character varying(10) DEFAULT ''::character varying NOT NULL,
    hxb2_start integer,
    hxb2_end integer
);


ALTER TABLE epitope.gene OWNER TO :owner;

--
-- Name: hla; Type: TABLE; Schema: epitope; Owner: :owner
--

CREATE TABLE epitope.hla (
    hla_id integer NOT NULL,
    type character varying(25),
    hla_genotype_id integer
);


ALTER TABLE epitope.hla OWNER TO :owner;

--
-- Name: hla_pept; Type: TABLE; Schema: epitope; Owner: :owner
--

CREATE TABLE epitope.hla_pept (
    hla_id integer NOT NULL,
    pept_id integer NOT NULL
);


ALTER TABLE epitope.hla_pept OWNER TO :owner;

--
-- Name: measure_id_seq; Type: SEQUENCE; Schema: epitope; Owner: :owner
--

CREATE SEQUENCE epitope.measure_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE epitope.measure_id_seq OWNER TO :owner;

--
-- Name: hla_response; Type: TABLE; Schema: epitope; Owner: :owner
--

CREATE TABLE epitope.hla_response (
    pept_id integer NOT NULL,
    blcl_id integer NOT NULL,
    exp_id integer NOT NULL,
    sample_id integer NOT NULL,
    cell_num integer,
    result character varying(10),
    measure_id integer DEFAULT nextval('epitope.measure_id_seq'::regclass) NOT NULL
);


ALTER TABLE epitope.hla_response OWNER TO :owner;

--
-- Name: pept_response; Type: TABLE; Schema: epitope; Owner: :owner
--

CREATE TABLE epitope.pept_response (
    pept_id integer NOT NULL,
    exp_id integer NOT NULL,
    sample_id integer NOT NULL,
    cell_num integer,
    result character varying(10),
    measure_id integer DEFAULT nextval('epitope.measure_id_seq'::regclass) NOT NULL
);


ALTER TABLE epitope.pept_response OWNER TO :owner;

--
-- Name: reading_reading_id_seq; Type: SEQUENCE; Schema: epitope; Owner: :owner
--

CREATE SEQUENCE epitope.reading_reading_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE epitope.reading_reading_id_seq OWNER TO :owner;

--
-- Name: reading; Type: TABLE; Schema: epitope; Owner: :owner
--

CREATE TABLE epitope.reading (
    measure_id integer NOT NULL,
    value integer,
    reading_id integer DEFAULT nextval('epitope.reading_reading_id_seq'::regclass) NOT NULL
);


ALTER TABLE epitope.reading OWNER TO :owner;

--
-- Name: hla_response_avg; Type: VIEW; Schema: epitope; Owner: :owner
--

CREATE VIEW epitope.hla_response_avg AS
 SELECT hr.measure_id,
    pr.measure_id AS bg_measure_id,
    hr.pept_id,
    hr.sample_id,
    hr.exp_id,
    hr.blcl_id,
    avg(r.value) AS avg
   FROM ((epitope.hla_response hr
     JOIN epitope.reading r ON ((r.measure_id = hr.measure_id)))
     JOIN epitope.pept_response pr USING (exp_id, sample_id))
  WHERE (pr.pept_id = 1)
  GROUP BY hr.exp_id, hr.measure_id, hr.blcl_id, pr.measure_id, hr.pept_id, hr.sample_id
  ORDER BY hr.exp_id, hr.measure_id, hr.blcl_id;


ALTER TABLE epitope.hla_response_avg OWNER TO :owner;

--
-- Name: pept_response_avg; Type: VIEW; Schema: epitope; Owner: :owner
--

CREATE VIEW epitope.pept_response_avg AS
 SELECT pept_response.measure_id,
    pept_response.pept_id,
    pept_response.exp_id,
    pept_response.sample_id,
    avg(reading.value) AS avg
   FROM (epitope.pept_response
     JOIN epitope.reading USING (measure_id))
  GROUP BY pept_response.measure_id, pept_response.pept_id, pept_response.exp_id, pept_response.sample_id;


ALTER TABLE epitope.pept_response_avg OWNER TO :owner;

--
-- Name: vv_uid; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.vv_uid
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.vv_uid OWNER TO :owner;

--
-- Name: sample; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.sample (
    sample_id integer NOT NULL,
    sample_type_id integer,
    tissue_type_id integer,
    received_date date,
    name character varying(25),
    visit_id integer,
    vv_uid integer DEFAULT nextval('viroserve.vv_uid'::regclass) NOT NULL,
    date_added date DEFAULT now() NOT NULL,
    additive_id integer,
    is_deleted boolean DEFAULT false NOT NULL,
    derivation_id integer,
    date_collected date,
    CONSTRAINT visit_xor_derivation CHECK (((((visit_id IS NULL) AND (derivation_id IS NOT NULL)) OR ((visit_id IS NOT NULL) AND (derivation_id IS NULL))) OR ((visit_id IS NULL) AND (derivation_id IS NULL))))
);


ALTER TABLE viroserve.sample OWNER TO :owner;

SET default_with_oids = true;

--
-- Name: tissue_type; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.tissue_type (
    tissue_type_id integer NOT NULL,
    name character varying(45) NOT NULL
);


ALTER TABLE viroserve.tissue_type OWNER TO :owner;

--
-- Name: visit; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.visit (
    visit_id integer NOT NULL,
    patient_id integer NOT NULL,
    visit_date date,
    visit_number character varying(15),
    vv_uid integer DEFAULT nextval('viroserve.vv_uid'::regclass) NOT NULL,
    date_entered date DEFAULT now() NOT NULL,
    external_visit_id character varying(20),
    is_deleted boolean DEFAULT false NOT NULL
);


ALTER TABLE viroserve.visit OWNER TO :owner;

--
-- Name: sample; Type: VIEW; Schema: epitope; Owner: :owner
--

CREATE VIEW epitope.sample AS
 SELECT sample.sample_id,
    tissue_type.name AS tissue,
    visit.visit_date AS sample_date,
    viroserve.patient_name(visit.patient_id) AS patient,
    visit.patient_id
   FROM ((viroserve.sample
     JOIN viroserve.visit USING (visit_id))
     JOIN viroserve.tissue_type USING (tissue_type_id));


ALTER TABLE epitope.sample OWNER TO :owner;

--
-- Name: hla_response_corravg; Type: VIEW; Schema: epitope; Owner: :owner
--

CREATE VIEW epitope.hla_response_corravg AS
 SELECT hra.measure_id,
    hra.bg_measure_id,
    hra.pept_id,
    hra.exp_id,
    hra.sample_id,
    s.patient_id,
    hra.blcl_id,
    hra.avg,
    (hra.avg - ( SELECT pra.avg
           FROM epitope.pept_response_avg pra
          WHERE (hra.bg_measure_id = pra.measure_id))) AS corr_avg
   FROM (epitope.hla_response_avg hra
     JOIN epitope.sample s USING (sample_id))
  ORDER BY hra.measure_id;


ALTER TABLE epitope.hla_response_corravg OWNER TO :owner;

SET default_with_oids = false;

--
-- Name: measurement; Type: TABLE; Schema: epitope; Owner: :owner
--

CREATE TABLE epitope.measurement (
    measure_id integer NOT NULL
);


ALTER TABLE epitope.measurement OWNER TO :owner;

--
-- Name: mutant_mutant_id_seq; Type: SEQUENCE; Schema: epitope; Owner: :owner
--

CREATE SEQUENCE epitope.mutant_mutant_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE epitope.mutant_mutant_id_seq OWNER TO :owner;

--
-- Name: mutant; Type: TABLE; Schema: epitope; Owner: :owner
--

CREATE TABLE epitope.mutant (
    mutant_id integer DEFAULT nextval('epitope.mutant_mutant_id_seq'::regclass) NOT NULL,
    pept_id integer NOT NULL
);


ALTER TABLE epitope.mutant OWNER TO :owner;

--
-- Name: origin_origin_id_seq; Type: SEQUENCE; Schema: epitope; Owner: :owner
--

CREATE SEQUENCE epitope.origin_origin_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE epitope.origin_origin_id_seq OWNER TO :owner;

--
-- Name: origin; Type: TABLE; Schema: epitope; Owner: :owner
--

CREATE TABLE epitope.origin (
    origin_id integer DEFAULT nextval('epitope.origin_origin_id_seq'::regclass) NOT NULL,
    name character varying(20),
    na_sequence_id integer,
    na_sequence_revision integer
);


ALTER TABLE epitope.origin OWNER TO :owner;

--
-- Name: origin_peptide; Type: TABLE; Schema: epitope; Owner: :owner
--

CREATE TABLE epitope.origin_peptide (
    origin_id integer NOT NULL,
    pept_id integer NOT NULL
);


ALTER TABLE epitope.origin_peptide OWNER TO :owner;

--
-- Name: pept_response_corravg; Type: VIEW; Schema: epitope; Owner: :owner
--

CREATE VIEW epitope.pept_response_corravg AS
 SELECT va.measure_id,
    p.measure_id AS bg_measure_id,
    va.pept_id,
    va.exp_id,
    s.patient_id,
    va.sample_id,
    va.avg,
    (va.avg - ( SELECT a.avg
           FROM epitope.pept_response_avg a
          WHERE (a.measure_id = p.measure_id))) AS corr_avg
   FROM ((epitope.pept_response_avg va
     JOIN epitope.sample s USING (sample_id))
     LEFT JOIN epitope.pept_response p USING (exp_id, sample_id))
  WHERE (p.pept_id = 1)
  ORDER BY va.measure_id;


ALTER TABLE epitope.pept_response_corravg OWNER TO :owner;

--
-- Name: peptide_pept_id_seq; Type: SEQUENCE; Schema: epitope; Owner: :owner
--

CREATE SEQUENCE epitope.peptide_pept_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE epitope.peptide_pept_id_seq OWNER TO :owner;

--
-- Name: peptide; Type: TABLE; Schema: epitope; Owner: :owner
--

CREATE TABLE epitope.peptide (
    pept_id integer DEFAULT nextval('epitope.peptide_pept_id_seq'::regclass) NOT NULL,
    name character varying(50) DEFAULT ''::character varying NOT NULL,
    sequence character varying(50),
    origin_id integer DEFAULT 1,
    gene_id integer,
    position_hxb2_start integer,
    position_hxb2_end integer,
    position_auto_start integer,
    position_auto_end integer,
    position_align_start integer,
    position_align_end integer
);


ALTER TABLE epitope.peptide OWNER TO :owner;

--
-- Name: pool_pool_id_seq; Type: SEQUENCE; Schema: epitope; Owner: :owner
--

CREATE SEQUENCE epitope.pool_pool_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE epitope.pool_pool_id_seq OWNER TO :owner;

--
-- Name: pool; Type: TABLE; Schema: epitope; Owner: :owner
--

CREATE TABLE epitope.pool (
    pool_id integer DEFAULT nextval('epitope.pool_pool_id_seq'::regclass) NOT NULL,
    name character varying(25)
);


ALTER TABLE epitope.pool OWNER TO :owner;

--
-- Name: pool_pept; Type: TABLE; Schema: epitope; Owner: :owner
--

CREATE TABLE epitope.pool_pept (
    pool_id integer NOT NULL,
    pept_id integer NOT NULL
);


ALTER TABLE epitope.pool_pept OWNER TO :owner;

--
-- Name: pool_response; Type: TABLE; Schema: epitope; Owner: :owner
--

CREATE TABLE epitope.pool_response (
    pool_id integer NOT NULL,
    exp_id integer NOT NULL,
    sample_id integer NOT NULL,
    cell_num integer,
    matrix_index character(2),
    result character(1),
    measure_id integer DEFAULT nextval('epitope.measure_id_seq'::regclass) NOT NULL
);


ALTER TABLE epitope.pool_response OWNER TO :owner;

--
-- Name: pool_response_avg; Type: VIEW; Schema: epitope; Owner: :owner
--

CREATE VIEW epitope.pool_response_avg AS
 SELECT pool_response.measure_id,
    pept_response.measure_id AS bg_measure_id,
    pool_response.pool_id,
    pool_response.sample_id,
    pool_response.exp_id,
    avg(reading.value) AS avg
   FROM ((epitope.pool_response
     JOIN epitope.reading USING (measure_id))
     JOIN epitope.pept_response USING (exp_id, sample_id))
  WHERE (pept_response.pept_id = 1)
  GROUP BY pool_response.exp_id, pool_response.measure_id, pept_response.measure_id, pool_response.pool_id, pool_response.sample_id
  ORDER BY pool_response.exp_id, pool_response.measure_id;


ALTER TABLE epitope.pool_response_avg OWNER TO :owner;

--
-- Name: pool_response_corravg; Type: VIEW; Schema: epitope; Owner: :owner
--

CREATE VIEW epitope.pool_response_corravg AS
 SELECT pool_response_avg.measure_id,
    pool_response_avg.bg_measure_id,
    pool_response_avg.pool_id,
    pool_response_avg.exp_id,
    pool_response_avg.sample_id,
    pool_response_avg.avg,
    (pool_response_avg.avg - ( SELECT pept_response_avg.avg
           FROM epitope.pept_response_avg
          WHERE (pool_response_avg.bg_measure_id = pept_response_avg.measure_id))) AS corr_avg,
    epitope.pool_response_result(pool_response_avg.measure_id, pool_response_avg.bg_measure_id) AS result
   FROM epitope.pool_response_avg
  ORDER BY pool_response_avg.measure_id;


ALTER TABLE epitope.pool_response_corravg OWNER TO :owner;

--
-- Name: test_patient; Type: VIEW; Schema: epitope; Owner: :owner
--

CREATE VIEW epitope.test_patient AS
 SELECT DISTINCT s.patient_id,
    s.patient
   FROM (epitope.sample s
     JOIN epitope.pept_response pr USING (sample_id))
  ORDER BY s.patient_id, s.patient;


ALTER TABLE epitope.test_patient OWNER TO :owner;

--
-- Name: titration; Type: TABLE; Schema: epitope; Owner: :owner
--

CREATE TABLE epitope.titration (
    pept_id integer NOT NULL,
    exp_id integer NOT NULL,
    sample_id integer NOT NULL,
    cell_num integer,
    ec50 character varying(8),
    measure_id integer DEFAULT nextval('epitope.measure_id_seq'::regclass) NOT NULL,
    conc_id integer NOT NULL
);


ALTER TABLE epitope.titration OWNER TO :owner;

--
-- Name: titration_avg; Type: VIEW; Schema: epitope; Owner: :owner
--

CREATE VIEW epitope.titration_avg AS
 SELECT t.measure_id,
    pr.measure_id AS bg_measure_id,
    t.pept_id,
    t.sample_id,
    t.exp_id,
    t.conc_id,
    avg(r.value) AS avg
   FROM ((epitope.titration t
     JOIN epitope.reading r ON ((r.measure_id = t.measure_id)))
     JOIN epitope.pept_response pr USING (exp_id, sample_id))
  WHERE (pr.pept_id = 1)
  GROUP BY t.exp_id, t.measure_id, t.conc_id, pr.measure_id, t.pept_id, t.sample_id
  ORDER BY t.exp_id, t.measure_id, t.conc_id;


ALTER TABLE epitope.titration_avg OWNER TO :owner;

--
-- Name: titration_conc_conc_id_seq; Type: SEQUENCE; Schema: epitope; Owner: :owner
--

CREATE SEQUENCE epitope.titration_conc_conc_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE epitope.titration_conc_conc_id_seq OWNER TO :owner;

--
-- Name: titration_conc; Type: TABLE; Schema: epitope; Owner: :owner
--

CREATE TABLE epitope.titration_conc (
    conc_id integer DEFAULT nextval('epitope.titration_conc_conc_id_seq'::regclass) NOT NULL,
    conc numeric
);


ALTER TABLE epitope.titration_conc OWNER TO :owner;

--
-- Name: titration_corravg; Type: VIEW; Schema: epitope; Owner: :owner
--

CREATE VIEW epitope.titration_corravg AS
 SELECT ta.measure_id,
    ta.bg_measure_id,
    ta.pept_id,
    ta.exp_id,
    ta.sample_id,
    s.patient_id,
    ta.conc_id,
    ta.avg,
    (ta.avg - ( SELECT pra.avg
           FROM epitope.pept_response_avg pra
          WHERE (ta.bg_measure_id = pra.measure_id))) AS corr_avg,
    t.ec50
   FROM ((epitope.titration_avg ta
     JOIN epitope.sample s USING (sample_id))
     JOIN epitope.titration t ON ((t.measure_id = ta.measure_id)))
  ORDER BY ta.measure_id;


ALTER TABLE epitope.titration_corravg OWNER TO :owner;

--
-- Name: box; Type: TABLE; Schema: freezer; Owner: :owner
--

CREATE TABLE freezer.box (
    box_id integer NOT NULL,
    rack_id integer,
    name character varying NOT NULL,
    order_key integer,
    num_rows integer DEFAULT 9,
    num_columns integer DEFAULT 9,
    creating_scientist_id integer,
    owning_scientist_id integer
);


ALTER TABLE freezer.box OWNER TO :owner;

--
-- Name: box_box_id_seq; Type: SEQUENCE; Schema: freezer; Owner: :owner
--

CREATE SEQUENCE freezer.box_box_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE freezer.box_box_id_seq OWNER TO :owner;

--
-- Name: box_box_id_seq; Type: SEQUENCE OWNED BY; Schema: freezer; Owner: :owner
--

ALTER SEQUENCE freezer.box_box_id_seq OWNED BY freezer.box.box_id;


--
-- Name: box_pos; Type: TABLE; Schema: freezer; Owner: :owner
--

CREATE TABLE freezer.box_pos (
    box_pos_id integer NOT NULL,
    box_id integer NOT NULL,
    name character(3) NOT NULL,
    pos integer,
    aliquot_id integer
);


ALTER TABLE freezer.box_pos OWNER TO :owner;

--
-- Name: box_pos_box_pos_id_seq; Type: SEQUENCE; Schema: freezer; Owner: :owner
--

CREATE SEQUENCE freezer.box_pos_box_pos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE freezer.box_pos_box_pos_id_seq OWNER TO :owner;

--
-- Name: box_pos_box_pos_id_seq; Type: SEQUENCE OWNED BY; Schema: freezer; Owner: :owner
--

ALTER SEQUENCE freezer.box_pos_box_pos_id_seq OWNED BY freezer.box_pos.box_pos_id;


--
-- Name: freezer; Type: TABLE; Schema: freezer; Owner: :owner
--

CREATE TABLE freezer.freezer (
    freezer_id integer NOT NULL,
    name character varying(255) NOT NULL,
    owning_scientist_id integer,
    creating_scientist_id integer,
    description text,
    location character varying,
    upright_chest character(1),
    cane_alpha_int character(1) DEFAULT 'a'::bpchar,
    vv_uid integer DEFAULT nextval('viroserve.vv_uid'::regclass) NOT NULL,
    is_offsite boolean DEFAULT false NOT NULL
);


ALTER TABLE freezer.freezer OWNER TO :owner;

--
-- Name: freezer_freezer_id_seq; Type: SEQUENCE; Schema: freezer; Owner: :owner
--

CREATE SEQUENCE freezer.freezer_freezer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE freezer.freezer_freezer_id_seq OWNER TO :owner;

--
-- Name: freezer_freezer_id_seq; Type: SEQUENCE OWNED BY; Schema: freezer; Owner: :owner
--

ALTER SEQUENCE freezer.freezer_freezer_id_seq OWNED BY freezer.freezer.freezer_id;


--
-- Name: rack; Type: TABLE; Schema: freezer; Owner: :owner
--

CREATE TABLE freezer.rack (
    rack_id integer NOT NULL,
    freezer_id integer NOT NULL,
    creating_scientist_id integer,
    owning_scientist_id integer,
    num_rows integer DEFAULT 12,
    num_columns integer DEFAULT 1,
    order_key integer,
    name character varying
);


ALTER TABLE freezer.rack OWNER TO :owner;

--
-- Name: rack_rack_id_seq; Type: SEQUENCE; Schema: freezer; Owner: :owner
--

CREATE SEQUENCE freezer.rack_rack_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE freezer.rack_rack_id_seq OWNER TO :owner;

--
-- Name: rack_rack_id_seq; Type: SEQUENCE OWNED BY; Schema: freezer; Owner: :owner
--

ALTER SEQUENCE freezer.rack_rack_id_seq OWNED BY freezer.rack.rack_id;


--
-- Name: changes; Type: TABLE; Schema: sqitch; Owner: :owner
--

CREATE TABLE sqitch.changes (
    change_id text NOT NULL,
    change text NOT NULL,
    project text NOT NULL,
    note text DEFAULT ''::text NOT NULL,
    committed_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    committer_name text NOT NULL,
    committer_email text NOT NULL,
    planned_at timestamp with time zone NOT NULL,
    planner_name text NOT NULL,
    planner_email text NOT NULL
);


ALTER TABLE sqitch.changes OWNER TO :owner;

--
-- Name: TABLE changes; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON TABLE sqitch.changes IS 'Tracks the changes currently deployed to the database.';


--
-- Name: COLUMN changes.change_id; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.changes.change_id IS 'Change primary key.';


--
-- Name: COLUMN changes.change; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.changes.change IS 'Name of a deployed change.';


--
-- Name: COLUMN changes.project; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.changes.project IS 'Name of the Sqitch project to which the change belongs.';


--
-- Name: COLUMN changes.note; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.changes.note IS 'Description of the change.';


--
-- Name: COLUMN changes.committed_at; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.changes.committed_at IS 'Date the change was deployed.';


--
-- Name: COLUMN changes.committer_name; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.changes.committer_name IS 'Name of the user who deployed the change.';


--
-- Name: COLUMN changes.committer_email; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.changes.committer_email IS 'Email address of the user who deployed the change.';


--
-- Name: COLUMN changes.planned_at; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.changes.planned_at IS 'Date the change was added to the plan.';


--
-- Name: COLUMN changes.planner_name; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.changes.planner_name IS 'Name of the user who planed the change.';


--
-- Name: COLUMN changes.planner_email; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.changes.planner_email IS 'Email address of the user who planned the change.';


--
-- Name: dependencies; Type: TABLE; Schema: sqitch; Owner: :owner
--

CREATE TABLE sqitch.dependencies (
    change_id text NOT NULL,
    type text NOT NULL,
    dependency text NOT NULL,
    dependency_id text,
    CONSTRAINT dependencies_check CHECK ((((type = 'require'::text) AND (dependency_id IS NOT NULL)) OR ((type = 'conflict'::text) AND (dependency_id IS NULL))))
);


ALTER TABLE sqitch.dependencies OWNER TO :owner;

--
-- Name: TABLE dependencies; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON TABLE sqitch.dependencies IS 'Tracks the currently satisfied dependencies.';


--
-- Name: COLUMN dependencies.change_id; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.dependencies.change_id IS 'ID of the depending change.';


--
-- Name: COLUMN dependencies.type; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.dependencies.type IS 'Type of dependency.';


--
-- Name: COLUMN dependencies.dependency; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.dependencies.dependency IS 'Dependency name.';


--
-- Name: COLUMN dependencies.dependency_id; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.dependencies.dependency_id IS 'Change ID the dependency resolves to.';


--
-- Name: events; Type: TABLE; Schema: sqitch; Owner: :owner
--

CREATE TABLE sqitch.events (
    event text NOT NULL,
    change_id text NOT NULL,
    change text NOT NULL,
    project text NOT NULL,
    note text DEFAULT ''::text NOT NULL,
    requires text[] DEFAULT '{}'::text[] NOT NULL,
    conflicts text[] DEFAULT '{}'::text[] NOT NULL,
    tags text[] DEFAULT '{}'::text[] NOT NULL,
    committed_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    committer_name text NOT NULL,
    committer_email text NOT NULL,
    planned_at timestamp with time zone NOT NULL,
    planner_name text NOT NULL,
    planner_email text NOT NULL,
    CONSTRAINT events_event_check CHECK ((event = ANY (ARRAY['deploy'::text, 'revert'::text, 'fail'::text])))
);


ALTER TABLE sqitch.events OWNER TO :owner;

--
-- Name: TABLE events; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON TABLE sqitch.events IS 'Contains full history of all deployment events.';


--
-- Name: COLUMN events.event; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.events.event IS 'Type of event.';


--
-- Name: COLUMN events.change_id; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.events.change_id IS 'Change ID.';


--
-- Name: COLUMN events.change; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.events.change IS 'Change name.';


--
-- Name: COLUMN events.project; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.events.project IS 'Name of the Sqitch project to which the change belongs.';


--
-- Name: COLUMN events.note; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.events.note IS 'Description of the change.';


--
-- Name: COLUMN events.requires; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.events.requires IS 'Array of the names of required changes.';


--
-- Name: COLUMN events.conflicts; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.events.conflicts IS 'Array of the names of conflicting changes.';


--
-- Name: COLUMN events.tags; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.events.tags IS 'Tags associated with the change.';


--
-- Name: COLUMN events.committed_at; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.events.committed_at IS 'Date the event was committed.';


--
-- Name: COLUMN events.committer_name; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.events.committer_name IS 'Name of the user who committed the event.';


--
-- Name: COLUMN events.committer_email; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.events.committer_email IS 'Email address of the user who committed the event.';


--
-- Name: COLUMN events.planned_at; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.events.planned_at IS 'Date the event was added to the plan.';


--
-- Name: COLUMN events.planner_name; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.events.planner_name IS 'Name of the user who planed the change.';


--
-- Name: COLUMN events.planner_email; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.events.planner_email IS 'Email address of the user who plan planned the change.';


--
-- Name: projects; Type: TABLE; Schema: sqitch; Owner: :owner
--

CREATE TABLE sqitch.projects (
    project text NOT NULL,
    uri text,
    created_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    creator_name text NOT NULL,
    creator_email text NOT NULL
);


ALTER TABLE sqitch.projects OWNER TO :owner;

--
-- Name: TABLE projects; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON TABLE sqitch.projects IS 'Sqitch projects deployed to this database.';


--
-- Name: COLUMN projects.project; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.projects.project IS 'Unique Name of a project.';


--
-- Name: COLUMN projects.uri; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.projects.uri IS 'Optional project URI';


--
-- Name: COLUMN projects.created_at; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.projects.created_at IS 'Date the project was added to the database.';


--
-- Name: COLUMN projects.creator_name; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.projects.creator_name IS 'Name of the user who added the project.';


--
-- Name: COLUMN projects.creator_email; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.projects.creator_email IS 'Email address of the user who added the project.';


--
-- Name: tags; Type: TABLE; Schema: sqitch; Owner: :owner
--

CREATE TABLE sqitch.tags (
    tag_id text NOT NULL,
    tag text NOT NULL,
    project text NOT NULL,
    change_id text NOT NULL,
    note text DEFAULT ''::text NOT NULL,
    committed_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    committer_name text NOT NULL,
    committer_email text NOT NULL,
    planned_at timestamp with time zone NOT NULL,
    planner_name text NOT NULL,
    planner_email text NOT NULL
);


ALTER TABLE sqitch.tags OWNER TO :owner;

--
-- Name: TABLE tags; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON TABLE sqitch.tags IS 'Tracks the tags currently applied to the database.';


--
-- Name: COLUMN tags.tag_id; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.tags.tag_id IS 'Tag primary key.';


--
-- Name: COLUMN tags.tag; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.tags.tag IS 'Project-unique tag name.';


--
-- Name: COLUMN tags.project; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.tags.project IS 'Name of the Sqitch project to which the tag belongs.';


--
-- Name: COLUMN tags.change_id; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.tags.change_id IS 'ID of last change deployed before the tag was applied.';


--
-- Name: COLUMN tags.note; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.tags.note IS 'Description of the tag.';


--
-- Name: COLUMN tags.committed_at; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.tags.committed_at IS 'Date the tag was applied to the database.';


--
-- Name: COLUMN tags.committer_name; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.tags.committer_name IS 'Name of the user who applied the tag.';


--
-- Name: COLUMN tags.committer_email; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.tags.committer_email IS 'Email address of the user who applied the tag.';


--
-- Name: COLUMN tags.planned_at; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.tags.planned_at IS 'Date the tag was added to the plan.';


--
-- Name: COLUMN tags.planner_name; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.tags.planner_name IS 'Name of the user who planed the tag.';


--
-- Name: COLUMN tags.planner_email; Type: COMMENT; Schema: sqitch; Owner: :owner
--

COMMENT ON COLUMN sqitch.tags.planner_email IS 'Email address of the user who planned the tag.';


--
-- Name: hla_genotype; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.hla_genotype (
    hla_genotype_id integer NOT NULL,
    mhc_class smallint,
    locus character varying(4),
    workshop character(1),
    type smallint,
    subtype smallint,
    synonymous_polymorphism smallint,
    utr_polymorphism smallint,
    expression_level character(1),
    supertype character varying(3),
    ambiguity_group viroserve.hla_genotype_ambiguity_code
);


ALTER TABLE viroserve.hla_genotype OWNER TO :owner;

--
-- Name: patient_hla_genotype; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.patient_hla_genotype (
    hla_genotype_id integer,
    patient_id integer,
    vv_uid integer DEFAULT nextval('viroserve.vv_uid'::regclass)
);


ALTER TABLE viroserve.patient_hla_genotype OWNER TO :owner;

--
-- Name: _vhla_genotype; Type: VIEW; Schema: viroserve; Owner: :owner
--

CREATE VIEW viroserve._vhla_genotype AS
 SELECT patient_hla_genotype.hla_genotype_id,
    patient_hla_genotype.patient_id,
    hla_genotype.mhc_class,
    hla_genotype.locus,
    hla_genotype.workshop,
        CASE
            WHEN (hla_genotype.type < 10) THEN (((hla_genotype.locus)::text || '*0'::text) || (hla_genotype.type)::text)
            ELSE (((hla_genotype.locus)::text || '*'::text) || (hla_genotype.type)::text)
        END AS type,
        CASE
            WHEN ((hla_genotype.type < 10) AND (hla_genotype.subtype < 10)) THEN (((((hla_genotype.locus)::text || '*0'::text) || (hla_genotype.type)::text) || '0'::text) || (hla_genotype.subtype)::text)
            WHEN (hla_genotype.type < 10) THEN ((((hla_genotype.locus)::text || '*0'::text) || (hla_genotype.type)::text) || (hla_genotype.subtype)::text)
            WHEN (hla_genotype.subtype < 10) THEN (((((hla_genotype.locus)::text || '*'::text) || (hla_genotype.type)::text) || '0'::text) || (hla_genotype.subtype)::text)
            ELSE ((((hla_genotype.locus)::text || '*'::text) || (hla_genotype.type)::text) || (hla_genotype.subtype)::text)
        END AS subtype,
    hla_genotype.synonymous_polymorphism,
    hla_genotype.utr_polymorphism,
    hla_genotype.expression_level,
    hla_genotype.supertype,
    viroserve.hla_designation(patient_hla_genotype.hla_genotype_id) AS full_hla,
    hla_genotype.ambiguity_group
   FROM (viroserve.patient_hla_genotype
     JOIN viroserve.hla_genotype USING (hla_genotype_id));


ALTER TABLE viroserve._vhla_genotype OWNER TO :owner;

SET default_with_oids = true;

--
-- Name: lab_result_cat; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.lab_result_cat (
    lab_result_cat_id integer NOT NULL,
    lab_result_cat_value_id integer NOT NULL,
    lab_result_cat_type_id integer NOT NULL,
    sample_id integer,
    scientist_id integer,
    date_performed date,
    note character varying(255),
    date_added date DEFAULT now(),
    vv_uid integer DEFAULT nextval('viroserve.vv_uid'::regclass) NOT NULL,
    visit_id integer NOT NULL
);


ALTER TABLE viroserve.lab_result_cat OWNER TO :owner;

--
-- Name: lab_result_cat_type; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.lab_result_cat_type (
    lab_result_cat_type_id integer NOT NULL,
    name text,
    note character varying(255),
    normal_lab_result_cat_value_id integer,
    vv_uid integer DEFAULT nextval('viroserve.vv_uid'::regclass)
);


ALTER TABLE viroserve.lab_result_cat_type OWNER TO :owner;

--
-- Name: lab_result_cat_value; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.lab_result_cat_value (
    lab_result_cat_value_id integer NOT NULL,
    lab_result_cat_type_id integer,
    name character varying(25)
);


ALTER TABLE viroserve.lab_result_cat_value OWNER TO :owner;

--
-- Name: _vlab_result_cat; Type: VIEW; Schema: viroserve; Owner: :owner
--

CREATE VIEW viroserve._vlab_result_cat AS
 SELECT visit.patient_id,
    visit.visit_id,
    visit.visit_date AS lab_date,
    lab_result_cat.lab_result_cat_type_id,
    lab_result_cat_type.name,
    lab_result_cat_value.lab_result_cat_value_id,
    lab_result_cat_value.name AS value
   FROM (((viroserve.lab_result_cat
     JOIN viroserve.lab_result_cat_value USING (lab_result_cat_value_id, lab_result_cat_type_id))
     JOIN viroserve.lab_result_cat_type USING (lab_result_cat_type_id))
     JOIN viroserve.visit USING (visit_id));


ALTER TABLE viroserve._vlab_result_cat OWNER TO :owner;

SET default_with_oids = false;

--
-- Name: lab_result_num; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.lab_result_num (
    lab_result_num_id integer NOT NULL,
    lab_result_num_type_id integer NOT NULL,
    sample_id integer,
    scientist_id integer,
    date_performed date,
    value numeric NOT NULL,
    note character varying(255),
    vv_uid integer DEFAULT nextval('viroserve.vv_uid'::regclass),
    date_added date DEFAULT now(),
    visit_id integer NOT NULL
);


ALTER TABLE viroserve.lab_result_num OWNER TO :owner;

SET default_with_oids = true;

--
-- Name: lab_result_num_type; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.lab_result_num_type (
    lab_result_num_type_id integer NOT NULL,
    name text,
    unit_id integer,
    normal_min integer,
    normal_max integer,
    note character varying(255),
    vv_uid integer DEFAULT nextval('viroserve.vv_uid'::regclass) NOT NULL
);


ALTER TABLE viroserve.lab_result_num_type OWNER TO :owner;

SET default_with_oids = false;

--
-- Name: unit; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.unit (
    unit_id integer NOT NULL,
    name character varying(45) NOT NULL
);


ALTER TABLE viroserve.unit OWNER TO :owner;

--
-- Name: _vlab_result_num; Type: VIEW; Schema: viroserve; Owner: :owner
--

CREATE VIEW viroserve._vlab_result_num AS
 SELECT visit.patient_id,
    visit.visit_id,
    visit.visit_date AS lab_date,
    lab_result_num.lab_result_num_type_id,
    lab_result_num_type.name,
    lab_result_num.value,
    unit.name AS units
   FROM (((viroserve.lab_result_num
     JOIN viroserve.lab_result_num_type USING (lab_result_num_type_id))
     LEFT JOIN viroserve.unit USING (unit_id))
     JOIN viroserve.visit USING (visit_id));


ALTER TABLE viroserve._vlab_result_num OWNER TO :owner;

--
-- Name: bisulfite_converted_dna; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.bisulfite_converted_dna (
    bisulfite_converted_dna_id integer NOT NULL,
    extraction_id integer,
    rt_product_id integer,
    sample_id integer,
    protocol_id integer,
    scientist_id integer NOT NULL,
    date_entered date DEFAULT now(),
    date_completed date,
    note text,
    CONSTRAINT bisulfite_converted_dna_only_one_fk CHECK ((((((rt_product_id IS NOT NULL) AND (extraction_id IS NULL)) AND (sample_id IS NULL)) OR (((rt_product_id IS NULL) AND (extraction_id IS NOT NULL)) AND (sample_id IS NULL))) OR (((rt_product_id IS NULL) AND (extraction_id IS NULL)) AND (sample_id IS NOT NULL))))
);


ALTER TABLE viroserve.bisulfite_converted_dna OWNER TO :owner;

--
-- Name: extraction; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.extraction (
    extraction_id integer NOT NULL,
    sample_id integer,
    scientist_id integer NOT NULL,
    notes character varying(255),
    amount double precision,
    unit_id integer,
    date_entered date DEFAULT now() NOT NULL,
    date_completed date,
    vv_uid integer DEFAULT nextval('viroserve.vv_uid'::regclass) NOT NULL,
    concentration double precision,
    concentration_unit_id integer,
    eluted_vol double precision,
    eluted_vol_unit_id integer,
    protocol_id integer,
    extract_type_id integer,
    concentrated boolean,
    CONSTRAINT extraction_eluted_vol_unit_nullable CHECK (
CASE
    WHEN (eluted_vol IS NOT NULL) THEN (eluted_vol_unit_id IS NOT NULL)
    WHEN (eluted_vol IS NULL) THEN (eluted_vol_unit_id IS NULL)
    ELSE NULL::boolean
END)
);


ALTER TABLE viroserve.extraction OWNER TO :owner;

--
-- Name: pcr_product; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.pcr_product (
    pcr_product_id integer NOT NULL,
    scientist_id integer NOT NULL,
    name character varying(255),
    date_entered date DEFAULT now(),
    purified boolean,
    notes character varying(255),
    date_completed date,
    round integer,
    successful boolean,
    replicate integer,
    enzyme_id integer,
    hot_start boolean,
    protocol_id integer,
    vv_uid integer DEFAULT nextval('viroserve.vv_uid'::regclass) NOT NULL,
    genome_portion smallint,
    pcr_template_id integer,
    pcr_pool_id integer,
    reamp_round integer,
    endpoint_dilution boolean
);


ALTER TABLE viroserve.pcr_product OWNER TO :owner;

--
-- Name: pcr_template; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.pcr_template (
    pcr_template_id integer NOT NULL,
    scientist_id integer,
    volume double precision,
    unit_id integer,
    date_completed date NOT NULL,
    date_entered date DEFAULT now() NOT NULL,
    vv_uid integer DEFAULT nextval('viroserve.vv_uid'::regclass) NOT NULL,
    rt_product_id integer,
    extraction_id integer,
    pcr_product_id integer,
    dil_factor double precision,
    sample_id integer,
    bisulfite_converted_dna_id integer,
    CONSTRAINT pcr_template_only_one_fk CHECK ((((((((((rt_product_id IS NOT NULL) AND (extraction_id IS NULL)) AND (pcr_product_id IS NULL)) AND (sample_id IS NULL)) AND (bisulfite_converted_dna_id IS NULL)) OR (((((rt_product_id IS NULL) AND (extraction_id IS NOT NULL)) AND (pcr_product_id IS NULL)) AND (sample_id IS NULL)) AND (bisulfite_converted_dna_id IS NULL))) OR (((((rt_product_id IS NULL) AND (extraction_id IS NULL)) AND (pcr_product_id IS NOT NULL)) AND (sample_id IS NULL)) AND (bisulfite_converted_dna_id IS NULL))) OR (((((rt_product_id IS NULL) AND (extraction_id IS NULL)) AND (pcr_product_id IS NULL)) AND (sample_id IS NOT NULL)) AND (bisulfite_converted_dna_id IS NULL))) OR (((((rt_product_id IS NULL) AND (extraction_id IS NULL)) AND (pcr_product_id IS NULL)) AND (sample_id IS NULL)) AND (bisulfite_converted_dna_id IS NOT NULL))))
);


ALTER TABLE viroserve.pcr_template OWNER TO :owner;

--
-- Name: rt_product; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.rt_product (
    rt_product_id integer NOT NULL,
    extraction_id integer,
    scientist_id integer NOT NULL,
    name character varying(255),
    date_entered date DEFAULT now(),
    protocol_id integer,
    date_completed date,
    vv_uid integer DEFAULT nextval('viroserve.vv_uid'::regclass) NOT NULL,
    notes character varying(255),
    enzyme_id integer,
    rna_to_cdna_ratio numeric
);


ALTER TABLE viroserve.rt_product OWNER TO :owner;

--
-- Name: _vpatient_visit_sample_pcr; Type: VIEW; Schema: viroserve; Owner: :owner
--

CREATE VIEW viroserve._vpatient_visit_sample_pcr AS
 WITH RECURSIVE patient_to_pcr(patient_id, visit_id, visit_date, sample_id, extraction_id, rt_product_id, bisulfite_converted_dna_id, primogenitor_pcr_template_id, primogenitor_pcr_product_id, pcr_template_id, pcr_product_id, pcr_round, pcr_scientist_id) AS (
         SELECT visit.patient_id,
            sample.visit_id,
            visit.visit_date,
            sample.sample_id,
            extraction.extraction_id,
            rt_product.rt_product_id,
            bisulfite_converted_dna.bisulfite_converted_dna_id,
            pcr_product.pcr_template_id AS primogenitor_pcr_template_id,
            pcr_product.pcr_product_id AS primogenitor_pcr_product_id,
            pcr_product.pcr_template_id,
            pcr_product.pcr_product_id,
            pcr_product.round,
            pcr_product.scientist_id
           FROM ((((((viroserve.pcr_product
             JOIN viroserve.pcr_template USING (pcr_template_id))
             LEFT JOIN viroserve.bisulfite_converted_dna ON ((bisulfite_converted_dna.bisulfite_converted_dna_id = pcr_template.bisulfite_converted_dna_id)))
             LEFT JOIN viroserve.rt_product ON (((rt_product.rt_product_id = bisulfite_converted_dna.rt_product_id) OR (rt_product.rt_product_id = pcr_template.rt_product_id))))
             LEFT JOIN viroserve.extraction ON ((((extraction.extraction_id = bisulfite_converted_dna.extraction_id) OR (extraction.extraction_id = rt_product.extraction_id)) OR (extraction.extraction_id = pcr_template.extraction_id))))
             JOIN viroserve.sample ON ((((sample.sample_id = bisulfite_converted_dna.sample_id) OR (sample.sample_id = extraction.sample_id)) OR (sample.sample_id = pcr_template.sample_id))))
             JOIN viroserve.visit USING (visit_id))
        UNION
         SELECT patient_to_pcr_1.patient_id,
            patient_to_pcr_1.visit_id,
            patient_to_pcr_1.visit_date,
            patient_to_pcr_1.sample_id,
            patient_to_pcr_1.extraction_id,
            patient_to_pcr_1.rt_product_id,
            patient_to_pcr_1.bisulfite_converted_dna_id,
            patient_to_pcr_1.primogenitor_pcr_template_id,
            patient_to_pcr_1.primogenitor_pcr_product_id,
            pcr_template.pcr_template_id,
            pcr_descendant.pcr_product_id,
            pcr_descendant.round,
            pcr_descendant.scientist_id
           FROM (patient_to_pcr patient_to_pcr_1
             JOIN (viroserve.pcr_template
             JOIN viroserve.pcr_product pcr_descendant USING (pcr_template_id)) ON ((patient_to_pcr_1.pcr_product_id = pcr_template.pcr_product_id)))
        )
 SELECT patient_to_pcr.patient_id,
    patient_to_pcr.visit_id,
    patient_to_pcr.visit_date,
    patient_to_pcr.sample_id,
    patient_to_pcr.extraction_id,
    patient_to_pcr.rt_product_id,
    patient_to_pcr.bisulfite_converted_dna_id,
    patient_to_pcr.primogenitor_pcr_template_id,
    patient_to_pcr.primogenitor_pcr_product_id,
    patient_to_pcr.pcr_template_id,
    patient_to_pcr.pcr_product_id,
    patient_to_pcr.pcr_round,
    patient_to_pcr.pcr_scientist_id
   FROM patient_to_pcr;


ALTER TABLE viroserve._vpatient_visit_sample_pcr OWNER TO :owner;

--
-- Name: additive; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.additive (
    additive_id integer NOT NULL,
    name character varying(45) NOT NULL,
    created date DEFAULT now() NOT NULL
);


ALTER TABLE viroserve.additive OWNER TO :owner;

--
-- Name: additive_additive_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.additive_additive_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.additive_additive_id_seq OWNER TO :owner;

--
-- Name: additive_additive_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.additive_additive_id_seq OWNED BY viroserve.additive.additive_id;


--
-- Name: alignment; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.alignment (
    alignment_id integer NOT NULL,
    alignment_length integer,
    name character varying(45),
    date_entered date DEFAULT now(),
    alignment_method_id integer NOT NULL,
    scientist_id integer,
    note character varying(255),
    vv_uid integer DEFAULT nextval('viroserve.vv_uid'::regclass),
    alignment_revision integer NOT NULL,
    alignment_taxa_revision integer NOT NULL
);


ALTER TABLE viroserve.alignment OWNER TO :owner;

--
-- Name: alignment_alignment_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.alignment_alignment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.alignment_alignment_id_seq OWNER TO :owner;

--
-- Name: alignment_alignment_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.alignment_alignment_id_seq OWNED BY viroserve.alignment.alignment_id;


--
-- Name: alignment_latest_revision; Type: VIEW; Schema: viroserve; Owner: :owner
--

CREATE VIEW viroserve.alignment_latest_revision AS
 SELECT latest_revision.alignment_id,
    latest_revision.alignment_revision,
    max(alignment.alignment_taxa_revision) AS alignment_taxa_revision
   FROM (( SELECT alignment_1.alignment_id,
            max(alignment_1.alignment_revision) AS alignment_revision
           FROM viroserve.alignment alignment_1
          GROUP BY alignment_1.alignment_id) latest_revision
     JOIN viroserve.alignment USING (alignment_id, alignment_revision))
  GROUP BY latest_revision.alignment_id, latest_revision.alignment_revision;


ALTER TABLE viroserve.alignment_latest_revision OWNER TO :owner;

--
-- Name: alignment_method; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.alignment_method (
    alignment_method_id integer NOT NULL,
    name character varying(25)
);


ALTER TABLE viroserve.alignment_method OWNER TO :owner;

--
-- Name: alignment_method_alignment_method_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.alignment_method_alignment_method_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.alignment_method_alignment_method_id_seq OWNER TO :owner;

--
-- Name: alignment_method_alignment_method_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.alignment_method_alignment_method_id_seq OWNED BY viroserve.alignment_method.alignment_method_id;


--
-- Name: aliquot; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.aliquot (
    aliquot_id integer NOT NULL,
    sample_id integer NOT NULL,
    vol numeric,
    unit_id integer NOT NULL,
    creating_scientist_id integer,
    possessing_scientist_id integer,
    manifest_id integer,
    orphaned date,
    num_thaws integer DEFAULT 0 NOT NULL,
    date_entered date DEFAULT now(),
    received_date date,
    vv_uid bigint DEFAULT nextval('viroserve.vv_uid'::regclass),
    qc_d boolean DEFAULT false,
    is_deleted boolean DEFAULT false NOT NULL
);


ALTER TABLE viroserve.aliquot OWNER TO :owner;

--
-- Name: aliquot_aliquot_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.aliquot_aliquot_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.aliquot_aliquot_id_seq OWNER TO :owner;

--
-- Name: aliquot_aliquot_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.aliquot_aliquot_id_seq OWNED BY viroserve.aliquot.aliquot_id;


--
-- Name: arv_class; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.arv_class (
    arv_class_id integer NOT NULL,
    name text NOT NULL,
    abbreviation text NOT NULL
);


ALTER TABLE viroserve.arv_class OWNER TO :owner;

--
-- Name: arv_class_arv_class_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.arv_class_arv_class_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.arv_class_arv_class_id_seq OWNER TO :owner;

--
-- Name: arv_class_arv_class_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.arv_class_arv_class_id_seq OWNED BY viroserve.arv_class.arv_class_id;


--
-- Name: bisulfite_converted_dna_bisulfite_converted_dna_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.bisulfite_converted_dna_bisulfite_converted_dna_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.bisulfite_converted_dna_bisulfite_converted_dna_id_seq OWNER TO :owner;

--
-- Name: bisulfite_converted_dna_bisulfite_converted_dna_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.bisulfite_converted_dna_bisulfite_converted_dna_id_seq OWNED BY viroserve.bisulfite_converted_dna.bisulfite_converted_dna_id;


--
-- Name: cell_count; Type: VIEW; Schema: viroserve; Owner: :owner
--

CREATE VIEW viroserve.cell_count AS
 WITH assay AS (
         SELECT row_number() OVER (PARTITION BY x.cell_type) AS rank,
            x.cell_type,
            x.name
           FROM ( SELECT unnest(ARRAY['CD4'::text, 'CD8'::text]) AS cell_type,
                    unnest(ARRAY['CD4 calc'::text, 'CD8 calc'::text, 'CD4'::text, 'CD8'::text]) AS name) x
        ), cell_counts AS (
         SELECT visit.patient_id,
            visit.visit_date,
            lab.lab_result_num_id,
            assay.cell_type,
            lab_type.name AS assay,
            lab.value,
            lab.date_added,
            first_value(lab.lab_result_num_id) OVER labs_by_rank AS best_lab_result_num_id,
            first_value(lab_type.name) OVER labs_by_rank AS best_assay,
            first_value(lab.value) OVER labs_by_rank AS best_value,
            first_value(lab.date_added) OVER labs_by_rank AS best_date_added
           FROM (((viroserve.lab_result_num lab
             JOIN viroserve.lab_result_num_type lab_type USING (lab_result_num_type_id))
             JOIN viroserve.visit USING (visit_id))
             JOIN assay ON ((lab_type.name = assay.name)))
          WINDOW labs_by_rank AS (PARTITION BY visit.patient_id, visit.visit_date, assay.cell_type ORDER BY assay.rank, lab.date_added DESC, lab.lab_result_num_id DESC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
          ORDER BY visit.patient_id, visit.visit_date, assay.cell_type, lab.date_added
        )
 SELECT DISTINCT cell_counts.patient_id,
    cell_counts.visit_date,
    cell_counts.cell_type,
    cell_counts.best_value AS value,
    cell_counts.best_date_added AS date_added,
    cell_counts.best_lab_result_num_id AS lab_result_num_id
   FROM cell_counts
  ORDER BY cell_counts.patient_id, cell_counts.visit_date, cell_counts.cell_type;


ALTER TABLE viroserve.cell_count OWNER TO :owner;

--
-- Name: chromat; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.chromat (
    chromat_id integer NOT NULL,
    vv_uid integer DEFAULT nextval('viroserve.vv_uid'::regclass) NOT NULL,
    date_entered date DEFAULT now() NOT NULL,
    scientist_id integer NOT NULL,
    data bytea,
    name character varying(255),
    chromat_type_id integer NOT NULL,
    primer_id integer
);


ALTER TABLE viroserve.chromat OWNER TO :owner;

--
-- Name: chromat_chromat_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.chromat_chromat_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.chromat_chromat_id_seq OWNER TO :owner;

--
-- Name: chromat_chromat_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.chromat_chromat_id_seq OWNED BY viroserve.chromat.chromat_id;


--
-- Name: chromat_na_sequence; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.chromat_na_sequence (
    chromat_id integer,
    na_sequence_id integer,
    na_sequence_revision smallint
);


ALTER TABLE viroserve.chromat_na_sequence OWNER TO :owner;

--
-- Name: chromat_type; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.chromat_type (
    chromat_type_id integer NOT NULL,
    ident_string character varying(25) NOT NULL,
    name character varying(255) NOT NULL,
    date_added date DEFAULT now() NOT NULL
);


ALTER TABLE viroserve.chromat_type OWNER TO :owner;

--
-- Name: chromat_type_chromat_type_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.chromat_type_chromat_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.chromat_type_chromat_type_id_seq OWNER TO :owner;

--
-- Name: chromat_type_chromat_type_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.chromat_type_chromat_type_id_seq OWNED BY viroserve.chromat_type.chromat_type_id;


--
-- Name: clone; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.clone (
    clone_id integer NOT NULL,
    scientist_id integer NOT NULL,
    pcr_product_id integer,
    name character varying(20),
    date_completed date,
    vv_uid integer DEFAULT nextval('viroserve.vv_uid'::regclass) NOT NULL,
    date_added date DEFAULT now() NOT NULL
);


ALTER TABLE viroserve.clone OWNER TO :owner;

--
-- Name: clone_clone_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.clone_clone_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.clone_clone_id_seq OWNER TO :owner;

--
-- Name: clone_clone_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.clone_clone_id_seq OWNED BY viroserve.clone.clone_id;


--
-- Name: cohort_cohort_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.cohort_cohort_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.cohort_cohort_id_seq OWNER TO :owner;

SET default_with_oids = true;

--
-- Name: cohort; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.cohort (
    cohort_id smallint DEFAULT nextval('viroserve.cohort_cohort_id_seq'::regclass) NOT NULL,
    name character varying(25),
    abbr character(2),
    vv_uid integer DEFAULT nextval('viroserve.vv_uid'::regclass) NOT NULL
);


ALTER TABLE viroserve.cohort OWNER TO :owner;

SET default_with_oids = false;

--
-- Name: infection; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.infection (
    infection_id integer NOT NULL,
    location_id integer,
    patient_id integer NOT NULL,
    infection_earliest date,
    infection_latest date,
    seroconv_earliest date,
    seroconv_latest date,
    symptom_earliest date,
    symptom_latest date,
    note character varying(255),
    estimated_date date
);


ALTER TABLE viroserve.infection OWNER TO :owner;

--
-- Name: COLUMN infection.estimated_date; Type: COMMENT; Schema: viroserve; Owner: :owner
--

COMMENT ON COLUMN viroserve.infection.estimated_date IS 'Best estimated or calculated infection date, to be preferentially used in queries';


--
-- Name: medication; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.medication (
    medication_id integer NOT NULL,
    name text NOT NULL,
    abbreviation text NOT NULL,
    arv_class_id integer NOT NULL
);


ALTER TABLE viroserve.medication OWNER TO :owner;

SET default_with_oids = true;

--
-- Name: patient; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.patient (
    patient_id integer NOT NULL,
    location_id integer,
    gender viroserve.gender_code,
    birth date,
    death date,
    symptom_onset date,
    multiply_infected boolean,
    vv_uid integer DEFAULT nextval('viroserve.vv_uid'::regclass),
    date_added date DEFAULT now()
);


ALTER TABLE viroserve.patient OWNER TO :owner;

--
-- Name: patient_alias; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.patient_alias (
    cohort_id smallint NOT NULL,
    patient_id integer NOT NULL,
    external_patient_id character varying(25) NOT NULL,
    vv_uid integer DEFAULT nextval('viroserve.vv_uid'::regclass),
    type viroserve.patient_alias_type NOT NULL
);


ALTER TABLE viroserve.patient_alias OWNER TO :owner;

SET default_with_oids = false;

--
-- Name: patient_medication; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.patient_medication (
    patient_medication_id integer NOT NULL,
    start_date date,
    end_date date,
    patient_id integer NOT NULL,
    medication_id integer,
    not_on_art boolean DEFAULT false NOT NULL
);


ALTER TABLE viroserve.patient_medication OWNER TO :owner;

--
-- Name: COLUMN patient_medication.start_date; Type: COMMENT; Schema: viroserve; Owner: :owner
--

COMMENT ON COLUMN viroserve.patient_medication.start_date IS 'when null: start date unknown, i.e. patient was on this medication prior to first contact';


--
-- Name: COLUMN patient_medication.end_date; Type: COMMENT; Schema: viroserve; Owner: :owner
--

COMMENT ON COLUMN viroserve.patient_medication.end_date IS 'when null: this medication was ongoing at last point of contact';


--
-- Name: viral_load; Type: VIEW; Schema: viroserve; Owner: :owner
--

CREATE VIEW viroserve.viral_load AS
 WITH assay AS (
         SELECT row_number() OVER () AS rank,
            x.name
           FROM ( SELECT unnest(ARRAY['viral load (Abbott RealTime HIV-1)'::text, 'viral load (Roche Amplicor "ultra-sensitive" 2nd gen)'::text, 'viral load (Roche Amplicor 2nd gen)'::text, 'viral load (TAQMAN)'::text, 'viral load (Chiron 3rd generation)'::text, 'viral load (Chiron 2nd generation)'::text, 'viral load (Chiron 1st generation)'::text, 'viral load'::text]) AS name) x
        ), vls AS (
         SELECT visit.patient_id,
            visit.visit_date,
            vl.lab_result_num_id,
            lab_type.name AS assay,
            vl.value AS viral_load,
            vl.date_added,
            lab_type.normal_min AS limit_of_quantification,
            first_value(vl.lab_result_num_id) OVER vls_by_rank AS best_lab_result_num_id,
            first_value(lab_type.name) OVER vls_by_rank AS best_assay,
            first_value(vl.value) OVER vls_by_rank AS best_viral_load,
            first_value(vl.date_added) OVER vls_by_rank AS best_date_added,
            first_value(lab_type.normal_min) OVER vls_by_rank AS best_limit_of_quantification
           FROM (((viroserve.lab_result_num vl
             JOIN viroserve.lab_result_num_type lab_type USING (lab_result_num_type_id))
             JOIN viroserve.visit USING (visit_id))
             JOIN assay ON ((lab_type.name = assay.name)))
          WINDOW vls_by_rank AS (PARTITION BY visit.patient_id, visit.visit_date ORDER BY assay.rank, vl.date_added DESC, vl.value ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
          ORDER BY visit.patient_id, visit.visit_date, vl.date_added
        )
 SELECT DISTINCT vls.patient_id,
    vls.visit_date,
        CASE
            WHEN (vls.best_viral_load <= (vls.best_limit_of_quantification)::numeric) THEN (0)::numeric
            ELSE vls.best_viral_load
        END AS viral_load,
    vls.best_assay AS assay,
    vls.best_limit_of_quantification AS limit_of_quantification,
    vls.best_date_added AS date_added,
    vls.best_lab_result_num_id AS lab_result_num_id
   FROM vls
  ORDER BY vls.patient_id, vls.visit_date;


ALTER TABLE viroserve.viral_load OWNER TO :owner;

--
-- Name: cohort_patient_summary; Type: VIEW; Schema: viroserve; Owner: :owner
--

CREATE VIEW viroserve.cohort_patient_summary AS
 WITH vls AS (
         SELECT viral_load.patient_id,
            json_agg(ARRAY[(viral_load.visit_date)::text, (viral_load.viral_load)::text]) AS viral_load_values
           FROM viroserve.viral_load
          WHERE (viral_load.visit_date IS NOT NULL)
          GROUP BY viral_load.patient_id
        ), visits AS (
         SELECT visit.patient_id,
            min(visit.visit_date) AS first_visit,
            max(visit.visit_date) AS latest_visit
           FROM viroserve.visit
          GROUP BY visit.patient_id
        ), samples AS (
         SELECT patient.patient_id,
            count(*) FILTER (WHERE ((tissue_type.name)::text = 'PBMC'::text)) AS pbmc_count,
            count(*) FILTER (WHERE ((tissue_type.name)::text = 'plasma'::text)) AS plasma_count,
            count(*) FILTER (WHERE ((tissue_type.name)::text = 'Leukapheresed cells'::text)) AS leuka_count,
            count(*) FILTER (WHERE ((tissue_type.name)::text <> ALL ((ARRAY['Leukapheresed cells'::character varying, 'PBMC'::character varying, 'plasma'::character varying])::text[]))) AS other_count
           FROM (((viroserve.patient
             LEFT JOIN viroserve.visit USING (patient_id))
             LEFT JOIN viroserve.sample USING (visit_id))
             LEFT JOIN viroserve.tissue_type USING (tissue_type_id))
          WHERE (sample.tissue_type_id IS NOT NULL)
          GROUP BY patient.patient_id
        ), fiebig AS (
         SELECT _vlab_result_cat.patient_id,
            json_agg(ARRAY[(_vlab_result_cat.lab_date)::text, (_vlab_result_cat.value)::text]) AS fiebig_stages
           FROM viroserve._vlab_result_cat
          WHERE (_vlab_result_cat.name = 'Fiebig stage'::text)
          GROUP BY _vlab_result_cat.patient_id
        ), art AS (
         SELECT patient_medication.patient_id,
            min(patient_medication.start_date) AS art_initiation_date
           FROM ((viroserve.patient_medication
             JOIN viroserve.medication USING (medication_id))
             JOIN viroserve.arv_class USING (arv_class_id))
          WHERE ((arv_class.name <> 'Non-ARV booster'::text) AND (NOT patient_medication.not_on_art))
          GROUP BY patient_medication.patient_id
        )
 SELECT cohort.cohort_id,
    alias.patient_id,
    (((cohort.name)::text || ' '::text) || (alias.external_patient_id)::text) AS name,
    inf.estimated_date AS estimated_date_infected,
    art.art_initiation_date,
    visits.first_visit,
    visits.latest_visit,
    vls.viral_load_values,
    fiebig.fiebig_stages,
    samples.pbmc_count,
    samples.plasma_count,
    samples.leuka_count,
    samples.other_count
   FROM (((((((viroserve.cohort
     JOIN viroserve.patient_alias alias ON ((alias.cohort_id = cohort.cohort_id)))
     LEFT JOIN viroserve.infection inf USING (patient_id))
     LEFT JOIN vls USING (patient_id))
     LEFT JOIN visits USING (patient_id))
     LEFT JOIN samples USING (patient_id))
     LEFT JOIN fiebig USING (patient_id))
     LEFT JOIN art USING (patient_id))
  WHERE ((alias.type)::text = 'primary'::text);


ALTER TABLE viroserve.cohort_patient_summary OWNER TO :owner;

--
-- Name: competent_cells_competent_cells_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.competent_cells_competent_cells_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.competent_cells_competent_cells_id_seq OWNER TO :owner;

--
-- Name: copy_number; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.copy_number (
    copy_number_id integer NOT NULL,
    rt_product_id integer,
    extraction_id integer,
    value numeric,
    std_error numeric,
    vv_uid integer DEFAULT nextval('viroserve.vv_uid'::regclass) NOT NULL,
    scientist_id integer NOT NULL,
    date_created date DEFAULT now(),
    key character varying,
    rec_addition numeric,
    dil_table character varying,
    sample_id integer,
    bisulfite_converted_dna_id integer,
    CONSTRAINT copy_number_only_one_fk CHECK ((((((((rt_product_id IS NOT NULL) AND (extraction_id IS NULL)) AND (sample_id IS NULL)) AND (bisulfite_converted_dna_id IS NULL)) OR ((((rt_product_id IS NULL) AND (extraction_id IS NOT NULL)) AND (sample_id IS NULL)) AND (bisulfite_converted_dna_id IS NULL))) OR ((((rt_product_id IS NULL) AND (extraction_id IS NULL)) AND (sample_id IS NOT NULL)) AND (bisulfite_converted_dna_id IS NULL))) OR ((((rt_product_id IS NULL) AND (extraction_id IS NULL)) AND (sample_id IS NULL)) AND (bisulfite_converted_dna_id IS NOT NULL))))
);


ALTER TABLE viroserve.copy_number OWNER TO :owner;

--
-- Name: copy_number_copy_number_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.copy_number_copy_number_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.copy_number_copy_number_id_seq OWNER TO :owner;

--
-- Name: copy_number_copy_number_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.copy_number_copy_number_id_seq OWNED BY viroserve.copy_number.copy_number_id;


--
-- Name: copy_number_gel_lane; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.copy_number_gel_lane (
    copy_number_id integer NOT NULL,
    gel_lane_id integer NOT NULL
);


ALTER TABLE viroserve.copy_number_gel_lane OWNER TO :owner;

--
-- Name: enzyme; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.enzyme (
    enzyme_id integer NOT NULL,
    name character varying(45),
    short_name character varying(30),
    type viroserve.enzyme_type
);


ALTER TABLE viroserve.enzyme OWNER TO :owner;

--
-- Name: enzyme_enzyme_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.enzyme_enzyme_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.enzyme_enzyme_id_seq OWNER TO :owner;

--
-- Name: enzyme_enzyme_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.enzyme_enzyme_id_seq OWNED BY viroserve.enzyme.enzyme_id;


--
-- Name: extract_type; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.extract_type (
    extract_type_id integer NOT NULL,
    name character varying(15)
);


ALTER TABLE viroserve.extract_type OWNER TO :owner;

--
-- Name: extract_type_extract_type_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.extract_type_extract_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.extract_type_extract_type_id_seq OWNER TO :owner;

--
-- Name: extract_type_extract_type_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.extract_type_extract_type_id_seq OWNED BY viroserve.extract_type.extract_type_id;


--
-- Name: extraction_extraction_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.extraction_extraction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.extraction_extraction_id_seq OWNER TO :owner;

--
-- Name: extraction_extraction_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.extraction_extraction_id_seq OWNED BY viroserve.extraction.extraction_id;


--
-- Name: gel; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.gel (
    gel_id integer NOT NULL,
    protocol_id integer,
    scientist_id integer NOT NULL,
    date_completed date,
    date_entered date DEFAULT now() NOT NULL,
    notes character varying(255),
    image bytea,
    vv_uid integer DEFAULT nextval('viroserve.vv_uid'::regclass) NOT NULL,
    name character varying(255),
    mime_type character varying(40) NOT NULL,
    ninety_six_well boolean DEFAULT false NOT NULL
);


ALTER TABLE viroserve.gel OWNER TO :owner;

--
-- Name: gel_gel_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.gel_gel_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.gel_gel_id_seq OWNER TO :owner;

--
-- Name: gel_gel_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.gel_gel_id_seq OWNED BY viroserve.gel.gel_id;


--
-- Name: gel_lane; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.gel_lane (
    gel_lane_id integer NOT NULL,
    gel_id integer NOT NULL,
    pcr_product_id integer,
    name character varying(45),
    loc_x integer,
    loc_y integer,
    label character varying(5),
    pos_result boolean,
    vv_uid integer DEFAULT nextval('viroserve.vv_uid'::regclass) NOT NULL
);


ALTER TABLE viroserve.gel_lane OWNER TO :owner;

--
-- Name: gel_lane_gel_lane_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.gel_lane_gel_lane_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.gel_lane_gel_lane_id_seq OWNER TO :owner;

--
-- Name: gel_lane_gel_lane_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.gel_lane_gel_lane_id_seq OWNED BY viroserve.gel_lane.gel_lane_id;


--
-- Name: genome_region; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.genome_region (
    name text NOT NULL,
    base_start integer NOT NULL,
    base_end integer NOT NULL,
    base_range int4range NOT NULL,
    reading_frame numeric NOT NULL,
    CONSTRAINT genome_region_reading_frame_check CHECK ((((reading_frame = (1)::numeric) OR (reading_frame = (2)::numeric)) OR (reading_frame = (3)::numeric)))
);


ALTER TABLE viroserve.genome_region OWNER TO :owner;

--
-- Name: hla_genotype_hla_genotype_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.hla_genotype_hla_genotype_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.hla_genotype_hla_genotype_id_seq OWNER TO :owner;

--
-- Name: hla_genotype_hla_genotype_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.hla_genotype_hla_genotype_id_seq OWNED BY viroserve.hla_genotype.hla_genotype_id;


SET default_with_oids = true;

--
-- Name: na_sequence; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.na_sequence (
    na_sequence_id integer NOT NULL,
    na_sequence_revision smallint DEFAULT 1 NOT NULL,
    name character varying(255),
    sequence text NOT NULL,
    entered_date date DEFAULT ('now'::text)::date,
    trimmed boolean,
    note character varying(255),
    scientist_id integer,
    pcr_product_id integer,
    clone_id integer,
    sample_id integer,
    genbank_acc character varying(8),
    deleted boolean,
    vv_uid integer DEFAULT nextval('viroserve.vv_uid'::regclass) NOT NULL,
    na_type viroserve.na_type,
    sequence_type_id integer NOT NULL,
    CONSTRAINT na_sequence_sequence_length CHECK ((length(sequence) <> 0))
);


ALTER TABLE viroserve.na_sequence OWNER TO :owner;

SET default_with_oids = false;

--
-- Name: na_sequence_alignment; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.na_sequence_alignment (
    na_sequence_id integer NOT NULL,
    na_sequence_revision integer NOT NULL,
    alignment_id integer NOT NULL,
    alignment_revision integer NOT NULL,
    alignment_taxa_revision integer NOT NULL,
    is_reference boolean DEFAULT false NOT NULL
);


ALTER TABLE viroserve.na_sequence_alignment OWNER TO :owner;

--
-- Name: na_sequence_alignment_pairwise; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.na_sequence_alignment_pairwise (
    alignment_id integer NOT NULL,
    alignment_revision integer NOT NULL,
    alignment_taxa_revision integer DEFAULT 1 NOT NULL,
    sequence_start integer NOT NULL,
    sequence_end integer NOT NULL,
    reference_start integer NOT NULL,
    reference_end integer NOT NULL
);


ALTER TABLE viroserve.na_sequence_alignment_pairwise OWNER TO :owner;

--
-- Name: na_sequence_latest_revision; Type: VIEW; Schema: viroserve; Owner: :owner
--

CREATE VIEW viroserve.na_sequence_latest_revision AS
 SELECT na_sequence.na_sequence_id,
    max(na_sequence.na_sequence_revision) AS na_sequence_revision
   FROM viroserve.na_sequence
  WHERE (na_sequence.deleted IS NOT TRUE)
  GROUP BY na_sequence.na_sequence_id;


ALTER TABLE viroserve.na_sequence_latest_revision OWNER TO :owner;

--
-- Name: sequence_reference_alignment; Type: VIEW; Schema: viroserve; Owner: :owner
--

CREATE VIEW viroserve.sequence_reference_alignment AS
 SELECT DISTINCT query.na_sequence_id,
    query.na_sequence_revision,
    first_value(query.alignment_id) OVER (alignments) AS alignment_id,
    first_value(query.alignment_revision) OVER (alignments) AS alignment_revision,
    first_value(query.alignment_taxa_revision) OVER (alignments) AS alignment_taxa_revision
   FROM (((((viroserve.na_sequence_latest_revision
     JOIN viroserve.na_sequence_alignment query USING (na_sequence_id, na_sequence_revision))
     JOIN viroserve.alignment_latest_revision USING (alignment_id, alignment_revision, alignment_taxa_revision))
     JOIN viroserve.na_sequence_alignment reference USING (alignment_id, alignment_revision, alignment_taxa_revision))
     JOIN viroserve.alignment USING (alignment_id, alignment_revision, alignment_taxa_revision))
     JOIN viroserve.alignment_method USING (alignment_method_id))
  WHERE (((((NOT query.is_reference) AND reference.is_reference) AND (reference.na_sequence_id = 0)) AND (reference.na_sequence_id <> query.na_sequence_id)) AND ((alignment_method.name)::text = 'needle'::text))
  WINDOW alignments AS (PARTITION BY query.na_sequence_id, query.na_sequence_revision ORDER BY alignment.date_entered DESC, query.alignment_id DESC);


ALTER TABLE viroserve.sequence_reference_alignment OWNER TO :owner;

--
-- Name: sequence_reference_alignment_pairwise; Type: VIEW; Schema: viroserve; Owner: :owner
--

CREATE VIEW viroserve.sequence_reference_alignment_pairwise AS
 SELECT sequence_reference_alignment.alignment_id,
    sequence_reference_alignment.alignment_revision,
    sequence_reference_alignment.alignment_taxa_revision,
    sequence_reference_alignment.na_sequence_id,
    sequence_reference_alignment.na_sequence_revision,
    na_sequence_alignment_pairwise.sequence_start,
    na_sequence_alignment_pairwise.sequence_end,
    na_sequence_alignment_pairwise.reference_start,
    na_sequence_alignment_pairwise.reference_end
   FROM (viroserve.sequence_reference_alignment
     JOIN viroserve.na_sequence_alignment_pairwise USING (alignment_id, alignment_revision, alignment_taxa_revision));


ALTER TABLE viroserve.sequence_reference_alignment_pairwise OWNER TO :owner;

--
-- Name: hxb2_stats; Type: VIEW; Schema: viroserve; Owner: :owner
--

CREATE VIEW viroserve.hxb2_stats AS
 SELECT genome_region.name AS region_name,
    count(1) FILTER (WHERE (genome_region.base_range @> int4range(full_align.alignment_start, full_align.alignment_end, '[]'::text))) AS sequences_within_region,
    count(1) FILTER (WHERE (genome_region.base_range && int4range(full_align.alignment_start, full_align.alignment_end, '[]'::text))) AS sequences_intersecting_region,
    count(1) FILTER (WHERE (genome_region.base_range <@ int4range(full_align.alignment_start, full_align.alignment_end, '[]'::text))) AS sequences_covering_region
   FROM viroserve.genome_region,
    ( SELECT sequence_reference_alignment_pairwise.na_sequence_id,
            sequence_reference_alignment_pairwise.na_sequence_revision,
            min(sequence_reference_alignment_pairwise.reference_start) AS alignment_start,
            max(sequence_reference_alignment_pairwise.reference_end) AS alignment_end
           FROM viroserve.sequence_reference_alignment_pairwise
          GROUP BY sequence_reference_alignment_pairwise.na_sequence_id, sequence_reference_alignment_pairwise.na_sequence_revision) full_align
  GROUP BY genome_region.name;


ALTER TABLE viroserve.hxb2_stats OWNER TO :owner;

--
-- Name: import_job; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.import_job (
    import_job_id integer NOT NULL,
    scientist_id integer,
    time_created timestamp with time zone DEFAULT now() NOT NULL,
    time_executed timestamp with time zone,
    data_file_name text,
    data_file_key text,
    log_file_key text,
    job_queue_key integer,
    type text NOT NULL,
    note text
);


ALTER TABLE viroserve.import_job OWNER TO :owner;

--
-- Name: import_job_import_job_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.import_job_import_job_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.import_job_import_job_id_seq OWNER TO :owner;

--
-- Name: import_job_import_job_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.import_job_import_job_id_seq OWNED BY viroserve.import_job.import_job_id;


--
-- Name: infection_infection_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.infection_infection_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.infection_infection_id_seq OWNER TO :owner;

--
-- Name: infection_infection_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.infection_infection_id_seq OWNED BY viroserve.infection.infection_id;


--
-- Name: lab_result_cat_lab_result_cat_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.lab_result_cat_lab_result_cat_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.lab_result_cat_lab_result_cat_id_seq OWNER TO :owner;

--
-- Name: lab_result_cat_lab_result_cat_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.lab_result_cat_lab_result_cat_id_seq OWNED BY viroserve.lab_result_cat.lab_result_cat_id;


--
-- Name: lab_result_cat_type_group; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.lab_result_cat_type_group (
    lab_result_cat_type_id integer,
    lab_result_group_id integer
);


ALTER TABLE viroserve.lab_result_cat_type_group OWNER TO :owner;

--
-- Name: lab_result_cat_type_lab_result_cat_type_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.lab_result_cat_type_lab_result_cat_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.lab_result_cat_type_lab_result_cat_type_id_seq OWNER TO :owner;

--
-- Name: lab_result_cat_type_lab_result_cat_type_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.lab_result_cat_type_lab_result_cat_type_id_seq OWNED BY viroserve.lab_result_cat_type.lab_result_cat_type_id;


--
-- Name: lab_result_cat_value_lab_result_cat_value_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.lab_result_cat_value_lab_result_cat_value_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.lab_result_cat_value_lab_result_cat_value_id_seq OWNER TO :owner;

--
-- Name: lab_result_cat_value_lab_result_cat_value_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.lab_result_cat_value_lab_result_cat_value_id_seq OWNED BY viroserve.lab_result_cat_value.lab_result_cat_value_id;


SET default_with_oids = true;

--
-- Name: lab_result_group; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.lab_result_group (
    lab_result_group_id integer NOT NULL,
    scientist_id integer,
    name character varying(45) NOT NULL
);


ALTER TABLE viroserve.lab_result_group OWNER TO :owner;

--
-- Name: lab_result_group_lab_result_group_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.lab_result_group_lab_result_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.lab_result_group_lab_result_group_id_seq OWNER TO :owner;

--
-- Name: lab_result_group_lab_result_group_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.lab_result_group_lab_result_group_id_seq OWNED BY viroserve.lab_result_group.lab_result_group_id;


--
-- Name: lab_result_num_lab_result_num_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.lab_result_num_lab_result_num_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.lab_result_num_lab_result_num_id_seq OWNER TO :owner;

--
-- Name: lab_result_num_lab_result_num_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.lab_result_num_lab_result_num_id_seq OWNED BY viroserve.lab_result_num.lab_result_num_id;


SET default_with_oids = false;

--
-- Name: lab_result_num_type_group; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.lab_result_num_type_group (
    lab_result_num_type_id integer,
    lab_result_group_id integer
);


ALTER TABLE viroserve.lab_result_num_type_group OWNER TO :owner;

--
-- Name: lab_result_num_type_lab_result_num_type_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.lab_result_num_type_lab_result_num_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.lab_result_num_type_lab_result_num_type_id_seq OWNER TO :owner;

--
-- Name: lab_result_num_type_lab_result_num_type_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.lab_result_num_type_lab_result_num_type_id_seq OWNED BY viroserve.lab_result_num_type.lab_result_num_type_id;


--
-- Name: location; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.location (
    location_id integer NOT NULL,
    city character varying(45),
    country_abbr character(2),
    site character varying(25)
);


ALTER TABLE viroserve.location OWNER TO :owner;

--
-- Name: location_location_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.location_location_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.location_location_id_seq OWNER TO :owner;

--
-- Name: location_location_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.location_location_id_seq OWNED BY viroserve.location.location_id;


--
-- Name: medication_medication_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.medication_medication_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.medication_medication_id_seq OWNER TO :owner;

--
-- Name: medication_medication_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.medication_medication_id_seq OWNED BY viroserve.medication.medication_id;


--
-- Name: na_sequence_na_sequence_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.na_sequence_na_sequence_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.na_sequence_na_sequence_id_seq OWNER TO :owner;

--
-- Name: na_sequence_na_sequence_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.na_sequence_na_sequence_id_seq OWNED BY viroserve.na_sequence.na_sequence_id;


--
-- Name: sample_note; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.sample_note (
    note_id integer NOT NULL,
    sample_id integer,
    body text NOT NULL,
    scientist_id integer,
    time_created timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT note_non_empty_body CHECK ((length(btrim(body)) <> 0))
);


ALTER TABLE viroserve.sample_note OWNER TO :owner;

--
-- Name: note_note_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.note_note_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.note_note_id_seq OWNER TO :owner;

--
-- Name: note_note_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.note_note_id_seq OWNED BY viroserve.sample_note.note_id;


--
-- Name: notes; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.notes (
    note_id integer NOT NULL,
    vv_uid bigint NOT NULL,
    scientist_id integer,
    private boolean DEFAULT false NOT NULL,
    note text NOT NULL,
    date_added date DEFAULT now() NOT NULL
);


ALTER TABLE viroserve.notes OWNER TO :owner;

--
-- Name: notes_note_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.notes_note_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.notes_note_id_seq OWNER TO :owner;

--
-- Name: notes_note_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.notes_note_id_seq OWNED BY viroserve.notes.note_id;


--
-- Name: organism; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.organism (
    organism_id integer NOT NULL,
    name text NOT NULL
);


ALTER TABLE viroserve.organism OWNER TO :owner;

--
-- Name: organism_organism_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.organism_organism_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.organism_organism_id_seq OWNER TO :owner;

--
-- Name: organism_organism_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.organism_organism_id_seq OWNED BY viroserve.organism.organism_id;


SET default_with_oids = true;

--
-- Name: patient_cohort; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.patient_cohort (
    patient_id integer NOT NULL,
    cohort_id smallint NOT NULL
);


ALTER TABLE viroserve.patient_cohort OWNER TO :owner;

SET default_with_oids = false;

--
-- Name: patient_group; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.patient_group (
    patient_group_id integer NOT NULL,
    scientist_id integer,
    created date,
    name character varying(45)
);


ALTER TABLE viroserve.patient_group OWNER TO :owner;

--
-- Name: patient_group_patient_group_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.patient_group_patient_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.patient_group_patient_group_id_seq OWNER TO :owner;

--
-- Name: patient_group_patient_group_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.patient_group_patient_group_id_seq OWNED BY viroserve.patient_group.patient_group_id;


--
-- Name: patient_medication_patient_medication_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.patient_medication_patient_medication_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.patient_medication_patient_medication_id_seq OWNER TO :owner;

--
-- Name: patient_medication_patient_medication_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.patient_medication_patient_medication_id_seq OWNED BY viroserve.patient_medication.patient_medication_id;


--
-- Name: patient_patient_group; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.patient_patient_group (
    patient_id integer NOT NULL,
    patient_group_id integer NOT NULL,
    alias character varying(20)
);


ALTER TABLE viroserve.patient_patient_group OWNER TO :owner;

--
-- Name: patient_patient_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.patient_patient_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.patient_patient_id_seq OWNER TO :owner;

--
-- Name: patient_patient_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.patient_patient_id_seq OWNED BY viroserve.patient.patient_id;


--
-- Name: pcr_cleanup; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.pcr_cleanup (
    pcr_cleanup_id integer NOT NULL,
    pcr_product_id integer,
    protocol_id integer,
    scientist_id integer,
    date_completed date,
    date_entered date DEFAULT now() NOT NULL,
    vv_uid integer DEFAULT nextval('viroserve.vv_uid'::regclass) NOT NULL,
    notes character varying(255),
    final_conc double precision,
    final_conc_unit_id integer
);


ALTER TABLE viroserve.pcr_cleanup OWNER TO :owner;

--
-- Name: pcr_cleanup_pcr_cleanup_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.pcr_cleanup_pcr_cleanup_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.pcr_cleanup_pcr_cleanup_id_seq OWNER TO :owner;

--
-- Name: pcr_cleanup_pcr_cleanup_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.pcr_cleanup_pcr_cleanup_id_seq OWNED BY viroserve.pcr_cleanup.pcr_cleanup_id;


--
-- Name: pcr_pool; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.pcr_pool (
    pcr_pool_id integer NOT NULL,
    date_entered date DEFAULT now() NOT NULL,
    date_completed date,
    scientist_id integer NOT NULL,
    notes character varying(255),
    vv_uid integer DEFAULT nextval('viroserve.vv_uid'::regclass) NOT NULL
);


ALTER TABLE viroserve.pcr_pool OWNER TO :owner;

--
-- Name: pcr_pool_pcr_pool_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.pcr_pool_pcr_pool_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.pcr_pool_pcr_pool_id_seq OWNER TO :owner;

--
-- Name: pcr_pool_pcr_pool_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.pcr_pool_pcr_pool_id_seq OWNED BY viroserve.pcr_pool.pcr_pool_id;


--
-- Name: pcr_pool_pcr_product; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.pcr_pool_pcr_product (
    pcr_pool_id integer NOT NULL,
    pcr_product_id integer NOT NULL
);


ALTER TABLE viroserve.pcr_pool_pcr_product OWNER TO :owner;

--
-- Name: pcr_product_pcr_product_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.pcr_product_pcr_product_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.pcr_product_pcr_product_id_seq OWNER TO :owner;

--
-- Name: pcr_product_pcr_product_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.pcr_product_pcr_product_id_seq OWNED BY viroserve.pcr_product.pcr_product_id;


--
-- Name: pcr_product_primer; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.pcr_product_primer (
    pcr_product_id integer NOT NULL,
    primer_id integer NOT NULL
);


ALTER TABLE viroserve.pcr_product_primer OWNER TO :owner;

--
-- Name: pcr_template_pcr_template_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.pcr_template_pcr_template_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.pcr_template_pcr_template_id_seq OWNER TO :owner;

--
-- Name: pcr_template_pcr_template_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.pcr_template_pcr_template_id_seq OWNED BY viroserve.pcr_template.pcr_template_id;


--
-- Name: primer_primer_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.primer_primer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.primer_primer_id_seq OWNER TO :owner;

--
-- Name: primer; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.primer (
    primer_id integer DEFAULT nextval('viroserve.primer_primer_id_seq'::regclass) NOT NULL,
    name character varying(45) NOT NULL,
    sequence character varying(255) NOT NULL,
    orientation character(1),
    lab_common boolean DEFAULT false,
    some_number integer,
    notes text,
    vv_uid integer DEFAULT nextval('viroserve.vv_uid'::regclass) NOT NULL,
    date_added date DEFAULT now(),
    organism_id integer
);


ALTER TABLE viroserve.primer OWNER TO :owner;

--
-- Name: primer_position; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.primer_position (
    primer_id integer NOT NULL,
    hxb2_start integer NOT NULL,
    hxb2_end integer NOT NULL
);


ALTER TABLE viroserve.primer_position OWNER TO :owner;

--
-- Name: project; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.project (
    project_id integer NOT NULL,
    name text NOT NULL,
    orig_scientist_id integer NOT NULL,
    start_date date DEFAULT now() NOT NULL,
    completed_date date
);


ALTER TABLE viroserve.project OWNER TO :owner;

--
-- Name: project_materials; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.project_materials (
    project_id integer NOT NULL,
    date_added date DEFAULT now() NOT NULL,
    desig_scientist_id integer,
    sample_id integer NOT NULL
);


ALTER TABLE viroserve.project_materials OWNER TO :owner;

--
-- Name: sample_first_pcr_template_path; Type: VIEW; Schema: viroserve; Owner: :owner
--

CREATE VIEW viroserve.sample_first_pcr_template_path AS
 SELECT sample.sample_id,
    pcr_template.pcr_template_id,
    NULL::integer AS extraction_id,
    NULL::integer AS rt_product_id,
    NULL::integer AS bisulfite_converted_dna_id
   FROM (viroserve.sample
     JOIN viroserve.pcr_template USING (sample_id))
UNION
 SELECT sample.sample_id,
    pcr_template.pcr_template_id,
    extraction.extraction_id,
    NULL::integer AS rt_product_id,
    NULL::integer AS bisulfite_converted_dna_id
   FROM ((viroserve.sample
     JOIN viroserve.extraction USING (sample_id))
     JOIN viroserve.pcr_template USING (extraction_id))
UNION
 SELECT sample.sample_id,
    pcr_template.pcr_template_id,
    extraction.extraction_id,
    rt_product.rt_product_id,
    NULL::integer AS bisulfite_converted_dna_id
   FROM (((viroserve.sample
     JOIN viroserve.extraction USING (sample_id))
     JOIN viroserve.rt_product USING (extraction_id))
     JOIN viroserve.pcr_template USING (rt_product_id))
UNION
 SELECT sample.sample_id,
    pcr_template.pcr_template_id,
    NULL::integer AS extraction_id,
    NULL::integer AS rt_product_id,
    bcd.bisulfite_converted_dna_id
   FROM ((viroserve.sample
     JOIN viroserve.bisulfite_converted_dna bcd USING (sample_id))
     JOIN viroserve.pcr_template USING (bisulfite_converted_dna_id))
UNION
 SELECT sample.sample_id,
    pcr_template.pcr_template_id,
    extraction.extraction_id,
    NULL::integer AS rt_product_id,
    bcd.bisulfite_converted_dna_id
   FROM (((viroserve.sample
     JOIN viroserve.extraction USING (sample_id))
     JOIN viroserve.bisulfite_converted_dna bcd USING (extraction_id))
     JOIN viroserve.pcr_template USING (bisulfite_converted_dna_id))
UNION
 SELECT sample.sample_id,
    pcr_template.pcr_template_id,
    extraction.extraction_id,
    rt_product.rt_product_id,
    bcd.bisulfite_converted_dna_id
   FROM ((((viroserve.sample
     JOIN viroserve.extraction USING (sample_id))
     JOIN viroserve.rt_product USING (extraction_id))
     JOIN viroserve.bisulfite_converted_dna bcd USING (rt_product_id))
     JOIN viroserve.pcr_template USING (bisulfite_converted_dna_id));


ALTER TABLE viroserve.sample_first_pcr_template_path OWNER TO :owner;

--
-- Name: project_material_scientist_progress; Type: MATERIALIZED VIEW; Schema: viroserve; Owner: :owner
--

CREATE MATERIALIZED VIEW viroserve.project_material_scientist_progress AS
 WITH extraction_status AS (
         SELECT DISTINCT extraction.sample_id,
            extraction.scientist_id,
            true AS has_extractions
           FROM viroserve.extraction
        ), rt_status AS (
         SELECT DISTINCT extraction.sample_id,
            rt.scientist_id,
            true AS has_rt_products
           FROM (viroserve.rt_product rt
             JOIN viroserve.extraction USING (extraction_id))
        ), pcr_status AS (
         SELECT DISTINCT sample_first_pcr_template_path.sample_id,
            pcr_product.scientist_id,
            true AS has_pcr_products
           FROM (viroserve.sample_first_pcr_template_path
             JOIN viroserve.pcr_product USING (pcr_template_id))
        ), sequencing_status AS (
         SELECT DISTINCT na_sequence.sample_id,
            na_sequence.scientist_id,
            true AS has_sequences
           FROM (viroserve.na_sequence
             JOIN viroserve.na_sequence_latest_revision USING (na_sequence_id, na_sequence_revision))
        )
 SELECT pm.project_id,
    pm.sample_id,
    pm.desig_scientist_id AS scientist_id,
    COALESCE(e.has_extractions, false) AS has_extractions,
    COALESCE(r.has_rt_products, false) AS has_rt_products,
    COALESCE(pcr.has_pcr_products, false) AS has_pcr_products,
    COALESCE(s.has_sequences, false) AS has_sequences
   FROM ((((viroserve.project_materials pm
     LEFT JOIN extraction_status e ON (((e.sample_id = pm.sample_id) AND (e.scientist_id = pm.desig_scientist_id))))
     LEFT JOIN rt_status r ON (((r.sample_id = pm.sample_id) AND (r.scientist_id = pm.desig_scientist_id))))
     LEFT JOIN pcr_status pcr ON (((pcr.sample_id = pm.sample_id) AND (pcr.scientist_id = pm.desig_scientist_id))))
     LEFT JOIN sequencing_status s ON (((s.sample_id = pm.sample_id) AND (s.scientist_id = pm.desig_scientist_id))))
  WHERE (pm.desig_scientist_id IS NOT NULL)
  WITH NO DATA;


ALTER TABLE viroserve.project_material_scientist_progress OWNER TO :owner;

--
-- Name: project_project_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.project_project_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.project_project_id_seq OWNER TO :owner;

--
-- Name: project_project_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.project_project_id_seq OWNED BY viroserve.project.project_id;


--
-- Name: protocol; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.protocol (
    protocol_id integer NOT NULL,
    name character varying(45),
    last_revision date,
    source character varying(255),
    protocol_type_id integer
);


ALTER TABLE viroserve.protocol OWNER TO :owner;

--
-- Name: protocol_protocol_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.protocol_protocol_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.protocol_protocol_id_seq OWNER TO :owner;

--
-- Name: protocol_protocol_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.protocol_protocol_id_seq OWNED BY viroserve.protocol.protocol_id;


--
-- Name: protocol_type; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.protocol_type (
    protocol_type_id integer NOT NULL,
    name character varying(45) NOT NULL
);


ALTER TABLE viroserve.protocol_type OWNER TO :owner;

--
-- Name: protocol_type_protocol_type_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.protocol_type_protocol_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.protocol_type_protocol_type_id_seq OWNER TO :owner;

--
-- Name: protocol_type_protocol_type_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.protocol_type_protocol_type_id_seq OWNED BY viroserve.protocol_type.protocol_type_id;


--
-- Name: restriction_enzyme_restriction_enzyme_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.restriction_enzyme_restriction_enzyme_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.restriction_enzyme_restriction_enzyme_id_seq OWNER TO :owner;

--
-- Name: rt_primer; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.rt_primer (
    rt_product_id integer NOT NULL,
    primer_id integer NOT NULL
);


ALTER TABLE viroserve.rt_primer OWNER TO :owner;

--
-- Name: rt_product_rt_product_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.rt_product_rt_product_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.rt_product_rt_product_id_seq OWNER TO :owner;

--
-- Name: rt_product_rt_product_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.rt_product_rt_product_id_seq OWNED BY viroserve.rt_product.rt_product_id;


--
-- Name: sample_patient_date; Type: VIEW; Schema: viroserve; Owner: :owner
--

CREATE VIEW viroserve.sample_patient_date AS
 WITH RECURSIVE sample_patient_recurrence(sample_id, patient_id) AS (
         SELECT s.sample_id,
            v.patient_id,
            COALESCE(s.date_collected, v.visit_date) AS sample_date
           FROM ((viroserve.sample s
             JOIN viroserve.visit v USING (visit_id))
             JOIN viroserve.patient USING (patient_id))
        UNION ALL
         SELECT s.sample_id,
            p.patient_id,
            COALESCE(s.date_collected, d.date_completed) AS sample_date
           FROM ((delta.derivation d
             JOIN sample_patient_recurrence p ON ((d.input_sample_id = p.sample_id)))
             JOIN viroserve.sample s ON ((s.derivation_id = d.derivation_id)))
        )
 SELECT sample_patient_recurrence.sample_id,
    sample_patient_recurrence.patient_id,
    sample_patient_recurrence.sample_date
   FROM sample_patient_recurrence;


ALTER TABLE viroserve.sample_patient_date OWNER TO :owner;

--
-- Name: sample_sample_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.sample_sample_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.sample_sample_id_seq OWNER TO :owner;

--
-- Name: sample_sample_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.sample_sample_id_seq OWNED BY viroserve.sample.sample_id;


SET default_with_oids = true;

--
-- Name: sample_type; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.sample_type (
    sample_type_id integer NOT NULL,
    name character varying(45)
);


ALTER TABLE viroserve.sample_type OWNER TO :owner;

--
-- Name: scientist; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.scientist (
    scientist_id integer NOT NULL,
    name character varying(45),
    start_date date,
    end_date date,
    phone character(10),
    username character varying(120),
    email character varying(120),
    role viroserve.scientist_role
);


ALTER TABLE viroserve.scientist OWNER TO :owner;

--
-- Name: sample_search; Type: VIEW; Schema: viroserve; Owner: :owner
--

CREATE VIEW viroserve.sample_search AS
 SELECT sample.sample_id,
    sample.name,
    (((cc.name)::text || ' '::text) || (a.external_patient_id)::text) AS patient_name,
    sample.tissue_type_id,
    sample.sample_type_id,
    st.name AS sample_type,
    p.sample_date AS visit_date,
    p.patient_id,
    c.cohort_id,
    sample.derivation_id,
    vl.viral_load,
    scientist.scientist_id,
    scientist.name AS scientist_name
   FROM ((((((((((viroserve.sample
     LEFT JOIN viroserve.sample_type st USING (sample_type_id))
     LEFT JOIN delta.derivation USING (derivation_id))
     LEFT JOIN viroserve.visit USING (visit_id))
     LEFT JOIN viroserve.sample_patient_date p USING (sample_id))
     LEFT JOIN viroserve.patient_cohort c ON ((p.patient_id = c.patient_id)))
     LEFT JOIN viroserve.viral_load vl ON (((vl.visit_date = visit.visit_date) AND (vl.patient_id = p.patient_id))))
     LEFT JOIN viroserve.patient_alias a ON ((((p.patient_id = a.patient_id) AND (c.cohort_id = a.cohort_id)) AND ((a.type)::text = 'primary'::text))))
     LEFT JOIN viroserve.cohort cc ON ((c.cohort_id = cc.cohort_id)))
     LEFT JOIN viroserve.project_materials m USING (sample_id))
     LEFT JOIN viroserve.scientist ON ((m.desig_scientist_id = scientist.scientist_id)));


ALTER TABLE viroserve.sample_search OWNER TO :owner;

--
-- Name: sample_type_sample_type_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.sample_type_sample_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.sample_type_sample_type_id_seq OWNER TO :owner;

--
-- Name: sample_type_sample_type_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.sample_type_sample_type_id_seq OWNED BY viroserve.sample_type.sample_type_id;


SET default_with_oids = false;

--
-- Name: scientist_group; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.scientist_group (
    scientist_group_id integer NOT NULL,
    vv_uid integer DEFAULT nextval('viroserve.vv_uid'::regclass),
    name character varying(255) NOT NULL,
    creating_scientist_id integer NOT NULL,
    display boolean NOT NULL,
    date_added date DEFAULT now() NOT NULL
);


ALTER TABLE viroserve.scientist_group OWNER TO :owner;

--
-- Name: scientist_group_scientist_group_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.scientist_group_scientist_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.scientist_group_scientist_group_id_seq OWNER TO :owner;

--
-- Name: scientist_group_scientist_group_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.scientist_group_scientist_group_id_seq OWNED BY viroserve.scientist_group.scientist_group_id;


--
-- Name: scientist_scientist_group; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.scientist_scientist_group (
    scientist_group_id integer NOT NULL,
    scientist_id integer NOT NULL,
    date_added date DEFAULT now() NOT NULL,
    creating_scientist_id integer
);


ALTER TABLE viroserve.scientist_scientist_group OWNER TO :owner;

--
-- Name: scientist_scientist_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.scientist_scientist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.scientist_scientist_id_seq OWNER TO :owner;

--
-- Name: scientist_scientist_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.scientist_scientist_id_seq OWNED BY viroserve.scientist.scientist_id;


--
-- Name: sequence_genome_region; Type: VIEW; Schema: viroserve; Owner: :owner
--

CREATE VIEW viroserve.sequence_genome_region AS
 WITH sequence AS (
         SELECT sequence_reference_alignment_pairwise.na_sequence_id,
            sequence_reference_alignment_pairwise.na_sequence_revision,
            min(sequence_reference_alignment_pairwise.reference_start) AS reference_start,
            max(sequence_reference_alignment_pairwise.reference_end) AS reference_end,
            int4range(min(sequence_reference_alignment_pairwise.reference_start), max(sequence_reference_alignment_pairwise.reference_end), '[]'::text) AS reference_range
           FROM viroserve.sequence_reference_alignment_pairwise
          GROUP BY sequence_reference_alignment_pairwise.na_sequence_id, sequence_reference_alignment_pairwise.na_sequence_revision
        ), large_amplicon(name, base_range) AS (
         VALUES ('NFLG'::text,int4range(790, 9417, '[]'::text)), ('LH'::text,int4range(790, 5817, '[]'::text)), ('RH'::text,int4range(5817, 9417, '(]'::text))
        )
 SELECT sequence.na_sequence_id,
    sequence.na_sequence_revision,
    sequence.reference_start,
    sequence.reference_end,
    region.name AS region_name
   FROM (sequence
     JOIN viroserve.genome_region region ON ((region.base_range && sequence.reference_range)))
UNION
 SELECT sequence.na_sequence_id,
    sequence.na_sequence_revision,
    sequence.reference_start,
    sequence.reference_end,
    region.name AS region_name
   FROM (sequence
     JOIN large_amplicon region ON ((sequence.reference_range @> region.base_range)));


ALTER TABLE viroserve.sequence_genome_region OWNER TO :owner;

--
-- Name: sequence_type; Type: TABLE; Schema: viroserve; Owner: :owner
--

CREATE TABLE viroserve.sequence_type (
    sequence_type_id integer NOT NULL,
    name text NOT NULL
);


ALTER TABLE viroserve.sequence_type OWNER TO :owner;

--
-- Name: sequence_search; Type: MATERIALIZED VIEW; Schema: viroserve; Owner: :owner
--

CREATE MATERIALIZED VIEW viroserve.sequence_search AS
 SELECT na_sequence.na_sequence_id,
    na_sequence_revision,
    na_sequence.name,
    na_sequence.na_type,
    na_sequence.entered_date,
    tissue_type.name AS tissue_type,
    sample.tissue_type_id,
    scientist.name AS scientist,
    scientist.scientist_id,
    pcr_product.name AS pcr_name,
    sample.name AS sample_name,
    sample.sample_id,
    viroserve.patient_name(sample_patient_date.patient_id) AS patient,
    sample_patient_date.patient_id,
    sequence_type.name AS type,
    array_agg(DISTINCT cohort.name) AS cohorts,
    array_agg(DISTINCT sequence_genome_region.region_name) AS regions
   FROM ((((((((((viroserve.na_sequence
     JOIN viroserve.na_sequence_latest_revision USING (na_sequence_id, na_sequence_revision))
     LEFT JOIN viroserve.sample USING (sample_id))
     LEFT JOIN viroserve.tissue_type USING (tissue_type_id))
     LEFT JOIN viroserve.scientist USING (scientist_id))
     LEFT JOIN viroserve.sample_patient_date USING (sample_id))
     LEFT JOIN viroserve.patient_cohort USING (patient_id))
     LEFT JOIN viroserve.cohort USING (cohort_id))
     LEFT JOIN viroserve.pcr_product pcr_product(pcr_product_id, scientist_id_1, name, date_entered, purified, notes, date_completed, round, successful, replicate, enzyme_id, hot_start, protocol_id, vv_uid, genome_portion, pcr_template_id, pcr_pool_id, reamp_round, endpoint_dilution) USING (pcr_product_id))
     LEFT JOIN viroserve.sequence_type USING (sequence_type_id))
     LEFT JOIN viroserve.sequence_genome_region USING (na_sequence_id, na_sequence_revision))
  GROUP BY na_sequence.na_sequence_id, na_sequence_revision, na_sequence.name, na_sequence.na_type, na_sequence.entered_date, tissue_type.name, sample.tissue_type_id, scientist.name, scientist.scientist_id, pcr_product.name, sample.name, sample.sample_id, viroserve.patient_name(sample_patient_date.patient_id), sample_patient_date.patient_id, sequence_type.name
  WITH NO DATA;


ALTER TABLE viroserve.sequence_search OWNER TO :owner;

--
-- Name: sequence_type_sequence_type_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.sequence_type_sequence_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.sequence_type_sequence_type_id_seq OWNER TO :owner;

--
-- Name: sequence_type_sequence_type_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.sequence_type_sequence_type_id_seq OWNED BY viroserve.sequence_type.sequence_type_id;


--
-- Name: tissue_type_tissue_type_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.tissue_type_tissue_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.tissue_type_tissue_type_id_seq OWNER TO :owner;

--
-- Name: tissue_type_tissue_type_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.tissue_type_tissue_type_id_seq OWNED BY viroserve.tissue_type.tissue_type_id;


--
-- Name: unit_unit_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.unit_unit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.unit_unit_id_seq OWNER TO :owner;

--
-- Name: unit_unit_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.unit_unit_id_seq OWNED BY viroserve.unit.unit_id;


--
-- Name: visit_visit_id_seq; Type: SEQUENCE; Schema: viroserve; Owner: :owner
--

CREATE SEQUENCE viroserve.visit_visit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE viroserve.visit_visit_id_seq OWNER TO :owner;

--
-- Name: visit_visit_id_seq; Type: SEQUENCE OWNED BY; Schema: viroserve; Owner: :owner
--

ALTER SEQUENCE viroserve.visit_visit_id_seq OWNED BY viroserve.visit.visit_id;


--
-- Name: derivation derivation_id; Type: DEFAULT; Schema: delta; Owner: :owner
--

ALTER TABLE ONLY delta.derivation ALTER COLUMN derivation_id SET DEFAULT nextval('delta.derivation_derivation_id_seq'::regclass);


--
-- Name: protocol protocol_id; Type: DEFAULT; Schema: delta; Owner: :owner
--

ALTER TABLE ONLY delta.protocol ALTER COLUMN protocol_id SET DEFAULT nextval('delta.protocol_protocol_id_seq'::regclass);


--
-- Name: box box_id; Type: DEFAULT; Schema: freezer; Owner: :owner
--

ALTER TABLE ONLY freezer.box ALTER COLUMN box_id SET DEFAULT nextval('freezer.box_box_id_seq'::regclass);


--
-- Name: box_pos box_pos_id; Type: DEFAULT; Schema: freezer; Owner: :owner
--

ALTER TABLE ONLY freezer.box_pos ALTER COLUMN box_pos_id SET DEFAULT nextval('freezer.box_pos_box_pos_id_seq'::regclass);


--
-- Name: freezer freezer_id; Type: DEFAULT; Schema: freezer; Owner: :owner
--

ALTER TABLE ONLY freezer.freezer ALTER COLUMN freezer_id SET DEFAULT nextval('freezer.freezer_freezer_id_seq'::regclass);


--
-- Name: rack rack_id; Type: DEFAULT; Schema: freezer; Owner: :owner
--

ALTER TABLE ONLY freezer.rack ALTER COLUMN rack_id SET DEFAULT nextval('freezer.rack_rack_id_seq'::regclass);


--
-- Name: additive additive_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.additive ALTER COLUMN additive_id SET DEFAULT nextval('viroserve.additive_additive_id_seq'::regclass);


--
-- Name: alignment alignment_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.alignment ALTER COLUMN alignment_id SET DEFAULT nextval('viroserve.alignment_alignment_id_seq'::regclass);


--
-- Name: alignment_method alignment_method_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.alignment_method ALTER COLUMN alignment_method_id SET DEFAULT nextval('viroserve.alignment_method_alignment_method_id_seq'::regclass);


--
-- Name: aliquot aliquot_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.aliquot ALTER COLUMN aliquot_id SET DEFAULT nextval('viroserve.aliquot_aliquot_id_seq'::regclass);


--
-- Name: arv_class arv_class_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.arv_class ALTER COLUMN arv_class_id SET DEFAULT nextval('viroserve.arv_class_arv_class_id_seq'::regclass);


--
-- Name: bisulfite_converted_dna bisulfite_converted_dna_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.bisulfite_converted_dna ALTER COLUMN bisulfite_converted_dna_id SET DEFAULT nextval('viroserve.bisulfite_converted_dna_bisulfite_converted_dna_id_seq'::regclass);


--
-- Name: chromat chromat_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.chromat ALTER COLUMN chromat_id SET DEFAULT nextval('viroserve.chromat_chromat_id_seq'::regclass);


--
-- Name: chromat_type chromat_type_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.chromat_type ALTER COLUMN chromat_type_id SET DEFAULT nextval('viroserve.chromat_type_chromat_type_id_seq'::regclass);


--
-- Name: clone clone_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.clone ALTER COLUMN clone_id SET DEFAULT nextval('viroserve.clone_clone_id_seq'::regclass);


--
-- Name: copy_number copy_number_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.copy_number ALTER COLUMN copy_number_id SET DEFAULT nextval('viroserve.copy_number_copy_number_id_seq'::regclass);


--
-- Name: enzyme enzyme_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.enzyme ALTER COLUMN enzyme_id SET DEFAULT nextval('viroserve.enzyme_enzyme_id_seq'::regclass);


--
-- Name: extract_type extract_type_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.extract_type ALTER COLUMN extract_type_id SET DEFAULT nextval('viroserve.extract_type_extract_type_id_seq'::regclass);


--
-- Name: extraction extraction_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.extraction ALTER COLUMN extraction_id SET DEFAULT nextval('viroserve.extraction_extraction_id_seq'::regclass);


--
-- Name: gel gel_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.gel ALTER COLUMN gel_id SET DEFAULT nextval('viroserve.gel_gel_id_seq'::regclass);


--
-- Name: gel_lane gel_lane_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.gel_lane ALTER COLUMN gel_lane_id SET DEFAULT nextval('viroserve.gel_lane_gel_lane_id_seq'::regclass);


--
-- Name: hla_genotype hla_genotype_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.hla_genotype ALTER COLUMN hla_genotype_id SET DEFAULT nextval('viroserve.hla_genotype_hla_genotype_id_seq'::regclass);


--
-- Name: import_job import_job_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.import_job ALTER COLUMN import_job_id SET DEFAULT nextval('viroserve.import_job_import_job_id_seq'::regclass);


--
-- Name: infection infection_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.infection ALTER COLUMN infection_id SET DEFAULT nextval('viroserve.infection_infection_id_seq'::regclass);


--
-- Name: lab_result_cat lab_result_cat_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.lab_result_cat ALTER COLUMN lab_result_cat_id SET DEFAULT nextval('viroserve.lab_result_cat_lab_result_cat_id_seq'::regclass);


--
-- Name: lab_result_cat_type lab_result_cat_type_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.lab_result_cat_type ALTER COLUMN lab_result_cat_type_id SET DEFAULT nextval('viroserve.lab_result_cat_type_lab_result_cat_type_id_seq'::regclass);


--
-- Name: lab_result_cat_value lab_result_cat_value_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.lab_result_cat_value ALTER COLUMN lab_result_cat_value_id SET DEFAULT nextval('viroserve.lab_result_cat_value_lab_result_cat_value_id_seq'::regclass);


--
-- Name: lab_result_group lab_result_group_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.lab_result_group ALTER COLUMN lab_result_group_id SET DEFAULT nextval('viroserve.lab_result_group_lab_result_group_id_seq'::regclass);


--
-- Name: lab_result_num lab_result_num_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.lab_result_num ALTER COLUMN lab_result_num_id SET DEFAULT nextval('viroserve.lab_result_num_lab_result_num_id_seq'::regclass);


--
-- Name: lab_result_num_type lab_result_num_type_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.lab_result_num_type ALTER COLUMN lab_result_num_type_id SET DEFAULT nextval('viroserve.lab_result_num_type_lab_result_num_type_id_seq'::regclass);


--
-- Name: location location_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.location ALTER COLUMN location_id SET DEFAULT nextval('viroserve.location_location_id_seq'::regclass);


--
-- Name: medication medication_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.medication ALTER COLUMN medication_id SET DEFAULT nextval('viroserve.medication_medication_id_seq'::regclass);


--
-- Name: na_sequence na_sequence_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.na_sequence ALTER COLUMN na_sequence_id SET DEFAULT nextval('viroserve.na_sequence_na_sequence_id_seq'::regclass);


--
-- Name: notes note_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.notes ALTER COLUMN note_id SET DEFAULT nextval('viroserve.notes_note_id_seq'::regclass);


--
-- Name: organism organism_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.organism ALTER COLUMN organism_id SET DEFAULT nextval('viroserve.organism_organism_id_seq'::regclass);


--
-- Name: patient patient_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.patient ALTER COLUMN patient_id SET DEFAULT nextval('viroserve.patient_patient_id_seq'::regclass);


--
-- Name: patient_group patient_group_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.patient_group ALTER COLUMN patient_group_id SET DEFAULT nextval('viroserve.patient_group_patient_group_id_seq'::regclass);


--
-- Name: patient_medication patient_medication_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.patient_medication ALTER COLUMN patient_medication_id SET DEFAULT nextval('viroserve.patient_medication_patient_medication_id_seq'::regclass);


--
-- Name: pcr_cleanup pcr_cleanup_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.pcr_cleanup ALTER COLUMN pcr_cleanup_id SET DEFAULT nextval('viroserve.pcr_cleanup_pcr_cleanup_id_seq'::regclass);


--
-- Name: pcr_pool pcr_pool_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.pcr_pool ALTER COLUMN pcr_pool_id SET DEFAULT nextval('viroserve.pcr_pool_pcr_pool_id_seq'::regclass);


--
-- Name: pcr_product pcr_product_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.pcr_product ALTER COLUMN pcr_product_id SET DEFAULT nextval('viroserve.pcr_product_pcr_product_id_seq'::regclass);


--
-- Name: pcr_template pcr_template_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.pcr_template ALTER COLUMN pcr_template_id SET DEFAULT nextval('viroserve.pcr_template_pcr_template_id_seq'::regclass);


--
-- Name: project project_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.project ALTER COLUMN project_id SET DEFAULT nextval('viroserve.project_project_id_seq'::regclass);


--
-- Name: protocol protocol_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.protocol ALTER COLUMN protocol_id SET DEFAULT nextval('viroserve.protocol_protocol_id_seq'::regclass);


--
-- Name: protocol_type protocol_type_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.protocol_type ALTER COLUMN protocol_type_id SET DEFAULT nextval('viroserve.protocol_type_protocol_type_id_seq'::regclass);


--
-- Name: rt_product rt_product_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.rt_product ALTER COLUMN rt_product_id SET DEFAULT nextval('viroserve.rt_product_rt_product_id_seq'::regclass);


--
-- Name: sample sample_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.sample ALTER COLUMN sample_id SET DEFAULT nextval('viroserve.sample_sample_id_seq'::regclass);


--
-- Name: sample_note note_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.sample_note ALTER COLUMN note_id SET DEFAULT nextval('viroserve.note_note_id_seq'::regclass);


--
-- Name: sample_type sample_type_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.sample_type ALTER COLUMN sample_type_id SET DEFAULT nextval('viroserve.sample_type_sample_type_id_seq'::regclass);


--
-- Name: scientist scientist_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.scientist ALTER COLUMN scientist_id SET DEFAULT nextval('viroserve.scientist_scientist_id_seq'::regclass);


--
-- Name: scientist_group scientist_group_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.scientist_group ALTER COLUMN scientist_group_id SET DEFAULT nextval('viroserve.scientist_group_scientist_group_id_seq'::regclass);


--
-- Name: sequence_type sequence_type_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.sequence_type ALTER COLUMN sequence_type_id SET DEFAULT nextval('viroserve.sequence_type_sequence_type_id_seq'::regclass);


--
-- Name: tissue_type tissue_type_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.tissue_type ALTER COLUMN tissue_type_id SET DEFAULT nextval('viroserve.tissue_type_tissue_type_id_seq'::regclass);


--
-- Name: unit unit_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.unit ALTER COLUMN unit_id SET DEFAULT nextval('viroserve.unit_unit_id_seq'::regclass);


--
-- Name: visit visit_id; Type: DEFAULT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.visit ALTER COLUMN visit_id SET DEFAULT nextval('viroserve.visit_visit_id_seq'::regclass);


--
-- Name: tissue_type tissue_type_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.tissue_type
    ADD CONSTRAINT tissue_type_pkey PRIMARY KEY (tissue_type_id);


--
-- Name: distinct_sample_search; Type: MATERIALIZED VIEW; Schema: viroserve; Owner: :owner
--

CREATE MATERIALIZED VIEW viroserve.distinct_sample_search AS
 SELECT sample.sample_id,
    sample.name,
    tissue_type.name AS tissue_type,
    tissue_type.tissue_type_id,
        CASE sample_type.name
            WHEN 'cells'::text THEN 'DNA'::text
            WHEN 'RNA'::text THEN 'RNA'::text
            ELSE NULL::text
        END AS na_type,
    sample_patient_date.sample_date,
    protocol.name AS derivation_protocol,
    protocol.protocol_id AS derivation_protocol_id,
    sample.derivation_id,
    viroserve.patient_name(sample_patient_date.patient_id) AS patient,
    sample_patient_date.patient_id,
    max(vl.viral_load) AS viral_load,
    min(vl.limit_of_quantification) AS viral_load_limit_of_quantification,
        CASE
            WHEN (count(DISTINCT aliquot.aliquot_id) = 0) THEN NULL::bigint
            ELSE count(DISTINCT aliquot.aliquot_id) FILTER (WHERE (((aliquot.possessing_scientist_id IS NULL) AND (aliquot.orphaned IS NULL)) AND ((aliquot.vol > (0)::numeric) OR (aliquot.vol IS NULL))))
        END AS available_aliquots,
    bool_or((sequence_search.na_sequence_id IS NOT NULL)) AS has_sequences,
    array_agg(DISTINCT cohort.name) AS cohorts,
    (json_agg(DISTINCT (json_build_object('project', project.name, 'project_id', project.project_id, 'scientist', scientist.name, 'scientist_id', scientist.scientist_id))::jsonb))::jsonb AS assignments
   FROM (((((((((((((((viroserve.sample
     LEFT JOIN viroserve.tissue_type USING (tissue_type_id))
     LEFT JOIN viroserve.sample_type USING (sample_type_id))
     LEFT JOIN delta.derivation USING (derivation_id))
     LEFT JOIN delta.protocol USING (protocol_id))
     LEFT JOIN viroserve.visit USING (visit_id))
     LEFT JOIN viroserve.sample_patient_date USING (sample_id))
     LEFT JOIN viroserve.patient_cohort ON ((patient_cohort.patient_id = sample_patient_date.patient_id)))
     LEFT JOIN viroserve.cohort USING (cohort_id))
     LEFT JOIN viroserve.project_materials USING (sample_id))
     LEFT JOIN viroserve.project USING (project_id))
     LEFT JOIN viroserve.scientist ON ((scientist.scientist_id = project_materials.desig_scientist_id)))
     LEFT JOIN viroserve.aliquot USING (sample_id))
     LEFT JOIN viroserve.unit USING (unit_id))
     LEFT JOIN viroserve.sequence_search USING (sample_id))
     LEFT JOIN viroserve.viral_load vl ON (((vl.patient_id = sample_patient_date.patient_id) AND (vl.visit_date = visit.visit_date))))
  GROUP BY sample.sample_id, sample.name, sample_patient_date.sample_date, sample_type.name, sample_patient_date.patient_id, sequence_search.tissue_type, tissue_type.tissue_type_id, protocol.name, protocol.protocol_id, sample.derivation_id
  WITH NO DATA;


ALTER TABLE viroserve.distinct_sample_search OWNER TO :owner;

--
-- Name: derivation derivation_pkey; Type: CONSTRAINT; Schema: delta; Owner: :owner
--

ALTER TABLE ONLY delta.derivation
    ADD CONSTRAINT derivation_pkey PRIMARY KEY (derivation_id);


--
-- Name: protocol protocol_name_key; Type: CONSTRAINT; Schema: delta; Owner: :owner
--

ALTER TABLE ONLY delta.protocol
    ADD CONSTRAINT protocol_name_key UNIQUE (name);


--
-- Name: protocol_output protocol_output_protocol_id_tissue_type_id_key; Type: CONSTRAINT; Schema: delta; Owner: :owner
--

ALTER TABLE ONLY delta.protocol_output
    ADD CONSTRAINT protocol_output_protocol_id_tissue_type_id_key UNIQUE (protocol_id, tissue_type_id);


--
-- Name: protocol protocol_pkey; Type: CONSTRAINT; Schema: delta; Owner: :owner
--

ALTER TABLE ONLY delta.protocol
    ADD CONSTRAINT protocol_pkey PRIMARY KEY (protocol_id);


--
-- Name: blcl blcl_pkey; Type: CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.blcl
    ADD CONSTRAINT blcl_pkey PRIMARY KEY (blcl_id);


--
-- Name: epitope_mutant epitope_mutant_pkey; Type: CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.epitope_mutant
    ADD CONSTRAINT epitope_mutant_pkey PRIMARY KEY (epit_id, mutant_id, patient_id);


--
-- Name: epitope epitope_pkey; Type: CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.epitope
    ADD CONSTRAINT epitope_pkey PRIMARY KEY (epit_id);


--
-- Name: epitope_source epitope_source_pkey; Type: CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.epitope_source
    ADD CONSTRAINT epitope_source_pkey PRIMARY KEY (source_id);


--
-- Name: titration epitope_titration_unique; Type: CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.titration
    ADD CONSTRAINT epitope_titration_unique UNIQUE (pept_id, exp_id, sample_id, conc_id);


--
-- Name: experiment experiment_pkey; Type: CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.experiment
    ADD CONSTRAINT experiment_pkey PRIMARY KEY (exp_id);


--
-- Name: gene gene_gene_name_key; Type: CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.gene
    ADD CONSTRAINT gene_gene_name_key UNIQUE (gene_name);


--
-- Name: gene gene_pkey; Type: CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.gene
    ADD CONSTRAINT gene_pkey PRIMARY KEY (gene_id);


--
-- Name: hla_pept hla_pept_pkey; Type: CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.hla_pept
    ADD CONSTRAINT hla_pept_pkey PRIMARY KEY (hla_id, pept_id);


--
-- Name: hla hla_pkey; Type: CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.hla
    ADD CONSTRAINT hla_pkey PRIMARY KEY (hla_id);


--
-- Name: hla_response hla_response_pkey; Type: CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.hla_response
    ADD CONSTRAINT hla_response_pkey PRIMARY KEY (measure_id);


--
-- Name: hla_response hla_response_unique; Type: CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.hla_response
    ADD CONSTRAINT hla_response_unique UNIQUE (pept_id, exp_id, sample_id, blcl_id);


--
-- Name: measurement measurement_pkey; Type: CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.measurement
    ADD CONSTRAINT measurement_pkey PRIMARY KEY (measure_id);


--
-- Name: mutant mutant_pkey; Type: CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.mutant
    ADD CONSTRAINT mutant_pkey PRIMARY KEY (mutant_id);


--
-- Name: origin_peptide origin_peptide_pkey; Type: CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.origin_peptide
    ADD CONSTRAINT origin_peptide_pkey PRIMARY KEY (origin_id, pept_id);


--
-- Name: origin origin_pkey; Type: CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.origin
    ADD CONSTRAINT origin_pkey PRIMARY KEY (origin_id);


--
-- Name: pept_response pept_response_pkey; Type: CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.pept_response
    ADD CONSTRAINT pept_response_pkey PRIMARY KEY (measure_id);


--
-- Name: pept_response pept_response_unique; Type: CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.pept_response
    ADD CONSTRAINT pept_response_unique UNIQUE (pept_id, exp_id, sample_id);


--
-- Name: peptide peptide_name_key; Type: CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.peptide
    ADD CONSTRAINT peptide_name_key UNIQUE (name);


--
-- Name: peptide peptide_pkey; Type: CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.peptide
    ADD CONSTRAINT peptide_pkey PRIMARY KEY (pept_id);


--
-- Name: peptide peptide_seq_key; Type: CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.peptide
    ADD CONSTRAINT peptide_seq_key UNIQUE (sequence);


--
-- Name: pool_pept pool_pept_pkey; Type: CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.pool_pept
    ADD CONSTRAINT pool_pept_pkey PRIMARY KEY (pool_id, pept_id);


--
-- Name: pool pool_pkey; Type: CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.pool
    ADD CONSTRAINT pool_pkey PRIMARY KEY (pool_id);


--
-- Name: pool_response pool_response_pkey; Type: CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.pool_response
    ADD CONSTRAINT pool_response_pkey PRIMARY KEY (measure_id);


--
-- Name: pool_response pool_response_unique; Type: CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.pool_response
    ADD CONSTRAINT pool_response_unique UNIQUE (pool_id, exp_id, sample_id, matrix_index);


--
-- Name: reading reading_pkey; Type: CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.reading
    ADD CONSTRAINT reading_pkey PRIMARY KEY (reading_id);


--
-- Name: titration_conc titration_conc_pkey; Type: CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.titration_conc
    ADD CONSTRAINT titration_conc_pkey PRIMARY KEY (conc_id);


--
-- Name: titration titration_pkey; Type: CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.titration
    ADD CONSTRAINT titration_pkey PRIMARY KEY (measure_id);


--
-- Name: box_pos box_pos_pk; Type: CONSTRAINT; Schema: freezer; Owner: :owner
--

ALTER TABLE ONLY freezer.box_pos
    ADD CONSTRAINT box_pos_pk PRIMARY KEY (box_pos_id);


--
-- Name: box freezer_box_pk; Type: CONSTRAINT; Schema: freezer; Owner: :owner
--

ALTER TABLE ONLY freezer.box
    ADD CONSTRAINT freezer_box_pk PRIMARY KEY (box_id);


--
-- Name: rack freezer_rack_name_unique; Type: CONSTRAINT; Schema: freezer; Owner: :owner
--

ALTER TABLE ONLY freezer.rack
    ADD CONSTRAINT freezer_rack_name_unique UNIQUE (freezer_id, name);


--
-- Name: rack freezer_rack_pk; Type: CONSTRAINT; Schema: freezer; Owner: :owner
--

ALTER TABLE ONLY freezer.rack
    ADD CONSTRAINT freezer_rack_pk PRIMARY KEY (rack_id);


--
-- Name: freezer frezer_name_unique; Type: CONSTRAINT; Schema: freezer; Owner: :owner
--

ALTER TABLE ONLY freezer.freezer
    ADD CONSTRAINT frezer_name_unique UNIQUE (name);


--
-- Name: freezer frezer_pk; Type: CONSTRAINT; Schema: freezer; Owner: :owner
--

ALTER TABLE ONLY freezer.freezer
    ADD CONSTRAINT frezer_pk PRIMARY KEY (freezer_id);


--
-- Name: changes changes_pkey; Type: CONSTRAINT; Schema: sqitch; Owner: :owner
--

ALTER TABLE ONLY sqitch.changes
    ADD CONSTRAINT changes_pkey PRIMARY KEY (change_id);


--
-- Name: dependencies dependencies_pkey; Type: CONSTRAINT; Schema: sqitch; Owner: :owner
--

ALTER TABLE ONLY sqitch.dependencies
    ADD CONSTRAINT dependencies_pkey PRIMARY KEY (change_id, dependency);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: sqitch; Owner: :owner
--

ALTER TABLE ONLY sqitch.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (change_id, committed_at);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: sqitch; Owner: :owner
--

ALTER TABLE ONLY sqitch.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (project);


--
-- Name: projects projects_uri_key; Type: CONSTRAINT; Schema: sqitch; Owner: :owner
--

ALTER TABLE ONLY sqitch.projects
    ADD CONSTRAINT projects_uri_key UNIQUE (uri);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: sqitch; Owner: :owner
--

ALTER TABLE ONLY sqitch.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (tag_id);


--
-- Name: tags tags_project_key; Type: CONSTRAINT; Schema: sqitch; Owner: :owner
--

ALTER TABLE ONLY sqitch.tags
    ADD CONSTRAINT tags_project_key UNIQUE (project, tag);


--
-- Name: additive additive_name_unique; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.additive
    ADD CONSTRAINT additive_name_unique UNIQUE (name);


--
-- Name: additive additive_pk; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.additive
    ADD CONSTRAINT additive_pk PRIMARY KEY (additive_id);


--
-- Name: alignment_method alignment_method_name_key; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.alignment_method
    ADD CONSTRAINT alignment_method_name_key UNIQUE (name);


--
-- Name: alignment_method alignment_method_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.alignment_method
    ADD CONSTRAINT alignment_method_pkey PRIMARY KEY (alignment_method_id);


--
-- Name: alignment alignment_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.alignment
    ADD CONSTRAINT alignment_pkey PRIMARY KEY (alignment_id, alignment_revision, alignment_taxa_revision);


--
-- Name: arv_class arv_class_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.arv_class
    ADD CONSTRAINT arv_class_pkey PRIMARY KEY (arv_class_id);


--
-- Name: bisulfite_converted_dna bisulfite_converted_dna_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.bisulfite_converted_dna
    ADD CONSTRAINT bisulfite_converted_dna_pkey PRIMARY KEY (bisulfite_converted_dna_id);


--
-- Name: chromat_na_sequence chromat_na_sequence_unique_join_keys; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.chromat_na_sequence
    ADD CONSTRAINT chromat_na_sequence_unique_join_keys UNIQUE (chromat_id, na_sequence_id, na_sequence_revision);


--
-- Name: chromat chromat_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.chromat
    ADD CONSTRAINT chromat_pkey PRIMARY KEY (chromat_id);


--
-- Name: chromat_type chromat_type_ident_string_key; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.chromat_type
    ADD CONSTRAINT chromat_type_ident_string_key UNIQUE (ident_string);


--
-- Name: chromat_type chromat_type_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.chromat_type
    ADD CONSTRAINT chromat_type_pkey PRIMARY KEY (chromat_type_id);


--
-- Name: clone clone_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.clone
    ADD CONSTRAINT clone_pkey PRIMARY KEY (clone_id);


--
-- Name: cohort cohort_name_key; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.cohort
    ADD CONSTRAINT cohort_name_key UNIQUE (name);


--
-- Name: cohort cohort_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.cohort
    ADD CONSTRAINT cohort_pkey PRIMARY KEY (cohort_id);


--
-- Name: copy_number_gel_lane copy_number_gel_lane_pk; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.copy_number_gel_lane
    ADD CONSTRAINT copy_number_gel_lane_pk PRIMARY KEY (copy_number_id, gel_lane_id);


--
-- Name: copy_number copy_number_pk; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.copy_number
    ADD CONSTRAINT copy_number_pk PRIMARY KEY (copy_number_id);


--
-- Name: enzyme enzyme_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.enzyme
    ADD CONSTRAINT enzyme_pkey PRIMARY KEY (enzyme_id);


--
-- Name: extract_type extract_type_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.extract_type
    ADD CONSTRAINT extract_type_pkey PRIMARY KEY (extract_type_id);


--
-- Name: extraction extraction_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.extraction
    ADD CONSTRAINT extraction_pkey PRIMARY KEY (extraction_id);


--
-- Name: aliquot freezer_aliquot_pk; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.aliquot
    ADD CONSTRAINT freezer_aliquot_pk PRIMARY KEY (aliquot_id);


--
-- Name: gel_lane gel_lane_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.gel_lane
    ADD CONSTRAINT gel_lane_pkey PRIMARY KEY (gel_lane_id);


--
-- Name: gel gel_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.gel
    ADD CONSTRAINT gel_pkey PRIMARY KEY (gel_id);


--
-- Name: genome_region genome_region_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.genome_region
    ADD CONSTRAINT genome_region_pkey PRIMARY KEY (name);


--
-- Name: hla_genotype hla_genotype_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.hla_genotype
    ADD CONSTRAINT hla_genotype_pkey PRIMARY KEY (hla_genotype_id);


--
-- Name: import_job import_job_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.import_job
    ADD CONSTRAINT import_job_pkey PRIMARY KEY (import_job_id);


--
-- Name: infection infection_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.infection
    ADD CONSTRAINT infection_pkey PRIMARY KEY (infection_id);


--
-- Name: lab_result_cat lab_result_cat_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.lab_result_cat
    ADD CONSTRAINT lab_result_cat_pkey PRIMARY KEY (lab_result_cat_id);


--
-- Name: lab_result_cat_type lab_result_cat_type_name_unique; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.lab_result_cat_type
    ADD CONSTRAINT lab_result_cat_type_name_unique UNIQUE (name);


--
-- Name: lab_result_cat_type lab_result_cat_type_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.lab_result_cat_type
    ADD CONSTRAINT lab_result_cat_type_pkey PRIMARY KEY (lab_result_cat_type_id);


--
-- Name: lab_result_cat_value lab_result_cat_value_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.lab_result_cat_value
    ADD CONSTRAINT lab_result_cat_value_pkey PRIMARY KEY (lab_result_cat_value_id);


--
-- Name: lab_result_cat_value lab_result_cat_value_unique_by_type; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.lab_result_cat_value
    ADD CONSTRAINT lab_result_cat_value_unique_by_type UNIQUE (lab_result_cat_type_id, name);


--
-- Name: lab_result_group lab_result_group_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.lab_result_group
    ADD CONSTRAINT lab_result_group_pkey PRIMARY KEY (lab_result_group_id);


--
-- Name: lab_result_num lab_result_num_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.lab_result_num
    ADD CONSTRAINT lab_result_num_pkey PRIMARY KEY (lab_result_num_id);


--
-- Name: lab_result_num_type lab_result_num_type_name_unique; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.lab_result_num_type
    ADD CONSTRAINT lab_result_num_type_name_unique UNIQUE (name);


--
-- Name: lab_result_num_type lab_result_num_type_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.lab_result_num_type
    ADD CONSTRAINT lab_result_num_type_pkey PRIMARY KEY (lab_result_num_type_id);


--
-- Name: location location_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.location
    ADD CONSTRAINT location_pkey PRIMARY KEY (location_id);


--
-- Name: medication medication_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.medication
    ADD CONSTRAINT medication_pkey PRIMARY KEY (medication_id);


--
-- Name: na_sequence_alignment_pairwise na_sequence_alignment_pairwise_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.na_sequence_alignment_pairwise
    ADD CONSTRAINT na_sequence_alignment_pairwise_pkey PRIMARY KEY (alignment_id, alignment_revision, alignment_taxa_revision, reference_start, sequence_start);


--
-- Name: na_sequence_alignment na_sequence_alignment_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.na_sequence_alignment
    ADD CONSTRAINT na_sequence_alignment_pkey PRIMARY KEY (na_sequence_id, na_sequence_revision, alignment_id, alignment_revision, alignment_taxa_revision);


--
-- Name: na_sequence na_sequence_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.na_sequence
    ADD CONSTRAINT na_sequence_pkey PRIMARY KEY (na_sequence_id, na_sequence_revision);


--
-- Name: notes note_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.notes
    ADD CONSTRAINT note_pkey PRIMARY KEY (note_id);


--
-- Name: organism organism_name_key; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.organism
    ADD CONSTRAINT organism_name_key UNIQUE (name);


--
-- Name: organism organism_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.organism
    ADD CONSTRAINT organism_pkey PRIMARY KEY (organism_id);


--
-- Name: patient_alias patient_alias_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.patient_alias
    ADD CONSTRAINT patient_alias_pkey PRIMARY KEY (cohort_id, patient_id, external_patient_id);


--
-- Name: patient_cohort patient_cohort_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.patient_cohort
    ADD CONSTRAINT patient_cohort_pkey PRIMARY KEY (patient_id, cohort_id);


--
-- Name: patient_group patient_group_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.patient_group
    ADD CONSTRAINT patient_group_pkey PRIMARY KEY (patient_group_id);


--
-- Name: patient_medication patient_medication_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.patient_medication
    ADD CONSTRAINT patient_medication_pkey PRIMARY KEY (patient_medication_id);


--
-- Name: patient_patient_group patient_patient_group_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.patient_patient_group
    ADD CONSTRAINT patient_patient_group_pkey PRIMARY KEY (patient_id, patient_group_id);


--
-- Name: patient patient_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.patient
    ADD CONSTRAINT patient_pkey PRIMARY KEY (patient_id);


--
-- Name: pcr_cleanup pcr_cleanup_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.pcr_cleanup
    ADD CONSTRAINT pcr_cleanup_pkey PRIMARY KEY (pcr_cleanup_id);


--
-- Name: pcr_pool_pcr_product pcr_pool_pcr_product_pcr_product_id_key; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.pcr_pool_pcr_product
    ADD CONSTRAINT pcr_pool_pcr_product_pcr_product_id_key UNIQUE (pcr_product_id);


--
-- Name: pcr_pool_pcr_product pcr_pool_pcr_product_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.pcr_pool_pcr_product
    ADD CONSTRAINT pcr_pool_pcr_product_pkey PRIMARY KEY (pcr_pool_id, pcr_product_id);


--
-- Name: pcr_pool pcr_pool_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.pcr_pool
    ADD CONSTRAINT pcr_pool_pkey PRIMARY KEY (pcr_pool_id);


--
-- Name: pcr_product pcr_product_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.pcr_product
    ADD CONSTRAINT pcr_product_pkey PRIMARY KEY (pcr_product_id);


--
-- Name: pcr_product_primer pcr_product_primer_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.pcr_product_primer
    ADD CONSTRAINT pcr_product_primer_pkey PRIMARY KEY (pcr_product_id, primer_id);


--
-- Name: pcr_template pcr_template_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.pcr_template
    ADD CONSTRAINT pcr_template_pkey PRIMARY KEY (pcr_template_id);


--
-- Name: primer primer_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.primer
    ADD CONSTRAINT primer_pkey PRIMARY KEY (primer_id);


--
-- Name: primer_position primer_position_primer_id_hxb2_start_hxb2_end_key; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.primer_position
    ADD CONSTRAINT primer_position_primer_id_hxb2_start_hxb2_end_key UNIQUE (primer_id, hxb2_start, hxb2_end);


--
-- Name: project_materials project_materials_project_sample_idx; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.project_materials
    ADD CONSTRAINT project_materials_project_sample_idx PRIMARY KEY (project_id, sample_id);


--
-- Name: project project_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.project
    ADD CONSTRAINT project_pkey PRIMARY KEY (project_id);


--
-- Name: protocol protocol_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.protocol
    ADD CONSTRAINT protocol_pkey PRIMARY KEY (protocol_id);


--
-- Name: protocol_type protocol_type_name_key; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.protocol_type
    ADD CONSTRAINT protocol_type_name_key UNIQUE (name);


--
-- Name: protocol_type protocol_type_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.protocol_type
    ADD CONSTRAINT protocol_type_pkey PRIMARY KEY (protocol_type_id);


--
-- Name: rt_primer rt_primer_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.rt_primer
    ADD CONSTRAINT rt_primer_pkey PRIMARY KEY (rt_product_id, primer_id);


--
-- Name: rt_product rt_product_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.rt_product
    ADD CONSTRAINT rt_product_pkey PRIMARY KEY (rt_product_id);


--
-- Name: sample_note sample_note_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.sample_note
    ADD CONSTRAINT sample_note_pkey PRIMARY KEY (note_id);


--
-- Name: sample sample_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.sample
    ADD CONSTRAINT sample_pkey PRIMARY KEY (sample_id);


--
-- Name: sample_type sample_type_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.sample_type
    ADD CONSTRAINT sample_type_pkey PRIMARY KEY (sample_type_id);


--
-- Name: scientist_group scientist_group_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.scientist_group
    ADD CONSTRAINT scientist_group_pkey PRIMARY KEY (scientist_group_id);


--
-- Name: scientist_group scientist_group_unique_name; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.scientist_group
    ADD CONSTRAINT scientist_group_unique_name UNIQUE (name);


--
-- Name: scientist scientist_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.scientist
    ADD CONSTRAINT scientist_pkey PRIMARY KEY (scientist_id);


--
-- Name: scientist scientist_username_key; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.scientist
    ADD CONSTRAINT scientist_username_key UNIQUE (username);


--
-- Name: sequence_type sequence_type_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.sequence_type
    ADD CONSTRAINT sequence_type_pkey PRIMARY KEY (sequence_type_id);


--
-- Name: unit unit_name_key; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.unit
    ADD CONSTRAINT unit_name_key UNIQUE (name);


--
-- Name: unit unit_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.unit
    ADD CONSTRAINT unit_pkey PRIMARY KEY (unit_id);


--
-- Name: visit visit_pkey; Type: CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.visit
    ADD CONSTRAINT visit_pkey PRIMARY KEY (visit_id);


--
-- Name: epitope_pept_id_index; Type: INDEX; Schema: epitope; Owner: :owner
--

CREATE INDEX epitope_pept_id_index ON epitope.epitope USING btree (pept_id);


--
-- Name: epitope_source_id_index; Type: INDEX; Schema: epitope; Owner: :owner
--

CREATE INDEX epitope_source_id_index ON epitope.epitope USING btree (source_id);


--
-- Name: pept_exp; Type: INDEX; Schema: epitope; Owner: :owner
--

CREATE INDEX pept_exp ON epitope.pept_response USING btree (exp_id);


--
-- Name: pept_response_pept_id_idx; Type: INDEX; Schema: epitope; Owner: :owner
--

CREATE INDEX pept_response_pept_id_idx ON epitope.pept_response USING btree (pept_id);


--
-- Name: pept_sample; Type: INDEX; Schema: epitope; Owner: :owner
--

CREATE INDEX pept_sample ON epitope.pept_response USING btree (sample_id);


--
-- Name: peptide_gene_id_idx; Type: INDEX; Schema: epitope; Owner: :owner
--

CREATE INDEX peptide_gene_id_idx ON epitope.peptide USING btree (gene_id);


--
-- Name: reading_measure_id_idx; Type: INDEX; Schema: epitope; Owner: :owner
--

CREATE INDEX reading_measure_id_idx ON epitope.reading USING btree (measure_id);


--
-- Name: titration_pept_id_index; Type: INDEX; Schema: epitope; Owner: :owner
--

CREATE INDEX titration_pept_id_index ON epitope.titration USING btree (pept_id);


--
-- Name: box_pos_aliquot_id_idx; Type: INDEX; Schema: freezer; Owner: :owner
--

CREATE UNIQUE INDEX box_pos_aliquot_id_idx ON freezer.box_pos USING btree (aliquot_id);


--
-- Name: aliquot_sample_id; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX aliquot_sample_id ON viroserve.aliquot USING btree (sample_id);


--
-- Name: distinct_sample_search_assignments_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX distinct_sample_search_assignments_idx ON viroserve.distinct_sample_search USING gin (assignments jsonb_path_ops);


--
-- Name: distinct_sample_search_available_aliquots_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX distinct_sample_search_available_aliquots_idx ON viroserve.distinct_sample_search USING btree (available_aliquots);


--
-- Name: distinct_sample_search_cohorts_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX distinct_sample_search_cohorts_idx ON viroserve.distinct_sample_search USING gin (cohorts);


--
-- Name: distinct_sample_search_derivation_id_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX distinct_sample_search_derivation_id_idx ON viroserve.distinct_sample_search USING btree (derivation_id);


--
-- Name: distinct_sample_search_derivation_protocol_id_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX distinct_sample_search_derivation_protocol_id_idx ON viroserve.distinct_sample_search USING btree (derivation_protocol_id);


--
-- Name: distinct_sample_search_derivation_protocol_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX distinct_sample_search_derivation_protocol_idx ON viroserve.distinct_sample_search USING btree (derivation_protocol);


--
-- Name: distinct_sample_search_has_sequences_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX distinct_sample_search_has_sequences_idx ON viroserve.distinct_sample_search USING btree (has_sequences) WHERE has_sequences;


--
-- Name: distinct_sample_search_na_type_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX distinct_sample_search_na_type_idx ON viroserve.distinct_sample_search USING btree (na_type);


--
-- Name: distinct_sample_search_name_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX distinct_sample_search_name_idx ON viroserve.distinct_sample_search USING btree (name);


--
-- Name: distinct_sample_search_patient_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX distinct_sample_search_patient_idx ON viroserve.distinct_sample_search USING btree (patient);


--
-- Name: distinct_sample_search_sample_date_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX distinct_sample_search_sample_date_idx ON viroserve.distinct_sample_search USING btree (sample_date);


--
-- Name: distinct_sample_search_sample_id_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE UNIQUE INDEX distinct_sample_search_sample_id_idx ON viroserve.distinct_sample_search USING btree (sample_id);


--
-- Name: distinct_sample_search_tissue_type_id_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX distinct_sample_search_tissue_type_id_idx ON viroserve.distinct_sample_search USING btree (tissue_type_id);


--
-- Name: distinct_sample_search_tissue_type_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX distinct_sample_search_tissue_type_idx ON viroserve.distinct_sample_search USING btree (tissue_type);


--
-- Name: distinct_sample_search_viral_load_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX distinct_sample_search_viral_load_idx ON viroserve.distinct_sample_search USING btree (viral_load);


--
-- Name: enzyme_type_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX enzyme_type_idx ON viroserve.enzyme USING btree (type);


--
-- Name: genome_region_base_end_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX genome_region_base_end_idx ON viroserve.genome_region USING btree (base_end);


--
-- Name: genome_region_base_range_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX genome_region_base_range_idx ON viroserve.genome_region USING gist (base_range);


--
-- Name: genome_region_base_start_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX genome_region_base_start_idx ON viroserve.genome_region USING btree (base_start);


--
-- Name: genome_region_name_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX genome_region_name_idx ON viroserve.genome_region USING btree (name);


--
-- Name: hla_genotype_key; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE UNIQUE INDEX hla_genotype_key ON viroserve.hla_genotype USING btree ((COALESCE(locus, ''::character varying)), (COALESCE(workshop, ''::bpchar)), (COALESCE((type)::integer, 0)), (COALESCE((subtype)::integer, 0)), (COALESCE((synonymous_polymorphism)::integer, 0)), (COALESCE((utr_polymorphism)::integer, 0)), (COALESCE(expression_level, ''::bpchar)), (COALESCE((ambiguity_group)::bpchar, ''::bpchar)));


--
-- Name: lab_num_type; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX lab_num_type ON viroserve.lab_result_num_type USING btree (lab_result_num_type_id);


--
-- Name: lab_result_cat_type_index; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX lab_result_cat_type_index ON viroserve.lab_result_cat_value USING btree (lab_result_cat_type_id);


--
-- Name: lab_result_cat_value_and_type; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX lab_result_cat_value_and_type ON viroserve.lab_result_cat USING btree (lab_result_cat_value_id, lab_result_cat_type_id);


--
-- Name: lab_result_cat_visit_type_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE UNIQUE INDEX lab_result_cat_visit_type_idx ON viroserve.lab_result_cat USING btree (visit_id, lab_result_cat_type_id);


--
-- Name: lab_result_num_lab_result_num_type_id; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX lab_result_num_lab_result_num_type_id ON viroserve.lab_result_num USING btree (lab_result_num_type_id);


--
-- Name: lab_result_num_sample; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX lab_result_num_sample ON viroserve.lab_result_num USING btree (sample_id);


--
-- Name: lab_result_num_type_to_group; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE UNIQUE INDEX lab_result_num_type_to_group ON viroserve.lab_result_num_type_group USING btree (lab_result_num_type_id, lab_result_group_id);


--
-- Name: lab_result_num_type_vv_uid; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX lab_result_num_type_vv_uid ON viroserve.lab_result_num_type USING btree (vv_uid);


--
-- Name: lab_result_num_visit_type_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE UNIQUE INDEX lab_result_num_visit_type_idx ON viroserve.lab_result_num USING btree (visit_id, lab_result_num_type_id);


--
-- Name: medication_abbreviation_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE UNIQUE INDEX medication_abbreviation_idx ON viroserve.medication USING btree (upper(abbreviation));


--
-- Name: na_samp_id; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX na_samp_id ON viroserve.na_sequence USING btree (sample_id);


--
-- Name: na_seq_alignment_id; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX na_seq_alignment_id ON viroserve.na_sequence_alignment USING btree (alignment_id);


--
-- Name: na_sequence_align_seq; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX na_sequence_align_seq ON viroserve.na_sequence_alignment USING btree (na_sequence_id, na_sequence_revision);


--
-- Name: only_one_primary_alias; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE UNIQUE INDEX only_one_primary_alias ON viroserve.patient_alias USING btree (patient_id, cohort_id) WHERE ((type)::text = 'primary'::text);


--
-- Name: organism_name_lowercase_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE UNIQUE INDEX organism_name_lowercase_idx ON viroserve.organism USING btree (lower(name));


--
-- Name: patient_medication_patient_id_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX patient_medication_patient_id_idx ON viroserve.patient_medication USING btree (patient_id);


--
-- Name: pcr_product_pcr_template_id_fk; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX pcr_product_pcr_template_id_fk ON viroserve.pcr_product USING btree (pcr_template_id);


--
-- Name: pcr_template_extraction_id_fk; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX pcr_template_extraction_id_fk ON viroserve.pcr_template USING btree (extraction_id);


--
-- Name: pcr_template_pcr_product_id_fk; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX pcr_template_pcr_product_id_fk ON viroserve.pcr_template USING btree (pcr_product_id);


--
-- Name: pcr_template_rt_product_id_fk; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX pcr_template_rt_product_id_fk ON viroserve.pcr_template USING btree (rt_product_id);


--
-- Name: pcr_template_sample_id_fk; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX pcr_template_sample_id_fk ON viroserve.pcr_template USING btree (sample_id);


--
-- Name: primer_name; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX primer_name ON viroserve.primer USING btree (name);


--
-- Name: primer_unique_name_sequence; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE UNIQUE INDEX primer_unique_name_sequence ON viroserve.primer USING btree (name, sequence);


--
-- Name: project_material_scientist_progress_fk_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE UNIQUE INDEX project_material_scientist_progress_fk_idx ON viroserve.project_material_scientist_progress USING btree (project_id, sample_id, scientist_id);


--
-- Name: project_material_scientist_progress_project_id_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX project_material_scientist_progress_project_id_idx ON viroserve.project_material_scientist_progress USING btree (project_id);


--
-- Name: project_material_scientist_progress_sample_id_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX project_material_scientist_progress_sample_id_idx ON viroserve.project_material_scientist_progress USING btree (sample_id);


--
-- Name: project_material_scientist_progress_scientist_id_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX project_material_scientist_progress_scientist_id_idx ON viroserve.project_material_scientist_progress USING btree (scientist_id);


--
-- Name: project_materials_sample_id_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX project_materials_sample_id_idx ON viroserve.project_materials USING btree (sample_id);


--
-- Name: project_name_key; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE UNIQUE INDEX project_name_key ON viroserve.project USING btree (lower(name));


--
-- Name: sample_visit; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX sample_visit ON viroserve.sample USING btree (visit_id);


--
-- Name: sequence_search_cohorts_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX sequence_search_cohorts_idx ON viroserve.sequence_search USING gin (cohorts);


--
-- Name: sequence_search_na_sequence_id_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE UNIQUE INDEX sequence_search_na_sequence_id_idx ON viroserve.sequence_search USING btree (na_sequence_id);


--
-- Name: sequence_search_na_type_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX sequence_search_na_type_idx ON viroserve.sequence_search USING btree (na_type);


--
-- Name: sequence_search_name_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX sequence_search_name_idx ON viroserve.sequence_search USING btree (name);


--
-- Name: sequence_search_patient_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX sequence_search_patient_idx ON viroserve.sequence_search USING btree (patient);


--
-- Name: sequence_search_pcr_name_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX sequence_search_pcr_name_idx ON viroserve.sequence_search USING btree (pcr_name);


--
-- Name: sequence_search_sample_name_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX sequence_search_sample_name_idx ON viroserve.sequence_search USING btree (sample_name);


--
-- Name: sequence_search_scientist_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX sequence_search_scientist_idx ON viroserve.sequence_search USING btree (scientist);


--
-- Name: sequence_search_tissue_type_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX sequence_search_tissue_type_idx ON viroserve.sequence_search USING btree (tissue_type);


--
-- Name: sequence_search_type_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX sequence_search_type_idx ON viroserve.sequence_search USING btree (type);


--
-- Name: tissue_type_name_key; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE UNIQUE INDEX tissue_type_name_key ON viroserve.tissue_type USING btree (name);


--
-- Name: tissue_type_name_lc_key; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE UNIQUE INDEX tissue_type_name_lc_key ON viroserve.tissue_type USING btree (lower((name)::text));


--
-- Name: unique_alias_within_cohort; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE UNIQUE INDEX unique_alias_within_cohort ON viroserve.patient_alias USING btree (external_patient_id, cohort_id);


--
-- Name: visit_date; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX visit_date ON viroserve.visit USING btree (visit_date);


--
-- Name: visit_patient; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE INDEX visit_patient ON viroserve.visit USING btree (patient_id);


--
-- Name: visit_patient_visit_date_idx; Type: INDEX; Schema: viroserve; Owner: :owner
--

CREATE UNIQUE INDEX visit_patient_visit_date_idx ON viroserve.visit USING btree (patient_id, visit_date) WHERE (visit_date IS NOT NULL);


--
-- Name: derivation derivation_input_sample_id_fkey; Type: FK CONSTRAINT; Schema: delta; Owner: :owner
--

ALTER TABLE ONLY delta.derivation
    ADD CONSTRAINT derivation_input_sample_id_fkey FOREIGN KEY (input_sample_id) REFERENCES viroserve.sample(sample_id);


--
-- Name: derivation derivation_protocol_id_fkey; Type: FK CONSTRAINT; Schema: delta; Owner: :owner
--

ALTER TABLE ONLY delta.derivation
    ADD CONSTRAINT derivation_protocol_id_fkey FOREIGN KEY (protocol_id) REFERENCES delta.protocol(protocol_id);


--
-- Name: derivation derivation_scientist_id_fkey; Type: FK CONSTRAINT; Schema: delta; Owner: :owner
--

ALTER TABLE ONLY delta.derivation
    ADD CONSTRAINT derivation_scientist_id_fkey FOREIGN KEY (scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: protocol_output protocol_output_protocol_id_fkey; Type: FK CONSTRAINT; Schema: delta; Owner: :owner
--

ALTER TABLE ONLY delta.protocol_output
    ADD CONSTRAINT protocol_output_protocol_id_fkey FOREIGN KEY (protocol_id) REFERENCES delta.protocol(protocol_id);


--
-- Name: protocol_output protocol_output_tissue_type_id_fkey; Type: FK CONSTRAINT; Schema: delta; Owner: :owner
--

ALTER TABLE ONLY delta.protocol_output
    ADD CONSTRAINT protocol_output_tissue_type_id_fkey FOREIGN KEY (tissue_type_id) REFERENCES viroserve.tissue_type(tissue_type_id);


--
-- Name: epitope_mutant epitope_mutant_epit_id_fkey; Type: FK CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.epitope_mutant
    ADD CONSTRAINT epitope_mutant_epit_id_fkey FOREIGN KEY (epit_id) REFERENCES epitope.epitope(epit_id);


--
-- Name: epitope_mutant epitope_mutant_mutant_id_fkey; Type: FK CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.epitope_mutant
    ADD CONSTRAINT epitope_mutant_mutant_id_fkey FOREIGN KEY (mutant_id) REFERENCES epitope.mutant(mutant_id);


--
-- Name: epitope epitope_pept_id_fkey; Type: FK CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.epitope
    ADD CONSTRAINT epitope_pept_id_fkey FOREIGN KEY (pept_id) REFERENCES epitope.peptide(pept_id);


--
-- Name: epitope_sequence epitope_sequence_na_sequence_id_fkey; Type: FK CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.epitope_sequence
    ADD CONSTRAINT epitope_sequence_na_sequence_id_fkey FOREIGN KEY (na_sequence_id, na_sequence_revision) REFERENCES viroserve.na_sequence(na_sequence_id, na_sequence_revision);


--
-- Name: epitope_sequence epitope_sequence_pept_id_fkey; Type: FK CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.epitope_sequence
    ADD CONSTRAINT epitope_sequence_pept_id_fkey FOREIGN KEY (pept_id) REFERENCES epitope.peptide(pept_id);


--
-- Name: epitope epitope_source_id_fkey; Type: FK CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.epitope
    ADD CONSTRAINT epitope_source_id_fkey FOREIGN KEY (source_id) REFERENCES epitope.epitope_source(source_id);


--
-- Name: hla hla_hla_genotype_id_fkey; Type: FK CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.hla
    ADD CONSTRAINT hla_hla_genotype_id_fkey FOREIGN KEY (hla_genotype_id) REFERENCES viroserve.hla_genotype(hla_genotype_id);


--
-- Name: hla_pept hla_pept_hla_id_fkey; Type: FK CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.hla_pept
    ADD CONSTRAINT hla_pept_hla_id_fkey FOREIGN KEY (hla_id) REFERENCES epitope.hla(hla_id);


--
-- Name: hla_pept hla_pept_pept_id_fkey; Type: FK CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.hla_pept
    ADD CONSTRAINT hla_pept_pept_id_fkey FOREIGN KEY (pept_id) REFERENCES epitope.peptide(pept_id);


--
-- Name: hla_response hla_response_blcl_id_fkey; Type: FK CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.hla_response
    ADD CONSTRAINT hla_response_blcl_id_fkey FOREIGN KEY (blcl_id) REFERENCES epitope.blcl(blcl_id);


--
-- Name: hla_response hla_response_exp_id_fkey; Type: FK CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.hla_response
    ADD CONSTRAINT hla_response_exp_id_fkey FOREIGN KEY (exp_id) REFERENCES epitope.experiment(exp_id);


--
-- Name: hla_response hla_response_pept_id_fkey; Type: FK CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.hla_response
    ADD CONSTRAINT hla_response_pept_id_fkey FOREIGN KEY (pept_id) REFERENCES epitope.peptide(pept_id);


--
-- Name: hla_response hla_response_sample_id_fkey; Type: FK CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.hla_response
    ADD CONSTRAINT hla_response_sample_id_fkey FOREIGN KEY (sample_id) REFERENCES viroserve.sample(sample_id);


--
-- Name: mutant mutant_pept_id_fkey; Type: FK CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.mutant
    ADD CONSTRAINT mutant_pept_id_fkey FOREIGN KEY (pept_id) REFERENCES epitope.peptide(pept_id);


--
-- Name: origin origin_na_sequence_id_fkey; Type: FK CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.origin
    ADD CONSTRAINT origin_na_sequence_id_fkey FOREIGN KEY (na_sequence_id, na_sequence_revision) REFERENCES viroserve.na_sequence(na_sequence_id, na_sequence_revision);


--
-- Name: origin_peptide origin_peptide_origin_id_fkey; Type: FK CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.origin_peptide
    ADD CONSTRAINT origin_peptide_origin_id_fkey FOREIGN KEY (origin_id) REFERENCES epitope.origin(origin_id);


--
-- Name: origin_peptide origin_peptide_pept_id_fkey; Type: FK CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.origin_peptide
    ADD CONSTRAINT origin_peptide_pept_id_fkey FOREIGN KEY (pept_id) REFERENCES epitope.peptide(pept_id);


--
-- Name: pept_response pept_response_exp_id_fkey; Type: FK CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.pept_response
    ADD CONSTRAINT pept_response_exp_id_fkey FOREIGN KEY (exp_id) REFERENCES epitope.experiment(exp_id);


--
-- Name: pept_response pept_response_pept_id_fkey; Type: FK CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.pept_response
    ADD CONSTRAINT pept_response_pept_id_fkey FOREIGN KEY (pept_id) REFERENCES epitope.peptide(pept_id);


--
-- Name: pept_response pept_response_sample_id_fkey; Type: FK CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.pept_response
    ADD CONSTRAINT pept_response_sample_id_fkey FOREIGN KEY (sample_id) REFERENCES viroserve.sample(sample_id);


--
-- Name: peptide peptide_gene_id_fkey; Type: FK CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.peptide
    ADD CONSTRAINT peptide_gene_id_fkey FOREIGN KEY (gene_id) REFERENCES epitope.gene(gene_id);


--
-- Name: peptide peptide_origin_id_fkey; Type: FK CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.peptide
    ADD CONSTRAINT peptide_origin_id_fkey FOREIGN KEY (origin_id) REFERENCES epitope.origin(origin_id);


--
-- Name: pool_pept pool_pept_pept_id_fkey; Type: FK CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.pool_pept
    ADD CONSTRAINT pool_pept_pept_id_fkey FOREIGN KEY (pept_id) REFERENCES epitope.peptide(pept_id);


--
-- Name: pool_pept pool_pept_pool_id_fkey; Type: FK CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.pool_pept
    ADD CONSTRAINT pool_pept_pool_id_fkey FOREIGN KEY (pool_id) REFERENCES epitope.pool(pool_id);


--
-- Name: pool_response pool_response_exp_id_fkey; Type: FK CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.pool_response
    ADD CONSTRAINT pool_response_exp_id_fkey FOREIGN KEY (exp_id) REFERENCES epitope.experiment(exp_id);


--
-- Name: pool_response pool_response_pool_id_fkey; Type: FK CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.pool_response
    ADD CONSTRAINT pool_response_pool_id_fkey FOREIGN KEY (pool_id) REFERENCES epitope.pool(pool_id);


--
-- Name: pool_response pool_response_sample_id_fkey; Type: FK CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.pool_response
    ADD CONSTRAINT pool_response_sample_id_fkey FOREIGN KEY (sample_id) REFERENCES viroserve.sample(sample_id);


--
-- Name: reading reading_measure_id_fkey; Type: FK CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.reading
    ADD CONSTRAINT reading_measure_id_fkey FOREIGN KEY (measure_id) REFERENCES epitope.measurement(measure_id);


--
-- Name: titration titration_conc_id_fkey; Type: FK CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.titration
    ADD CONSTRAINT titration_conc_id_fkey FOREIGN KEY (conc_id) REFERENCES epitope.titration_conc(conc_id);


--
-- Name: titration titration_exp_id_fkey; Type: FK CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.titration
    ADD CONSTRAINT titration_exp_id_fkey FOREIGN KEY (exp_id) REFERENCES epitope.experiment(exp_id);


--
-- Name: titration titration_pept_id_fkey; Type: FK CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.titration
    ADD CONSTRAINT titration_pept_id_fkey FOREIGN KEY (pept_id) REFERENCES epitope.peptide(pept_id);


--
-- Name: titration titration_sample_id_fkey; Type: FK CONSTRAINT; Schema: epitope; Owner: :owner
--

ALTER TABLE ONLY epitope.titration
    ADD CONSTRAINT titration_sample_id_fkey FOREIGN KEY (sample_id) REFERENCES viroserve.sample(sample_id);


--
-- Name: box_pos box_bos_box_fk; Type: FK CONSTRAINT; Schema: freezer; Owner: :owner
--

ALTER TABLE ONLY freezer.box_pos
    ADD CONSTRAINT box_bos_box_fk FOREIGN KEY (box_id) REFERENCES freezer.box(box_id);


--
-- Name: box_pos box_pos_aliquot_fk; Type: FK CONSTRAINT; Schema: freezer; Owner: :owner
--

ALTER TABLE ONLY freezer.box_pos
    ADD CONSTRAINT box_pos_aliquot_fk FOREIGN KEY (aliquot_id) REFERENCES viroserve.aliquot(aliquot_id);


--
-- Name: freezer creating_scientist_fk; Type: FK CONSTRAINT; Schema: freezer; Owner: :owner
--

ALTER TABLE ONLY freezer.freezer
    ADD CONSTRAINT creating_scientist_fk FOREIGN KEY (creating_scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: box freezer_box_creating_scientist_fk; Type: FK CONSTRAINT; Schema: freezer; Owner: :owner
--

ALTER TABLE ONLY freezer.box
    ADD CONSTRAINT freezer_box_creating_scientist_fk FOREIGN KEY (creating_scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: box freezer_box_owning_scientist_fk; Type: FK CONSTRAINT; Schema: freezer; Owner: :owner
--

ALTER TABLE ONLY freezer.box
    ADD CONSTRAINT freezer_box_owning_scientist_fk FOREIGN KEY (owning_scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: box freezer_box_rack_fk; Type: FK CONSTRAINT; Schema: freezer; Owner: :owner
--

ALTER TABLE ONLY freezer.box
    ADD CONSTRAINT freezer_box_rack_fk FOREIGN KEY (rack_id) REFERENCES freezer.rack(rack_id);


--
-- Name: rack freezer_rack_ owning_scientist_fk; Type: FK CONSTRAINT; Schema: freezer; Owner: :owner
--

ALTER TABLE ONLY freezer.rack
    ADD CONSTRAINT "freezer_rack_ owning_scientist_fk" FOREIGN KEY (owning_scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: rack freezer_rack_creating_scientist_id; Type: FK CONSTRAINT; Schema: freezer; Owner: :owner
--

ALTER TABLE ONLY freezer.rack
    ADD CONSTRAINT freezer_rack_creating_scientist_id FOREIGN KEY (creating_scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: rack freezer_rack_freezer_fk; Type: FK CONSTRAINT; Schema: freezer; Owner: :owner
--

ALTER TABLE ONLY freezer.rack
    ADD CONSTRAINT freezer_rack_freezer_fk FOREIGN KEY (freezer_id) REFERENCES freezer.freezer(freezer_id);


--
-- Name: freezer owning_scientist_fk; Type: FK CONSTRAINT; Schema: freezer; Owner: :owner
--

ALTER TABLE ONLY freezer.freezer
    ADD CONSTRAINT owning_scientist_fk FOREIGN KEY (owning_scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: changes changes_project_fkey; Type: FK CONSTRAINT; Schema: sqitch; Owner: :owner
--

ALTER TABLE ONLY sqitch.changes
    ADD CONSTRAINT changes_project_fkey FOREIGN KEY (project) REFERENCES sqitch.projects(project) ON UPDATE CASCADE;


--
-- Name: dependencies dependencies_change_id_fkey; Type: FK CONSTRAINT; Schema: sqitch; Owner: :owner
--

ALTER TABLE ONLY sqitch.dependencies
    ADD CONSTRAINT dependencies_change_id_fkey FOREIGN KEY (change_id) REFERENCES sqitch.changes(change_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: dependencies dependencies_dependency_id_fkey; Type: FK CONSTRAINT; Schema: sqitch; Owner: :owner
--

ALTER TABLE ONLY sqitch.dependencies
    ADD CONSTRAINT dependencies_dependency_id_fkey FOREIGN KEY (dependency_id) REFERENCES sqitch.changes(change_id) ON UPDATE CASCADE;


--
-- Name: events events_project_fkey; Type: FK CONSTRAINT; Schema: sqitch; Owner: :owner
--

ALTER TABLE ONLY sqitch.events
    ADD CONSTRAINT events_project_fkey FOREIGN KEY (project) REFERENCES sqitch.projects(project) ON UPDATE CASCADE;


--
-- Name: tags tags_change_id_fkey; Type: FK CONSTRAINT; Schema: sqitch; Owner: :owner
--

ALTER TABLE ONLY sqitch.tags
    ADD CONSTRAINT tags_change_id_fkey FOREIGN KEY (change_id) REFERENCES sqitch.changes(change_id) ON UPDATE CASCADE;


--
-- Name: tags tags_project_fkey; Type: FK CONSTRAINT; Schema: sqitch; Owner: :owner
--

ALTER TABLE ONLY sqitch.tags
    ADD CONSTRAINT tags_project_fkey FOREIGN KEY (project) REFERENCES sqitch.projects(project) ON UPDATE CASCADE;


--
-- Name: sample additive_fk; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.sample
    ADD CONSTRAINT additive_fk FOREIGN KEY (additive_id) REFERENCES viroserve.additive(additive_id);


--
-- Name: alignment alignment_alignment_method_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.alignment
    ADD CONSTRAINT alignment_alignment_method_id_fkey FOREIGN KEY (alignment_method_id) REFERENCES viroserve.alignment_method(alignment_method_id);


--
-- Name: alignment alignment_scientist_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.alignment
    ADD CONSTRAINT alignment_scientist_id_fkey FOREIGN KEY (scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: aliquot aliquot_creating_scientist_fk; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.aliquot
    ADD CONSTRAINT aliquot_creating_scientist_fk FOREIGN KEY (creating_scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: aliquot aliquot_possessing_scientist_fk; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.aliquot
    ADD CONSTRAINT aliquot_possessing_scientist_fk FOREIGN KEY (possessing_scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: aliquot aliquot_sample_fk; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.aliquot
    ADD CONSTRAINT aliquot_sample_fk FOREIGN KEY (sample_id) REFERENCES viroserve.sample(sample_id);


--
-- Name: aliquot aliquot_unit_fk; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.aliquot
    ADD CONSTRAINT aliquot_unit_fk FOREIGN KEY (unit_id) REFERENCES viroserve.unit(unit_id);


--
-- Name: bisulfite_converted_dna bisulfite_converted_dna_extraction_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.bisulfite_converted_dna
    ADD CONSTRAINT bisulfite_converted_dna_extraction_id_fkey FOREIGN KEY (extraction_id) REFERENCES viroserve.extraction(extraction_id);


--
-- Name: bisulfite_converted_dna bisulfite_converted_dna_protocol_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.bisulfite_converted_dna
    ADD CONSTRAINT bisulfite_converted_dna_protocol_id_fkey FOREIGN KEY (protocol_id) REFERENCES viroserve.protocol(protocol_id);


--
-- Name: bisulfite_converted_dna bisulfite_converted_dna_rt_product_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.bisulfite_converted_dna
    ADD CONSTRAINT bisulfite_converted_dna_rt_product_id_fkey FOREIGN KEY (rt_product_id) REFERENCES viroserve.rt_product(rt_product_id);


--
-- Name: bisulfite_converted_dna bisulfite_converted_dna_sample_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.bisulfite_converted_dna
    ADD CONSTRAINT bisulfite_converted_dna_sample_id_fkey FOREIGN KEY (sample_id) REFERENCES viroserve.sample(sample_id);


--
-- Name: bisulfite_converted_dna bisulfite_converted_dna_scientist_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.bisulfite_converted_dna
    ADD CONSTRAINT bisulfite_converted_dna_scientist_id_fkey FOREIGN KEY (scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: chromat chromat_chromat_type_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.chromat
    ADD CONSTRAINT chromat_chromat_type_id_fkey FOREIGN KEY (chromat_type_id) REFERENCES viroserve.chromat_type(chromat_type_id);


--
-- Name: chromat_na_sequence chromat_na_sequence_chromat_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.chromat_na_sequence
    ADD CONSTRAINT chromat_na_sequence_chromat_id_fkey FOREIGN KEY (chromat_id) REFERENCES viroserve.chromat(chromat_id);


--
-- Name: chromat_na_sequence chromat_na_sequence_id_fk; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.chromat_na_sequence
    ADD CONSTRAINT chromat_na_sequence_id_fk FOREIGN KEY (na_sequence_id, na_sequence_revision) REFERENCES viroserve.na_sequence(na_sequence_id, na_sequence_revision);


--
-- Name: chromat chromat_primer_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.chromat
    ADD CONSTRAINT chromat_primer_id_fkey FOREIGN KEY (primer_id) REFERENCES viroserve.primer(primer_id);


--
-- Name: chromat chromat_scientist_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.chromat
    ADD CONSTRAINT chromat_scientist_id_fkey FOREIGN KEY (scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: clone clone_pcr_product_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.clone
    ADD CONSTRAINT clone_pcr_product_id_fkey FOREIGN KEY (pcr_product_id) REFERENCES viroserve.pcr_product(pcr_product_id);


--
-- Name: clone clone_scientist_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.clone
    ADD CONSTRAINT clone_scientist_id_fkey FOREIGN KEY (scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: copy_number copy_number_bisulfite_converted_dna_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.copy_number
    ADD CONSTRAINT copy_number_bisulfite_converted_dna_id_fkey FOREIGN KEY (bisulfite_converted_dna_id) REFERENCES viroserve.bisulfite_converted_dna(bisulfite_converted_dna_id);


--
-- Name: copy_number_gel_lane copy_number_fk; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.copy_number_gel_lane
    ADD CONSTRAINT copy_number_fk FOREIGN KEY (copy_number_id) REFERENCES viroserve.copy_number(copy_number_id);


--
-- Name: copy_number copy_number_sample_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.copy_number
    ADD CONSTRAINT copy_number_sample_id_fkey FOREIGN KEY (sample_id) REFERENCES viroserve.sample(sample_id);


--
-- Name: extraction extraction_concentration_unit_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.extraction
    ADD CONSTRAINT extraction_concentration_unit_id_fkey FOREIGN KEY (concentration_unit_id) REFERENCES viroserve.unit(unit_id);


--
-- Name: extraction extraction_eluted_vol_unit_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.extraction
    ADD CONSTRAINT extraction_eluted_vol_unit_id_fkey FOREIGN KEY (eluted_vol_unit_id) REFERENCES viroserve.unit(unit_id);


--
-- Name: extraction extraction_extract_type_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.extraction
    ADD CONSTRAINT extraction_extract_type_id_fkey FOREIGN KEY (extract_type_id) REFERENCES viroserve.extract_type(extract_type_id);


--
-- Name: copy_number extraction_fk; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.copy_number
    ADD CONSTRAINT extraction_fk FOREIGN KEY (extraction_id) REFERENCES viroserve.extraction(extraction_id);


--
-- Name: extraction extraction_protocol_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.extraction
    ADD CONSTRAINT extraction_protocol_id_fkey FOREIGN KEY (protocol_id) REFERENCES viroserve.protocol(protocol_id);


--
-- Name: extraction extraction_sample_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.extraction
    ADD CONSTRAINT extraction_sample_id_fkey FOREIGN KEY (sample_id) REFERENCES viroserve.sample(sample_id);


--
-- Name: extraction extraction_scientist_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.extraction
    ADD CONSTRAINT extraction_scientist_id_fkey FOREIGN KEY (scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: extraction extraction_unit_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.extraction
    ADD CONSTRAINT extraction_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES viroserve.unit(unit_id);


--
-- Name: copy_number_gel_lane gel_lane_fk; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.copy_number_gel_lane
    ADD CONSTRAINT gel_lane_fk FOREIGN KEY (gel_lane_id) REFERENCES viroserve.gel_lane(gel_lane_id);


--
-- Name: gel_lane gel_lane_gel_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.gel_lane
    ADD CONSTRAINT gel_lane_gel_id_fkey FOREIGN KEY (gel_id) REFERENCES viroserve.gel(gel_id);


--
-- Name: gel_lane gel_lane_pcr_product_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.gel_lane
    ADD CONSTRAINT gel_lane_pcr_product_id_fkey FOREIGN KEY (pcr_product_id) REFERENCES viroserve.pcr_product(pcr_product_id);


--
-- Name: gel gel_protocol_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.gel
    ADD CONSTRAINT gel_protocol_id_fkey FOREIGN KEY (protocol_id) REFERENCES viroserve.protocol(protocol_id);


--
-- Name: gel gel_scientist_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.gel
    ADD CONSTRAINT gel_scientist_id_fkey FOREIGN KEY (scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: import_job import_job_scientist_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.import_job
    ADD CONSTRAINT import_job_scientist_id_fkey FOREIGN KEY (scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: infection infection_location_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.infection
    ADD CONSTRAINT infection_location_id_fkey FOREIGN KEY (location_id) REFERENCES viroserve.location(location_id);


--
-- Name: infection infection_patient_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.infection
    ADD CONSTRAINT infection_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES viroserve.patient(patient_id);


--
-- Name: lab_result_cat lab_result_cat_lab_result_cat_type_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.lab_result_cat
    ADD CONSTRAINT lab_result_cat_lab_result_cat_type_id_fkey FOREIGN KEY (lab_result_cat_type_id) REFERENCES viroserve.lab_result_cat_type(lab_result_cat_type_id);


--
-- Name: lab_result_cat lab_result_cat_lab_result_cat_value_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.lab_result_cat
    ADD CONSTRAINT lab_result_cat_lab_result_cat_value_id_fkey FOREIGN KEY (lab_result_cat_value_id) REFERENCES viroserve.lab_result_cat_value(lab_result_cat_value_id);


--
-- Name: lab_result_cat lab_result_cat_sample_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.lab_result_cat
    ADD CONSTRAINT lab_result_cat_sample_id_fkey FOREIGN KEY (sample_id) REFERENCES viroserve.sample(sample_id);


--
-- Name: lab_result_cat lab_result_cat_scientist_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.lab_result_cat
    ADD CONSTRAINT lab_result_cat_scientist_id_fkey FOREIGN KEY (scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: lab_result_cat_type_group lab_result_cat_type_group_lab_result_cat_type_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.lab_result_cat_type_group
    ADD CONSTRAINT lab_result_cat_type_group_lab_result_cat_type_id_fkey FOREIGN KEY (lab_result_cat_type_id) REFERENCES viroserve.lab_result_cat_type(lab_result_cat_type_id);


--
-- Name: lab_result_cat_type_group lab_result_cat_type_group_lab_result_group_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.lab_result_cat_type_group
    ADD CONSTRAINT lab_result_cat_type_group_lab_result_group_id_fkey FOREIGN KEY (lab_result_group_id) REFERENCES viroserve.lab_result_group(lab_result_group_id);


--
-- Name: lab_result_cat_type lab_result_cat_type_normal_lab_result_cat_value_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.lab_result_cat_type
    ADD CONSTRAINT lab_result_cat_type_normal_lab_result_cat_value_id_fkey FOREIGN KEY (normal_lab_result_cat_value_id) REFERENCES viroserve.lab_result_cat_value(lab_result_cat_value_id);


--
-- Name: lab_result_cat_value lab_result_cat_value_lab_result_cat_type_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.lab_result_cat_value
    ADD CONSTRAINT lab_result_cat_value_lab_result_cat_type_id_fkey FOREIGN KEY (lab_result_cat_type_id) REFERENCES viroserve.lab_result_cat_type(lab_result_cat_type_id);


--
-- Name: lab_result_cat lab_result_cat_visit_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.lab_result_cat
    ADD CONSTRAINT lab_result_cat_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES viroserve.visit(visit_id);


--
-- Name: lab_result_group lab_result_group_scientist_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.lab_result_group
    ADD CONSTRAINT lab_result_group_scientist_id_fkey FOREIGN KEY (scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: lab_result_num lab_result_num_lab_result_num_type_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.lab_result_num
    ADD CONSTRAINT lab_result_num_lab_result_num_type_id_fkey FOREIGN KEY (lab_result_num_type_id) REFERENCES viroserve.lab_result_num_type(lab_result_num_type_id);


--
-- Name: lab_result_num lab_result_num_sample_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.lab_result_num
    ADD CONSTRAINT lab_result_num_sample_id_fkey FOREIGN KEY (sample_id) REFERENCES viroserve.sample(sample_id);


--
-- Name: lab_result_num lab_result_num_scientist_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.lab_result_num
    ADD CONSTRAINT lab_result_num_scientist_id_fkey FOREIGN KEY (scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: lab_result_num_type_group lab_result_num_type_group_lab_result_group_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.lab_result_num_type_group
    ADD CONSTRAINT lab_result_num_type_group_lab_result_group_id_fkey FOREIGN KEY (lab_result_group_id) REFERENCES viroserve.lab_result_group(lab_result_group_id);


--
-- Name: lab_result_num_type_group lab_result_num_type_group_lab_result_num_type_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.lab_result_num_type_group
    ADD CONSTRAINT lab_result_num_type_group_lab_result_num_type_id_fkey FOREIGN KEY (lab_result_num_type_id) REFERENCES viroserve.lab_result_num_type(lab_result_num_type_id);


--
-- Name: lab_result_num_type lab_result_num_type_unit_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.lab_result_num_type
    ADD CONSTRAINT lab_result_num_type_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES viroserve.unit(unit_id);


--
-- Name: lab_result_num lab_result_num_visit_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.lab_result_num
    ADD CONSTRAINT lab_result_num_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES viroserve.visit(visit_id);


--
-- Name: medication medication_arv_class_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.medication
    ADD CONSTRAINT medication_arv_class_id_fkey FOREIGN KEY (arv_class_id) REFERENCES viroserve.arv_class(arv_class_id);


--
-- Name: na_sequence_alignment na_sequence_alignment_alignment_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.na_sequence_alignment
    ADD CONSTRAINT na_sequence_alignment_alignment_id_fkey FOREIGN KEY (alignment_id, alignment_revision, alignment_taxa_revision) REFERENCES viroserve.alignment(alignment_id, alignment_revision, alignment_taxa_revision);


--
-- Name: na_sequence_alignment na_sequence_alignment_na_sequence_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.na_sequence_alignment
    ADD CONSTRAINT na_sequence_alignment_na_sequence_id_fkey FOREIGN KEY (na_sequence_id, na_sequence_revision) REFERENCES viroserve.na_sequence(na_sequence_id, na_sequence_revision);


--
-- Name: na_sequence_alignment_pairwise na_sequence_alignment_pairwise_alignment_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.na_sequence_alignment_pairwise
    ADD CONSTRAINT na_sequence_alignment_pairwise_alignment_id_fkey FOREIGN KEY (alignment_id, alignment_revision, alignment_taxa_revision) REFERENCES viroserve.alignment(alignment_id, alignment_revision, alignment_taxa_revision);


--
-- Name: na_sequence na_sequence_clone_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.na_sequence
    ADD CONSTRAINT na_sequence_clone_id_fkey FOREIGN KEY (clone_id) REFERENCES viroserve.clone(clone_id);


--
-- Name: na_sequence na_sequence_pcr_product_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.na_sequence
    ADD CONSTRAINT na_sequence_pcr_product_id_fkey FOREIGN KEY (pcr_product_id) REFERENCES viroserve.pcr_product(pcr_product_id);


--
-- Name: na_sequence na_sequence_sample_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.na_sequence
    ADD CONSTRAINT na_sequence_sample_id_fkey FOREIGN KEY (sample_id) REFERENCES viroserve.sample(sample_id);


--
-- Name: na_sequence na_sequence_scientist_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.na_sequence
    ADD CONSTRAINT na_sequence_scientist_id_fkey FOREIGN KEY (scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: na_sequence na_sequence_sequence_type_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.na_sequence
    ADD CONSTRAINT na_sequence_sequence_type_id_fkey FOREIGN KEY (sequence_type_id) REFERENCES viroserve.sequence_type(sequence_type_id);


--
-- Name: sample_note note_sample_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.sample_note
    ADD CONSTRAINT note_sample_id_fkey FOREIGN KEY (sample_id) REFERENCES viroserve.sample(sample_id);


--
-- Name: notes note_scientist_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.notes
    ADD CONSTRAINT note_scientist_id_fkey FOREIGN KEY (scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: sample_note note_scientist_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.sample_note
    ADD CONSTRAINT note_scientist_id_fkey FOREIGN KEY (scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: patient_alias patient_alias_cohort_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.patient_alias
    ADD CONSTRAINT patient_alias_cohort_id_fkey FOREIGN KEY (cohort_id) REFERENCES viroserve.cohort(cohort_id);


--
-- Name: patient_alias patient_alias_patient_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.patient_alias
    ADD CONSTRAINT patient_alias_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES viroserve.patient(patient_id);


--
-- Name: patient_cohort patient_cohort_cohort_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.patient_cohort
    ADD CONSTRAINT patient_cohort_cohort_id_fkey FOREIGN KEY (cohort_id) REFERENCES viroserve.cohort(cohort_id);


--
-- Name: patient_cohort patient_cohort_patient_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.patient_cohort
    ADD CONSTRAINT patient_cohort_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES viroserve.patient(patient_id);


--
-- Name: patient_group patient_group_scientist_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.patient_group
    ADD CONSTRAINT patient_group_scientist_id_fkey FOREIGN KEY (scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: patient_hla_genotype patient_hla_genotype_hla_genotype_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.patient_hla_genotype
    ADD CONSTRAINT patient_hla_genotype_hla_genotype_id_fkey FOREIGN KEY (hla_genotype_id) REFERENCES viroserve.hla_genotype(hla_genotype_id);


--
-- Name: patient_hla_genotype patient_hla_genotype_patient_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.patient_hla_genotype
    ADD CONSTRAINT patient_hla_genotype_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES viroserve.patient(patient_id);


--
-- Name: patient patient_location_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.patient
    ADD CONSTRAINT patient_location_id_fkey FOREIGN KEY (location_id) REFERENCES viroserve.location(location_id);


--
-- Name: patient_medication patient_medication_medication_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.patient_medication
    ADD CONSTRAINT patient_medication_medication_id_fkey FOREIGN KEY (medication_id) REFERENCES viroserve.medication(medication_id);


--
-- Name: patient_medication patient_medication_patient_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.patient_medication
    ADD CONSTRAINT patient_medication_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES viroserve.patient(patient_id);


--
-- Name: patient_patient_group patient_patient_group_patient_group_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.patient_patient_group
    ADD CONSTRAINT patient_patient_group_patient_group_id_fkey FOREIGN KEY (patient_group_id) REFERENCES viroserve.patient_group(patient_group_id);


--
-- Name: patient_patient_group patient_patient_group_patient_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.patient_patient_group
    ADD CONSTRAINT patient_patient_group_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES viroserve.patient(patient_id);


--
-- Name: pcr_cleanup pcr_cleanup_final_conc_unit_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.pcr_cleanup
    ADD CONSTRAINT pcr_cleanup_final_conc_unit_id_fkey FOREIGN KEY (final_conc_unit_id) REFERENCES viroserve.unit(unit_id);


--
-- Name: pcr_cleanup pcr_cleanup_pcr_product_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.pcr_cleanup
    ADD CONSTRAINT pcr_cleanup_pcr_product_id_fkey FOREIGN KEY (pcr_product_id) REFERENCES viroserve.pcr_product(pcr_product_id);


--
-- Name: pcr_cleanup pcr_cleanup_protocol_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.pcr_cleanup
    ADD CONSTRAINT pcr_cleanup_protocol_id_fkey FOREIGN KEY (protocol_id) REFERENCES viroserve.protocol(protocol_id);


--
-- Name: pcr_cleanup pcr_cleanup_scientist_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.pcr_cleanup
    ADD CONSTRAINT pcr_cleanup_scientist_id_fkey FOREIGN KEY (scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: pcr_pool_pcr_product pcr_pool_pcr_product_pcr_pool_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.pcr_pool_pcr_product
    ADD CONSTRAINT pcr_pool_pcr_product_pcr_pool_id_fkey FOREIGN KEY (pcr_pool_id) REFERENCES viroserve.pcr_pool(pcr_pool_id);


--
-- Name: pcr_pool_pcr_product pcr_pool_pcr_product_pcr_product_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.pcr_pool_pcr_product
    ADD CONSTRAINT pcr_pool_pcr_product_pcr_product_id_fkey FOREIGN KEY (pcr_product_id) REFERENCES viroserve.pcr_product(pcr_product_id);


--
-- Name: pcr_pool pcr_pool_scientist_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.pcr_pool
    ADD CONSTRAINT pcr_pool_scientist_id_fkey FOREIGN KEY (scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: pcr_product pcr_product_enzyme_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.pcr_product
    ADD CONSTRAINT pcr_product_enzyme_id_fkey FOREIGN KEY (enzyme_id) REFERENCES viroserve.enzyme(enzyme_id);


--
-- Name: pcr_product pcr_product_pcr_pool_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.pcr_product
    ADD CONSTRAINT pcr_product_pcr_pool_id_fkey FOREIGN KEY (pcr_pool_id) REFERENCES viroserve.pcr_pool(pcr_pool_id);


--
-- Name: pcr_product pcr_product_pcr_template_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.pcr_product
    ADD CONSTRAINT pcr_product_pcr_template_id_fkey FOREIGN KEY (pcr_template_id) REFERENCES viroserve.pcr_template(pcr_template_id);


--
-- Name: pcr_product_primer pcr_product_primer_pcr_product_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.pcr_product_primer
    ADD CONSTRAINT pcr_product_primer_pcr_product_id_fkey FOREIGN KEY (pcr_product_id) REFERENCES viroserve.pcr_product(pcr_product_id);


--
-- Name: pcr_product_primer pcr_product_primer_primer_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.pcr_product_primer
    ADD CONSTRAINT pcr_product_primer_primer_id_fkey FOREIGN KEY (primer_id) REFERENCES viroserve.primer(primer_id);


--
-- Name: pcr_product pcr_product_protocol_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.pcr_product
    ADD CONSTRAINT pcr_product_protocol_id_fkey FOREIGN KEY (protocol_id) REFERENCES viroserve.protocol(protocol_id);


--
-- Name: pcr_product pcr_product_scientist_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.pcr_product
    ADD CONSTRAINT pcr_product_scientist_id_fkey FOREIGN KEY (scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: pcr_template pcr_template_bisulfite_converted_dna_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.pcr_template
    ADD CONSTRAINT pcr_template_bisulfite_converted_dna_id_fkey FOREIGN KEY (bisulfite_converted_dna_id) REFERENCES viroserve.bisulfite_converted_dna(bisulfite_converted_dna_id);


--
-- Name: pcr_template pcr_template_extraction_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.pcr_template
    ADD CONSTRAINT pcr_template_extraction_id_fkey FOREIGN KEY (extraction_id) REFERENCES viroserve.extraction(extraction_id);


--
-- Name: pcr_template pcr_template_pcr_product_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.pcr_template
    ADD CONSTRAINT pcr_template_pcr_product_id_fkey FOREIGN KEY (pcr_product_id) REFERENCES viroserve.pcr_product(pcr_product_id);


--
-- Name: pcr_template pcr_template_rt_product_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.pcr_template
    ADD CONSTRAINT pcr_template_rt_product_id_fkey FOREIGN KEY (rt_product_id) REFERENCES viroserve.rt_product(rt_product_id);


--
-- Name: pcr_template pcr_template_sample_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.pcr_template
    ADD CONSTRAINT pcr_template_sample_id_fkey FOREIGN KEY (sample_id) REFERENCES viroserve.sample(sample_id);


--
-- Name: pcr_template pcr_template_scientist_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.pcr_template
    ADD CONSTRAINT pcr_template_scientist_id_fkey FOREIGN KEY (scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: pcr_template pcr_template_unit_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.pcr_template
    ADD CONSTRAINT pcr_template_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES viroserve.unit(unit_id);


--
-- Name: primer primer_organism_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.primer
    ADD CONSTRAINT primer_organism_id_fkey FOREIGN KEY (organism_id) REFERENCES viroserve.organism(organism_id);


--
-- Name: primer_position primer_position_primer_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.primer_position
    ADD CONSTRAINT primer_position_primer_id_fkey FOREIGN KEY (primer_id) REFERENCES viroserve.primer(primer_id);


--
-- Name: project_materials project_materials_desig_scientist_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.project_materials
    ADD CONSTRAINT project_materials_desig_scientist_id_fkey FOREIGN KEY (desig_scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: project_materials project_materials_project_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.project_materials
    ADD CONSTRAINT project_materials_project_id_fkey FOREIGN KEY (project_id) REFERENCES viroserve.project(project_id);


--
-- Name: project_materials project_materials_sample_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.project_materials
    ADD CONSTRAINT project_materials_sample_id_fkey FOREIGN KEY (sample_id) REFERENCES viroserve.sample(sample_id);


--
-- Name: project project_orig_scientist_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.project
    ADD CONSTRAINT project_orig_scientist_id_fkey FOREIGN KEY (orig_scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: protocol protocol_protocol_type_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.protocol
    ADD CONSTRAINT protocol_protocol_type_id_fkey FOREIGN KEY (protocol_type_id) REFERENCES viroserve.protocol_type(protocol_type_id);


--
-- Name: rt_primer rt_primer_primer_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.rt_primer
    ADD CONSTRAINT rt_primer_primer_id_fkey FOREIGN KEY (primer_id) REFERENCES viroserve.primer(primer_id);


--
-- Name: rt_primer rt_primer_rt_product_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.rt_primer
    ADD CONSTRAINT rt_primer_rt_product_id_fkey FOREIGN KEY (rt_product_id) REFERENCES viroserve.rt_product(rt_product_id);


--
-- Name: rt_product rt_product_enzyme_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.rt_product
    ADD CONSTRAINT rt_product_enzyme_id_fkey FOREIGN KEY (enzyme_id) REFERENCES viroserve.enzyme(enzyme_id);


--
-- Name: rt_product rt_product_extraction_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.rt_product
    ADD CONSTRAINT rt_product_extraction_id_fkey FOREIGN KEY (extraction_id) REFERENCES viroserve.extraction(extraction_id);


--
-- Name: copy_number rt_product_fk; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.copy_number
    ADD CONSTRAINT rt_product_fk FOREIGN KEY (rt_product_id) REFERENCES viroserve.rt_product(rt_product_id);


--
-- Name: rt_product rt_product_protocol_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.rt_product
    ADD CONSTRAINT rt_product_protocol_id_fkey FOREIGN KEY (protocol_id) REFERENCES viroserve.protocol(protocol_id);


--
-- Name: rt_product rt_product_scientist_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.rt_product
    ADD CONSTRAINT rt_product_scientist_id_fkey FOREIGN KEY (scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: sample sample_derivation_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.sample
    ADD CONSTRAINT sample_derivation_id_fkey FOREIGN KEY (derivation_id) REFERENCES delta.derivation(derivation_id);


--
-- Name: sample sample_sample_type_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.sample
    ADD CONSTRAINT sample_sample_type_id_fkey FOREIGN KEY (sample_type_id) REFERENCES viroserve.sample_type(sample_type_id);


--
-- Name: sample sample_tissue_type_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.sample
    ADD CONSTRAINT sample_tissue_type_id_fkey FOREIGN KEY (tissue_type_id) REFERENCES viroserve.tissue_type(tissue_type_id);


--
-- Name: sample sample_visit_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.sample
    ADD CONSTRAINT sample_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES viroserve.visit(visit_id);


--
-- Name: copy_number scientist_fk; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.copy_number
    ADD CONSTRAINT scientist_fk FOREIGN KEY (scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: scientist_group scientist_group_scientist_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.scientist_group
    ADD CONSTRAINT scientist_group_scientist_id_fkey FOREIGN KEY (creating_scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: scientist_scientist_group scientist_scientist_group_add_scientist_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.scientist_scientist_group
    ADD CONSTRAINT scientist_scientist_group_add_scientist_id_fkey FOREIGN KEY (creating_scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: scientist_scientist_group scientist_scientist_group_scientist_group_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.scientist_scientist_group
    ADD CONSTRAINT scientist_scientist_group_scientist_group_id_fkey FOREIGN KEY (scientist_group_id) REFERENCES viroserve.scientist_group(scientist_group_id);


--
-- Name: scientist_scientist_group scientist_scientist_group_scientist_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.scientist_scientist_group
    ADD CONSTRAINT scientist_scientist_group_scientist_id_fkey FOREIGN KEY (scientist_id) REFERENCES viroserve.scientist(scientist_id);


--
-- Name: visit visit_patient_id_fkey; Type: FK CONSTRAINT; Schema: viroserve; Owner: :owner
--

ALTER TABLE ONLY viroserve.visit
    ADD CONSTRAINT visit_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES viroserve.patient(patient_id);


--
-- Name: SCHEMA delta; Type: ACL; Schema: -; Owner: :owner
--

REVOKE ALL ON SCHEMA delta FROM PUBLIC;
REVOKE ALL ON SCHEMA delta FROM :owner;
GRANT ALL ON SCHEMA delta TO :owner;
GRANT USAGE ON SCHEMA delta TO :ro_user;
GRANT USAGE ON SCHEMA delta TO :rw_user;


--
-- Name: SCHEMA epitope; Type: ACL; Schema: -; Owner: :owner
--

REVOKE ALL ON SCHEMA epitope FROM PUBLIC;
REVOKE ALL ON SCHEMA epitope FROM :owner;
GRANT ALL ON SCHEMA epitope TO :owner;
GRANT USAGE ON SCHEMA epitope TO :ro_user;
GRANT USAGE ON SCHEMA epitope TO :rw_user;


--
-- Name: SCHEMA freezer; Type: ACL; Schema: -; Owner: :owner
--

REVOKE ALL ON SCHEMA freezer FROM PUBLIC;
REVOKE ALL ON SCHEMA freezer FROM :owner;
GRANT ALL ON SCHEMA freezer TO :owner;
GRANT USAGE ON SCHEMA freezer TO :ro_user;
GRANT USAGE ON SCHEMA freezer TO :rw_user;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO :owner;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- Name: SCHEMA viroserve; Type: ACL; Schema: -; Owner: :owner
--

REVOKE ALL ON SCHEMA viroserve FROM PUBLIC;
REVOKE ALL ON SCHEMA viroserve FROM :owner;
GRANT ALL ON SCHEMA viroserve TO :owner;
GRANT USAGE ON SCHEMA viroserve TO :ro_user;
GRANT USAGE ON SCHEMA viroserve TO :rw_user;
GRANT USAGE ON SCHEMA viroserve TO postgres;


--
-- Name: TYPE hla_genotype_ambiguity_code; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TYPE viroserve.hla_genotype_ambiguity_code FROM PUBLIC;
REVOKE ALL ON TYPE viroserve.hla_genotype_ambiguity_code FROM :owner;
GRANT ALL ON TYPE viroserve.hla_genotype_ambiguity_code TO PUBLIC;


--
-- Name: TYPE na_type; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TYPE viroserve.na_type FROM PUBLIC;
REVOKE ALL ON TYPE viroserve.na_type FROM :owner;
GRANT ALL ON TYPE viroserve.na_type TO PUBLIC;


--
-- Name: TYPE patient_alias_type; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TYPE viroserve.patient_alias_type FROM PUBLIC;
REVOKE ALL ON TYPE viroserve.patient_alias_type FROM :owner;
GRANT ALL ON TYPE viroserve.patient_alias_type TO :owner;
GRANT ALL ON TYPE viroserve.patient_alias_type TO PUBLIC;
GRANT ALL ON TYPE viroserve.patient_alias_type TO :rw_user;


--
-- Name: TYPE scientist_role; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TYPE viroserve.scientist_role FROM PUBLIC;
REVOKE ALL ON TYPE viroserve.scientist_role FROM :owner;
GRANT ALL ON TYPE viroserve.scientist_role TO PUBLIC;


--
-- Name: FUNCTION refresh_distinct_sample_search(); Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON FUNCTION viroserve.refresh_distinct_sample_search() FROM PUBLIC;
REVOKE ALL ON FUNCTION viroserve.refresh_distinct_sample_search() FROM :owner;
GRANT ALL ON FUNCTION viroserve.refresh_distinct_sample_search() TO :owner;
GRANT ALL ON FUNCTION viroserve.refresh_distinct_sample_search() TO :rw_user;


--
-- Name: FUNCTION refresh_project_material_scientist_progress(); Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON FUNCTION viroserve.refresh_project_material_scientist_progress() FROM PUBLIC;
REVOKE ALL ON FUNCTION viroserve.refresh_project_material_scientist_progress() FROM :owner;
GRANT ALL ON FUNCTION viroserve.refresh_project_material_scientist_progress() TO :owner;
GRANT ALL ON FUNCTION viroserve.refresh_project_material_scientist_progress() TO :rw_user;


--
-- Name: FUNCTION refresh_sequence_search(); Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON FUNCTION viroserve.refresh_sequence_search() FROM PUBLIC;
REVOKE ALL ON FUNCTION viroserve.refresh_sequence_search() FROM :owner;
GRANT ALL ON FUNCTION viroserve.refresh_sequence_search() TO :owner;
GRANT ALL ON FUNCTION viroserve.refresh_sequence_search() TO :rw_user;


--
-- Name: TABLE derivation; Type: ACL; Schema: delta; Owner: :owner
--

REVOKE ALL ON TABLE delta.derivation FROM PUBLIC;
REVOKE ALL ON TABLE delta.derivation FROM :owner;
GRANT ALL ON TABLE delta.derivation TO :owner;
GRANT SELECT ON TABLE delta.derivation TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE delta.derivation TO :rw_user;


--
-- Name: SEQUENCE derivation_derivation_id_seq; Type: ACL; Schema: delta; Owner: :owner
--

REVOKE ALL ON SEQUENCE delta.derivation_derivation_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE delta.derivation_derivation_id_seq FROM :owner;
GRANT ALL ON SEQUENCE delta.derivation_derivation_id_seq TO :owner;
GRANT ALL ON SEQUENCE delta.derivation_derivation_id_seq TO :rw_user;


--
-- Name: TABLE protocol; Type: ACL; Schema: delta; Owner: :owner
--

REVOKE ALL ON TABLE delta.protocol FROM PUBLIC;
REVOKE ALL ON TABLE delta.protocol FROM :owner;
GRANT ALL ON TABLE delta.protocol TO :owner;
GRANT SELECT ON TABLE delta.protocol TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE delta.protocol TO :rw_user;


--
-- Name: TABLE protocol_output; Type: ACL; Schema: delta; Owner: :owner
--

REVOKE ALL ON TABLE delta.protocol_output FROM PUBLIC;
REVOKE ALL ON TABLE delta.protocol_output FROM :owner;
GRANT ALL ON TABLE delta.protocol_output TO :owner;
GRANT SELECT ON TABLE delta.protocol_output TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE delta.protocol_output TO :rw_user;


--
-- Name: SEQUENCE protocol_protocol_id_seq; Type: ACL; Schema: delta; Owner: :owner
--

REVOKE ALL ON SEQUENCE delta.protocol_protocol_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE delta.protocol_protocol_id_seq FROM :owner;
GRANT ALL ON SEQUENCE delta.protocol_protocol_id_seq TO :owner;
GRANT ALL ON SEQUENCE delta.protocol_protocol_id_seq TO :rw_user;


--
-- Name: SEQUENCE blcl_blcl_id_seq; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON SEQUENCE epitope.blcl_blcl_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE epitope.blcl_blcl_id_seq FROM :owner;
GRANT ALL ON SEQUENCE epitope.blcl_blcl_id_seq TO :owner;
GRANT SELECT ON SEQUENCE epitope.blcl_blcl_id_seq TO :ro_user;
GRANT ALL ON SEQUENCE epitope.blcl_blcl_id_seq TO :rw_user;


--
-- Name: TABLE blcl; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON TABLE epitope.blcl FROM PUBLIC;
REVOKE ALL ON TABLE epitope.blcl FROM :owner;
GRANT ALL ON TABLE epitope.blcl TO :owner;
GRANT SELECT ON TABLE epitope.blcl TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE epitope.blcl TO :rw_user;


--
-- Name: SEQUENCE epitope_epit_id_seq; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON SEQUENCE epitope.epitope_epit_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE epitope.epitope_epit_id_seq FROM :owner;
GRANT ALL ON SEQUENCE epitope.epitope_epit_id_seq TO :owner;
GRANT SELECT ON SEQUENCE epitope.epitope_epit_id_seq TO :ro_user;
GRANT ALL ON SEQUENCE epitope.epitope_epit_id_seq TO :rw_user;


--
-- Name: TABLE epitope; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON TABLE epitope.epitope FROM PUBLIC;
REVOKE ALL ON TABLE epitope.epitope FROM :owner;
GRANT ALL ON TABLE epitope.epitope TO :owner;
GRANT SELECT ON TABLE epitope.epitope TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE epitope.epitope TO :rw_user;


--
-- Name: TABLE epitope_mutant; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON TABLE epitope.epitope_mutant FROM PUBLIC;
REVOKE ALL ON TABLE epitope.epitope_mutant FROM :owner;
GRANT ALL ON TABLE epitope.epitope_mutant TO :owner;
GRANT SELECT ON TABLE epitope.epitope_mutant TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE epitope.epitope_mutant TO :rw_user;


--
-- Name: TABLE epitope_sequence; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON TABLE epitope.epitope_sequence FROM PUBLIC;
REVOKE ALL ON TABLE epitope.epitope_sequence FROM :owner;
GRANT ALL ON TABLE epitope.epitope_sequence TO :owner;
GRANT SELECT ON TABLE epitope.epitope_sequence TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE epitope.epitope_sequence TO :rw_user;


--
-- Name: SEQUENCE epitope_source_source_id_seq; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON SEQUENCE epitope.epitope_source_source_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE epitope.epitope_source_source_id_seq FROM :owner;
GRANT ALL ON SEQUENCE epitope.epitope_source_source_id_seq TO :owner;
GRANT ALL ON SEQUENCE epitope.epitope_source_source_id_seq TO :rw_user;


--
-- Name: TABLE epitope_source; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON TABLE epitope.epitope_source FROM PUBLIC;
REVOKE ALL ON TABLE epitope.epitope_source FROM :owner;
GRANT ALL ON TABLE epitope.epitope_source TO :owner;
GRANT SELECT ON TABLE epitope.epitope_source TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE epitope.epitope_source TO :rw_user;


--
-- Name: SEQUENCE experiment_exp_id_seq; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON SEQUENCE epitope.experiment_exp_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE epitope.experiment_exp_id_seq FROM :owner;
GRANT ALL ON SEQUENCE epitope.experiment_exp_id_seq TO :owner;
GRANT SELECT ON SEQUENCE epitope.experiment_exp_id_seq TO :ro_user;
GRANT ALL ON SEQUENCE epitope.experiment_exp_id_seq TO :rw_user;


--
-- Name: TABLE experiment; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON TABLE epitope.experiment FROM PUBLIC;
REVOKE ALL ON TABLE epitope.experiment FROM :owner;
GRANT ALL ON TABLE epitope.experiment TO :owner;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE epitope.experiment TO :rw_user;
GRANT SELECT ON TABLE epitope.experiment TO :ro_user;


--
-- Name: SEQUENCE gene_gene_id_seq; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON SEQUENCE epitope.gene_gene_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE epitope.gene_gene_id_seq FROM :owner;
GRANT ALL ON SEQUENCE epitope.gene_gene_id_seq TO :owner;
GRANT SELECT ON SEQUENCE epitope.gene_gene_id_seq TO :ro_user;
GRANT ALL ON SEQUENCE epitope.gene_gene_id_seq TO :rw_user;


--
-- Name: TABLE gene; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON TABLE epitope.gene FROM PUBLIC;
REVOKE ALL ON TABLE epitope.gene FROM :owner;
GRANT ALL ON TABLE epitope.gene TO :owner;
GRANT SELECT ON TABLE epitope.gene TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE epitope.gene TO :rw_user;


--
-- Name: TABLE hla; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON TABLE epitope.hla FROM PUBLIC;
REVOKE ALL ON TABLE epitope.hla FROM :owner;
GRANT ALL ON TABLE epitope.hla TO :owner;
GRANT SELECT ON TABLE epitope.hla TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE epitope.hla TO :rw_user;


--
-- Name: TABLE hla_pept; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON TABLE epitope.hla_pept FROM PUBLIC;
REVOKE ALL ON TABLE epitope.hla_pept FROM :owner;
GRANT ALL ON TABLE epitope.hla_pept TO :owner;
GRANT SELECT ON TABLE epitope.hla_pept TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE epitope.hla_pept TO :rw_user;


--
-- Name: SEQUENCE measure_id_seq; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON SEQUENCE epitope.measure_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE epitope.measure_id_seq FROM :owner;
GRANT ALL ON SEQUENCE epitope.measure_id_seq TO :owner;
GRANT SELECT ON SEQUENCE epitope.measure_id_seq TO :ro_user;
GRANT ALL ON SEQUENCE epitope.measure_id_seq TO :rw_user;


--
-- Name: TABLE hla_response; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON TABLE epitope.hla_response FROM PUBLIC;
REVOKE ALL ON TABLE epitope.hla_response FROM :owner;
GRANT ALL ON TABLE epitope.hla_response TO :owner;
GRANT SELECT ON TABLE epitope.hla_response TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE epitope.hla_response TO :rw_user;


--
-- Name: TABLE pept_response; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON TABLE epitope.pept_response FROM PUBLIC;
REVOKE ALL ON TABLE epitope.pept_response FROM :owner;
GRANT ALL ON TABLE epitope.pept_response TO :owner;
GRANT SELECT ON TABLE epitope.pept_response TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE epitope.pept_response TO :rw_user;


--
-- Name: SEQUENCE reading_reading_id_seq; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON SEQUENCE epitope.reading_reading_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE epitope.reading_reading_id_seq FROM :owner;
GRANT ALL ON SEQUENCE epitope.reading_reading_id_seq TO :owner;
GRANT SELECT ON SEQUENCE epitope.reading_reading_id_seq TO :ro_user;
GRANT ALL ON SEQUENCE epitope.reading_reading_id_seq TO :rw_user;


--
-- Name: TABLE reading; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON TABLE epitope.reading FROM PUBLIC;
REVOKE ALL ON TABLE epitope.reading FROM :owner;
GRANT ALL ON TABLE epitope.reading TO :owner;
GRANT SELECT ON TABLE epitope.reading TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE epitope.reading TO :rw_user;


--
-- Name: TABLE hla_response_avg; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON TABLE epitope.hla_response_avg FROM PUBLIC;
REVOKE ALL ON TABLE epitope.hla_response_avg FROM :owner;
GRANT ALL ON TABLE epitope.hla_response_avg TO :owner;
GRANT SELECT ON TABLE epitope.hla_response_avg TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE epitope.hla_response_avg TO :rw_user;


--
-- Name: TABLE pept_response_avg; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON TABLE epitope.pept_response_avg FROM PUBLIC;
REVOKE ALL ON TABLE epitope.pept_response_avg FROM :owner;
GRANT ALL ON TABLE epitope.pept_response_avg TO :owner;
GRANT SELECT ON TABLE epitope.pept_response_avg TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE epitope.pept_response_avg TO :rw_user;


--
-- Name: SEQUENCE vv_uid; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.vv_uid FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.vv_uid FROM :owner;
GRANT ALL ON SEQUENCE viroserve.vv_uid TO :owner;
GRANT SELECT,UPDATE ON SEQUENCE viroserve.vv_uid TO :ro_user;
GRANT ALL ON SEQUENCE viroserve.vv_uid TO :rw_user;


--
-- Name: TABLE sample; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.sample FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.sample FROM :owner;
GRANT ALL ON TABLE viroserve.sample TO :owner;
GRANT SELECT ON TABLE viroserve.sample TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.sample TO :rw_user;


--
-- Name: TABLE tissue_type; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.tissue_type FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.tissue_type FROM :owner;
GRANT ALL ON TABLE viroserve.tissue_type TO :owner;
GRANT SELECT ON TABLE viroserve.tissue_type TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.tissue_type TO :rw_user;


--
-- Name: TABLE visit; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.visit FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.visit FROM :owner;
GRANT ALL ON TABLE viroserve.visit TO :owner;
GRANT SELECT ON TABLE viroserve.visit TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.visit TO :rw_user;


--
-- Name: TABLE sample; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON TABLE epitope.sample FROM PUBLIC;
REVOKE ALL ON TABLE epitope.sample FROM :owner;
GRANT ALL ON TABLE epitope.sample TO :owner;
GRANT SELECT ON TABLE epitope.sample TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE epitope.sample TO :rw_user;


--
-- Name: TABLE hla_response_corravg; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON TABLE epitope.hla_response_corravg FROM PUBLIC;
REVOKE ALL ON TABLE epitope.hla_response_corravg FROM :owner;
GRANT ALL ON TABLE epitope.hla_response_corravg TO :owner;
GRANT SELECT ON TABLE epitope.hla_response_corravg TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE epitope.hla_response_corravg TO :rw_user;


--
-- Name: TABLE measurement; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON TABLE epitope.measurement FROM PUBLIC;
REVOKE ALL ON TABLE epitope.measurement FROM :owner;
GRANT ALL ON TABLE epitope.measurement TO :owner;
GRANT SELECT ON TABLE epitope.measurement TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE epitope.measurement TO :rw_user;


--
-- Name: SEQUENCE mutant_mutant_id_seq; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON SEQUENCE epitope.mutant_mutant_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE epitope.mutant_mutant_id_seq FROM :owner;
GRANT ALL ON SEQUENCE epitope.mutant_mutant_id_seq TO :owner;
GRANT SELECT ON SEQUENCE epitope.mutant_mutant_id_seq TO :ro_user;
GRANT ALL ON SEQUENCE epitope.mutant_mutant_id_seq TO :rw_user;


--
-- Name: TABLE mutant; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON TABLE epitope.mutant FROM PUBLIC;
REVOKE ALL ON TABLE epitope.mutant FROM :owner;
GRANT ALL ON TABLE epitope.mutant TO :owner;
GRANT SELECT ON TABLE epitope.mutant TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE epitope.mutant TO :rw_user;


--
-- Name: SEQUENCE origin_origin_id_seq; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON SEQUENCE epitope.origin_origin_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE epitope.origin_origin_id_seq FROM :owner;
GRANT ALL ON SEQUENCE epitope.origin_origin_id_seq TO :owner;
GRANT SELECT ON SEQUENCE epitope.origin_origin_id_seq TO :ro_user;
GRANT ALL ON SEQUENCE epitope.origin_origin_id_seq TO :rw_user;


--
-- Name: TABLE origin; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON TABLE epitope.origin FROM PUBLIC;
REVOKE ALL ON TABLE epitope.origin FROM :owner;
GRANT ALL ON TABLE epitope.origin TO :owner;
GRANT SELECT ON TABLE epitope.origin TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE epitope.origin TO :rw_user;


--
-- Name: TABLE origin_peptide; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON TABLE epitope.origin_peptide FROM PUBLIC;
REVOKE ALL ON TABLE epitope.origin_peptide FROM :owner;
GRANT ALL ON TABLE epitope.origin_peptide TO :owner;
GRANT SELECT ON TABLE epitope.origin_peptide TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE epitope.origin_peptide TO :rw_user;


--
-- Name: TABLE pept_response_corravg; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON TABLE epitope.pept_response_corravg FROM PUBLIC;
REVOKE ALL ON TABLE epitope.pept_response_corravg FROM :owner;
GRANT ALL ON TABLE epitope.pept_response_corravg TO :owner;
GRANT SELECT ON TABLE epitope.pept_response_corravg TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE epitope.pept_response_corravg TO :rw_user;


--
-- Name: SEQUENCE peptide_pept_id_seq; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON SEQUENCE epitope.peptide_pept_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE epitope.peptide_pept_id_seq FROM :owner;
GRANT ALL ON SEQUENCE epitope.peptide_pept_id_seq TO :owner;
GRANT SELECT ON SEQUENCE epitope.peptide_pept_id_seq TO :ro_user;
GRANT ALL ON SEQUENCE epitope.peptide_pept_id_seq TO :rw_user;


--
-- Name: TABLE peptide; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON TABLE epitope.peptide FROM PUBLIC;
REVOKE ALL ON TABLE epitope.peptide FROM :owner;
GRANT ALL ON TABLE epitope.peptide TO :owner;
GRANT SELECT ON TABLE epitope.peptide TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE epitope.peptide TO :rw_user;


--
-- Name: SEQUENCE pool_pool_id_seq; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON SEQUENCE epitope.pool_pool_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE epitope.pool_pool_id_seq FROM :owner;
GRANT ALL ON SEQUENCE epitope.pool_pool_id_seq TO :owner;
GRANT SELECT ON SEQUENCE epitope.pool_pool_id_seq TO :ro_user;
GRANT ALL ON SEQUENCE epitope.pool_pool_id_seq TO :rw_user;


--
-- Name: TABLE pool; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON TABLE epitope.pool FROM PUBLIC;
REVOKE ALL ON TABLE epitope.pool FROM :owner;
GRANT ALL ON TABLE epitope.pool TO :owner;
GRANT SELECT ON TABLE epitope.pool TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE epitope.pool TO :rw_user;


--
-- Name: TABLE pool_pept; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON TABLE epitope.pool_pept FROM PUBLIC;
REVOKE ALL ON TABLE epitope.pool_pept FROM :owner;
GRANT ALL ON TABLE epitope.pool_pept TO :owner;
GRANT SELECT ON TABLE epitope.pool_pept TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE epitope.pool_pept TO :rw_user;


--
-- Name: TABLE pool_response; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON TABLE epitope.pool_response FROM PUBLIC;
REVOKE ALL ON TABLE epitope.pool_response FROM :owner;
GRANT ALL ON TABLE epitope.pool_response TO :owner;
GRANT SELECT ON TABLE epitope.pool_response TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE epitope.pool_response TO :rw_user;


--
-- Name: TABLE pool_response_avg; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON TABLE epitope.pool_response_avg FROM PUBLIC;
REVOKE ALL ON TABLE epitope.pool_response_avg FROM :owner;
GRANT ALL ON TABLE epitope.pool_response_avg TO :owner;
GRANT SELECT ON TABLE epitope.pool_response_avg TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE epitope.pool_response_avg TO :rw_user;


--
-- Name: TABLE pool_response_corravg; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON TABLE epitope.pool_response_corravg FROM PUBLIC;
REVOKE ALL ON TABLE epitope.pool_response_corravg FROM :owner;
GRANT ALL ON TABLE epitope.pool_response_corravg TO :owner;
GRANT SELECT ON TABLE epitope.pool_response_corravg TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE epitope.pool_response_corravg TO :rw_user;


--
-- Name: TABLE test_patient; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON TABLE epitope.test_patient FROM PUBLIC;
REVOKE ALL ON TABLE epitope.test_patient FROM :owner;
GRANT ALL ON TABLE epitope.test_patient TO :owner;
GRANT SELECT ON TABLE epitope.test_patient TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE epitope.test_patient TO :rw_user;


--
-- Name: TABLE titration; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON TABLE epitope.titration FROM PUBLIC;
REVOKE ALL ON TABLE epitope.titration FROM :owner;
GRANT ALL ON TABLE epitope.titration TO :owner;
GRANT SELECT ON TABLE epitope.titration TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE epitope.titration TO :rw_user;


--
-- Name: TABLE titration_avg; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON TABLE epitope.titration_avg FROM PUBLIC;
REVOKE ALL ON TABLE epitope.titration_avg FROM :owner;
GRANT ALL ON TABLE epitope.titration_avg TO :owner;
GRANT SELECT ON TABLE epitope.titration_avg TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE epitope.titration_avg TO :rw_user;


--
-- Name: SEQUENCE titration_conc_conc_id_seq; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON SEQUENCE epitope.titration_conc_conc_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE epitope.titration_conc_conc_id_seq FROM :owner;
GRANT ALL ON SEQUENCE epitope.titration_conc_conc_id_seq TO :owner;
GRANT SELECT ON SEQUENCE epitope.titration_conc_conc_id_seq TO :ro_user;
GRANT ALL ON SEQUENCE epitope.titration_conc_conc_id_seq TO :rw_user;


--
-- Name: TABLE titration_conc; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON TABLE epitope.titration_conc FROM PUBLIC;
REVOKE ALL ON TABLE epitope.titration_conc FROM :owner;
GRANT ALL ON TABLE epitope.titration_conc TO :owner;
GRANT SELECT ON TABLE epitope.titration_conc TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE epitope.titration_conc TO :rw_user;


--
-- Name: TABLE titration_corravg; Type: ACL; Schema: epitope; Owner: :owner
--

REVOKE ALL ON TABLE epitope.titration_corravg FROM PUBLIC;
REVOKE ALL ON TABLE epitope.titration_corravg FROM :owner;
GRANT ALL ON TABLE epitope.titration_corravg TO :owner;
GRANT SELECT ON TABLE epitope.titration_corravg TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE epitope.titration_corravg TO :rw_user;


--
-- Name: TABLE box; Type: ACL; Schema: freezer; Owner: :owner
--

REVOKE ALL ON TABLE freezer.box FROM PUBLIC;
REVOKE ALL ON TABLE freezer.box FROM :owner;
GRANT ALL ON TABLE freezer.box TO :owner;
GRANT SELECT ON TABLE freezer.box TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE freezer.box TO :rw_user;


--
-- Name: SEQUENCE box_box_id_seq; Type: ACL; Schema: freezer; Owner: :owner
--

REVOKE ALL ON SEQUENCE freezer.box_box_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE freezer.box_box_id_seq FROM :owner;
GRANT ALL ON SEQUENCE freezer.box_box_id_seq TO :owner;
GRANT SELECT ON SEQUENCE freezer.box_box_id_seq TO :ro_user;
GRANT ALL ON SEQUENCE freezer.box_box_id_seq TO :rw_user;


--
-- Name: TABLE box_pos; Type: ACL; Schema: freezer; Owner: :owner
--

REVOKE ALL ON TABLE freezer.box_pos FROM PUBLIC;
REVOKE ALL ON TABLE freezer.box_pos FROM :owner;
GRANT ALL ON TABLE freezer.box_pos TO :owner;
GRANT SELECT ON TABLE freezer.box_pos TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE freezer.box_pos TO :rw_user;


--
-- Name: SEQUENCE box_pos_box_pos_id_seq; Type: ACL; Schema: freezer; Owner: :owner
--

REVOKE ALL ON SEQUENCE freezer.box_pos_box_pos_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE freezer.box_pos_box_pos_id_seq FROM :owner;
GRANT ALL ON SEQUENCE freezer.box_pos_box_pos_id_seq TO :owner;
GRANT SELECT ON SEQUENCE freezer.box_pos_box_pos_id_seq TO :ro_user;
GRANT ALL ON SEQUENCE freezer.box_pos_box_pos_id_seq TO :rw_user;


--
-- Name: TABLE freezer; Type: ACL; Schema: freezer; Owner: :owner
--

REVOKE ALL ON TABLE freezer.freezer FROM PUBLIC;
REVOKE ALL ON TABLE freezer.freezer FROM :owner;
GRANT ALL ON TABLE freezer.freezer TO :owner;
GRANT SELECT ON TABLE freezer.freezer TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE freezer.freezer TO :rw_user;


--
-- Name: SEQUENCE freezer_freezer_id_seq; Type: ACL; Schema: freezer; Owner: :owner
--

REVOKE ALL ON SEQUENCE freezer.freezer_freezer_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE freezer.freezer_freezer_id_seq FROM :owner;
GRANT ALL ON SEQUENCE freezer.freezer_freezer_id_seq TO :owner;
GRANT SELECT ON SEQUENCE freezer.freezer_freezer_id_seq TO :ro_user;
GRANT ALL ON SEQUENCE freezer.freezer_freezer_id_seq TO :rw_user;


--
-- Name: TABLE rack; Type: ACL; Schema: freezer; Owner: :owner
--

REVOKE ALL ON TABLE freezer.rack FROM PUBLIC;
REVOKE ALL ON TABLE freezer.rack FROM :owner;
GRANT ALL ON TABLE freezer.rack TO :owner;
GRANT SELECT ON TABLE freezer.rack TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE freezer.rack TO :rw_user;


--
-- Name: SEQUENCE rack_rack_id_seq; Type: ACL; Schema: freezer; Owner: :owner
--

REVOKE ALL ON SEQUENCE freezer.rack_rack_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE freezer.rack_rack_id_seq FROM :owner;
GRANT ALL ON SEQUENCE freezer.rack_rack_id_seq TO :owner;
GRANT SELECT ON SEQUENCE freezer.rack_rack_id_seq TO :ro_user;
GRANT ALL ON SEQUENCE freezer.rack_rack_id_seq TO :rw_user;


--
-- Name: TABLE hla_genotype; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.hla_genotype FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.hla_genotype FROM :owner;
GRANT ALL ON TABLE viroserve.hla_genotype TO :owner;
GRANT SELECT ON TABLE viroserve.hla_genotype TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.hla_genotype TO :rw_user;


--
-- Name: TABLE patient_hla_genotype; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.patient_hla_genotype FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.patient_hla_genotype FROM :owner;
GRANT ALL ON TABLE viroserve.patient_hla_genotype TO :owner;
GRANT SELECT ON TABLE viroserve.patient_hla_genotype TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.patient_hla_genotype TO :rw_user;


--
-- Name: TABLE _vhla_genotype; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve._vhla_genotype FROM PUBLIC;
REVOKE ALL ON TABLE viroserve._vhla_genotype FROM :owner;
GRANT ALL ON TABLE viroserve._vhla_genotype TO :owner;
GRANT SELECT ON TABLE viroserve._vhla_genotype TO :ro_user;
GRANT SELECT ON TABLE viroserve._vhla_genotype TO :rw_user;


--
-- Name: TABLE lab_result_cat; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.lab_result_cat FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.lab_result_cat FROM :owner;
GRANT ALL ON TABLE viroserve.lab_result_cat TO :owner;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.lab_result_cat TO :rw_user;
GRANT SELECT ON TABLE viroserve.lab_result_cat TO :ro_user;


--
-- Name: TABLE lab_result_cat_type; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.lab_result_cat_type FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.lab_result_cat_type FROM :owner;
GRANT ALL ON TABLE viroserve.lab_result_cat_type TO :owner;
GRANT SELECT ON TABLE viroserve.lab_result_cat_type TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.lab_result_cat_type TO :rw_user;


--
-- Name: TABLE lab_result_cat_value; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.lab_result_cat_value FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.lab_result_cat_value FROM :owner;
GRANT ALL ON TABLE viroserve.lab_result_cat_value TO :owner;
GRANT SELECT ON TABLE viroserve.lab_result_cat_value TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.lab_result_cat_value TO :rw_user;


--
-- Name: TABLE _vlab_result_cat; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve._vlab_result_cat FROM PUBLIC;
REVOKE ALL ON TABLE viroserve._vlab_result_cat FROM :owner;
GRANT ALL ON TABLE viroserve._vlab_result_cat TO :owner;
GRANT SELECT ON TABLE viroserve._vlab_result_cat TO :ro_user;
GRANT SELECT ON TABLE viroserve._vlab_result_cat TO :rw_user;


--
-- Name: TABLE lab_result_num; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.lab_result_num FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.lab_result_num FROM :owner;
GRANT ALL ON TABLE viroserve.lab_result_num TO :owner;
GRANT SELECT ON TABLE viroserve.lab_result_num TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.lab_result_num TO :rw_user;


--
-- Name: TABLE lab_result_num_type; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.lab_result_num_type FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.lab_result_num_type FROM :owner;
GRANT ALL ON TABLE viroserve.lab_result_num_type TO :owner;
GRANT SELECT ON TABLE viroserve.lab_result_num_type TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.lab_result_num_type TO :rw_user;


--
-- Name: TABLE unit; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.unit FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.unit FROM :owner;
GRANT ALL ON TABLE viroserve.unit TO :owner;
GRANT SELECT ON TABLE viroserve.unit TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.unit TO :rw_user;


--
-- Name: TABLE _vlab_result_num; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve._vlab_result_num FROM PUBLIC;
REVOKE ALL ON TABLE viroserve._vlab_result_num FROM :owner;
GRANT ALL ON TABLE viroserve._vlab_result_num TO :owner;
GRANT SELECT ON TABLE viroserve._vlab_result_num TO :ro_user;
GRANT SELECT ON TABLE viroserve._vlab_result_num TO :rw_user;


--
-- Name: TABLE bisulfite_converted_dna; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.bisulfite_converted_dna FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.bisulfite_converted_dna FROM :owner;
GRANT ALL ON TABLE viroserve.bisulfite_converted_dna TO :owner;
GRANT SELECT ON TABLE viroserve.bisulfite_converted_dna TO :ro_user;
GRANT ALL ON TABLE viroserve.bisulfite_converted_dna TO :rw_user;


--
-- Name: TABLE extraction; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.extraction FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.extraction FROM :owner;
GRANT ALL ON TABLE viroserve.extraction TO :owner;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.extraction TO :rw_user;
GRANT SELECT ON TABLE viroserve.extraction TO :ro_user;


--
-- Name: TABLE pcr_product; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.pcr_product FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.pcr_product FROM :owner;
GRANT ALL ON TABLE viroserve.pcr_product TO :owner;
GRANT SELECT ON TABLE viroserve.pcr_product TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.pcr_product TO :rw_user;


--
-- Name: TABLE pcr_template; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.pcr_template FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.pcr_template FROM :owner;
GRANT ALL ON TABLE viroserve.pcr_template TO :owner;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.pcr_template TO :rw_user;
GRANT SELECT ON TABLE viroserve.pcr_template TO :ro_user;


--
-- Name: TABLE rt_product; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.rt_product FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.rt_product FROM :owner;
GRANT ALL ON TABLE viroserve.rt_product TO :owner;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.rt_product TO :rw_user;
GRANT SELECT ON TABLE viroserve.rt_product TO :ro_user;


--
-- Name: TABLE _vpatient_visit_sample_pcr; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve._vpatient_visit_sample_pcr FROM PUBLIC;
REVOKE ALL ON TABLE viroserve._vpatient_visit_sample_pcr FROM :owner;
GRANT ALL ON TABLE viroserve._vpatient_visit_sample_pcr TO :owner;
GRANT SELECT ON TABLE viroserve._vpatient_visit_sample_pcr TO :ro_user;
GRANT SELECT ON TABLE viroserve._vpatient_visit_sample_pcr TO :rw_user;


--
-- Name: TABLE additive; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.additive FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.additive FROM :owner;
GRANT ALL ON TABLE viroserve.additive TO :owner;
GRANT SELECT ON TABLE viroserve.additive TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.additive TO :rw_user;


--
-- Name: SEQUENCE additive_additive_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.additive_additive_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.additive_additive_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.additive_additive_id_seq TO :owner;
GRANT SELECT ON SEQUENCE viroserve.additive_additive_id_seq TO :ro_user;
GRANT ALL ON SEQUENCE viroserve.additive_additive_id_seq TO :rw_user;


--
-- Name: TABLE alignment; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.alignment FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.alignment FROM :owner;
GRANT ALL ON TABLE viroserve.alignment TO :owner;
GRANT SELECT ON TABLE viroserve.alignment TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.alignment TO :rw_user;


--
-- Name: SEQUENCE alignment_alignment_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.alignment_alignment_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.alignment_alignment_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.alignment_alignment_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.alignment_alignment_id_seq TO :rw_user;


--
-- Name: TABLE alignment_latest_revision; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.alignment_latest_revision FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.alignment_latest_revision FROM :owner;
GRANT ALL ON TABLE viroserve.alignment_latest_revision TO :owner;
GRANT SELECT ON TABLE viroserve.alignment_latest_revision TO :ro_user;
GRANT SELECT ON TABLE viroserve.alignment_latest_revision TO :rw_user;


--
-- Name: TABLE alignment_method; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.alignment_method FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.alignment_method FROM :owner;
GRANT ALL ON TABLE viroserve.alignment_method TO :owner;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.alignment_method TO :rw_user;


--
-- Name: SEQUENCE alignment_method_alignment_method_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.alignment_method_alignment_method_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.alignment_method_alignment_method_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.alignment_method_alignment_method_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.alignment_method_alignment_method_id_seq TO :rw_user;


--
-- Name: TABLE aliquot; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.aliquot FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.aliquot FROM :owner;
GRANT ALL ON TABLE viroserve.aliquot TO :owner;
GRANT SELECT ON TABLE viroserve.aliquot TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.aliquot TO :rw_user;


--
-- Name: SEQUENCE aliquot_aliquot_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.aliquot_aliquot_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.aliquot_aliquot_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.aliquot_aliquot_id_seq TO :owner;
GRANT SELECT ON SEQUENCE viroserve.aliquot_aliquot_id_seq TO :ro_user;
GRANT ALL ON SEQUENCE viroserve.aliquot_aliquot_id_seq TO :rw_user;


--
-- Name: TABLE arv_class; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.arv_class FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.arv_class FROM :owner;
GRANT ALL ON TABLE viroserve.arv_class TO :owner;
GRANT SELECT ON TABLE viroserve.arv_class TO :ro_user;
GRANT ALL ON TABLE viroserve.arv_class TO :rw_user;


--
-- Name: SEQUENCE arv_class_arv_class_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.arv_class_arv_class_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.arv_class_arv_class_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.arv_class_arv_class_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.arv_class_arv_class_id_seq TO :rw_user;


--
-- Name: SEQUENCE bisulfite_converted_dna_bisulfite_converted_dna_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.bisulfite_converted_dna_bisulfite_converted_dna_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.bisulfite_converted_dna_bisulfite_converted_dna_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.bisulfite_converted_dna_bisulfite_converted_dna_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.bisulfite_converted_dna_bisulfite_converted_dna_id_seq TO :rw_user;


--
-- Name: TABLE cell_count; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.cell_count FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.cell_count FROM :owner;
GRANT ALL ON TABLE viroserve.cell_count TO :owner;
GRANT SELECT ON TABLE viroserve.cell_count TO :ro_user;
GRANT SELECT ON TABLE viroserve.cell_count TO :rw_user;


--
-- Name: TABLE chromat; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.chromat FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.chromat FROM :owner;
GRANT ALL ON TABLE viroserve.chromat TO :owner;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.chromat TO :rw_user;
GRANT SELECT ON TABLE viroserve.chromat TO :ro_user;


--
-- Name: SEQUENCE chromat_chromat_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.chromat_chromat_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.chromat_chromat_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.chromat_chromat_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.chromat_chromat_id_seq TO :rw_user;


--
-- Name: TABLE chromat_na_sequence; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.chromat_na_sequence FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.chromat_na_sequence FROM :owner;
GRANT ALL ON TABLE viroserve.chromat_na_sequence TO :owner;
GRANT ALL ON TABLE viroserve.chromat_na_sequence TO :rw_user;
GRANT SELECT ON TABLE viroserve.chromat_na_sequence TO :ro_user;


--
-- Name: TABLE chromat_type; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.chromat_type FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.chromat_type FROM :owner;
GRANT ALL ON TABLE viroserve.chromat_type TO :owner;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.chromat_type TO :rw_user;
GRANT SELECT ON TABLE viroserve.chromat_type TO :ro_user;


--
-- Name: SEQUENCE chromat_type_chromat_type_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.chromat_type_chromat_type_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.chromat_type_chromat_type_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.chromat_type_chromat_type_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.chromat_type_chromat_type_id_seq TO :rw_user;


--
-- Name: TABLE clone; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.clone FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.clone FROM :owner;
GRANT ALL ON TABLE viroserve.clone TO :owner;
GRANT SELECT ON TABLE viroserve.clone TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.clone TO :rw_user;


--
-- Name: SEQUENCE clone_clone_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.clone_clone_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.clone_clone_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.clone_clone_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.clone_clone_id_seq TO :rw_user;


--
-- Name: SEQUENCE cohort_cohort_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.cohort_cohort_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.cohort_cohort_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.cohort_cohort_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.cohort_cohort_id_seq TO :rw_user;


--
-- Name: TABLE cohort; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.cohort FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.cohort FROM :owner;
GRANT ALL ON TABLE viroserve.cohort TO :owner;
GRANT SELECT ON TABLE viroserve.cohort TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.cohort TO :rw_user;


--
-- Name: TABLE infection; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.infection FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.infection FROM :owner;
GRANT ALL ON TABLE viroserve.infection TO :owner;
GRANT SELECT ON TABLE viroserve.infection TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.infection TO :rw_user;


--
-- Name: TABLE medication; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.medication FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.medication FROM :owner;
GRANT ALL ON TABLE viroserve.medication TO :owner;
GRANT SELECT ON TABLE viroserve.medication TO :ro_user;
GRANT ALL ON TABLE viroserve.medication TO :rw_user;


--
-- Name: TABLE patient; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.patient FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.patient FROM :owner;
GRANT ALL ON TABLE viroserve.patient TO :owner;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.patient TO :rw_user;
GRANT SELECT ON TABLE viroserve.patient TO :ro_user;


--
-- Name: TABLE patient_alias; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.patient_alias FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.patient_alias FROM :owner;
GRANT ALL ON TABLE viroserve.patient_alias TO :owner;
GRANT SELECT ON TABLE viroserve.patient_alias TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.patient_alias TO :rw_user;


--
-- Name: TABLE patient_medication; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.patient_medication FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.patient_medication FROM :owner;
GRANT ALL ON TABLE viroserve.patient_medication TO :owner;
GRANT SELECT ON TABLE viroserve.patient_medication TO :ro_user;
GRANT ALL ON TABLE viroserve.patient_medication TO :rw_user;


--
-- Name: TABLE viral_load; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.viral_load FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.viral_load FROM :owner;
GRANT ALL ON TABLE viroserve.viral_load TO :owner;
GRANT SELECT ON TABLE viroserve.viral_load TO :ro_user;
GRANT SELECT ON TABLE viroserve.viral_load TO :rw_user;


--
-- Name: TABLE cohort_patient_summary; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.cohort_patient_summary FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.cohort_patient_summary FROM :owner;
GRANT ALL ON TABLE viroserve.cohort_patient_summary TO :owner;
GRANT SELECT ON TABLE viroserve.cohort_patient_summary TO :ro_user;
GRANT SELECT ON TABLE viroserve.cohort_patient_summary TO :rw_user;


--
-- Name: SEQUENCE competent_cells_competent_cells_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.competent_cells_competent_cells_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.competent_cells_competent_cells_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.competent_cells_competent_cells_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.competent_cells_competent_cells_id_seq TO :rw_user;


--
-- Name: TABLE copy_number; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.copy_number FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.copy_number FROM :owner;
GRANT ALL ON TABLE viroserve.copy_number TO :owner;
GRANT SELECT ON TABLE viroserve.copy_number TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.copy_number TO :rw_user;


--
-- Name: SEQUENCE copy_number_copy_number_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.copy_number_copy_number_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.copy_number_copy_number_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.copy_number_copy_number_id_seq TO :owner;
GRANT SELECT ON SEQUENCE viroserve.copy_number_copy_number_id_seq TO :ro_user;
GRANT ALL ON SEQUENCE viroserve.copy_number_copy_number_id_seq TO :rw_user;


--
-- Name: TABLE copy_number_gel_lane; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.copy_number_gel_lane FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.copy_number_gel_lane FROM :owner;
GRANT ALL ON TABLE viroserve.copy_number_gel_lane TO :owner;
GRANT SELECT ON TABLE viroserve.copy_number_gel_lane TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.copy_number_gel_lane TO :rw_user;


--
-- Name: TABLE enzyme; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.enzyme FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.enzyme FROM :owner;
GRANT ALL ON TABLE viroserve.enzyme TO :owner;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.enzyme TO :rw_user;
GRANT SELECT ON TABLE viroserve.enzyme TO :ro_user;


--
-- Name: SEQUENCE enzyme_enzyme_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.enzyme_enzyme_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.enzyme_enzyme_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.enzyme_enzyme_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.enzyme_enzyme_id_seq TO :rw_user;


--
-- Name: TABLE extract_type; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.extract_type FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.extract_type FROM :owner;
GRANT ALL ON TABLE viroserve.extract_type TO :owner;
GRANT SELECT ON TABLE viroserve.extract_type TO :ro_user;
GRANT ALL ON TABLE viroserve.extract_type TO :rw_user;


--
-- Name: SEQUENCE extraction_extraction_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.extraction_extraction_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.extraction_extraction_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.extraction_extraction_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.extraction_extraction_id_seq TO :rw_user;


--
-- Name: TABLE gel; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.gel FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.gel FROM :owner;
GRANT ALL ON TABLE viroserve.gel TO :owner;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.gel TO :rw_user;
GRANT SELECT ON TABLE viroserve.gel TO :ro_user;


--
-- Name: SEQUENCE gel_gel_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.gel_gel_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.gel_gel_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.gel_gel_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.gel_gel_id_seq TO :rw_user;


--
-- Name: TABLE gel_lane; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.gel_lane FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.gel_lane FROM :owner;
GRANT ALL ON TABLE viroserve.gel_lane TO :owner;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.gel_lane TO :rw_user;
GRANT SELECT ON TABLE viroserve.gel_lane TO :ro_user;


--
-- Name: SEQUENCE gel_lane_gel_lane_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.gel_lane_gel_lane_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.gel_lane_gel_lane_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.gel_lane_gel_lane_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.gel_lane_gel_lane_id_seq TO :rw_user;


--
-- Name: TABLE genome_region; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.genome_region FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.genome_region FROM :owner;
GRANT ALL ON TABLE viroserve.genome_region TO :owner;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE viroserve.genome_region TO :rw_user;
GRANT SELECT ON TABLE viroserve.genome_region TO :ro_user;


--
-- Name: SEQUENCE hla_genotype_hla_genotype_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.hla_genotype_hla_genotype_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.hla_genotype_hla_genotype_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.hla_genotype_hla_genotype_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.hla_genotype_hla_genotype_id_seq TO :rw_user;


--
-- Name: TABLE na_sequence; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.na_sequence FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.na_sequence FROM :owner;
GRANT ALL ON TABLE viroserve.na_sequence TO :owner;
GRANT SELECT ON TABLE viroserve.na_sequence TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.na_sequence TO :rw_user;


--
-- Name: TABLE na_sequence_alignment; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.na_sequence_alignment FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.na_sequence_alignment FROM :owner;
GRANT ALL ON TABLE viroserve.na_sequence_alignment TO :owner;
GRANT SELECT ON TABLE viroserve.na_sequence_alignment TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.na_sequence_alignment TO :rw_user;


--
-- Name: TABLE na_sequence_alignment_pairwise; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.na_sequence_alignment_pairwise FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.na_sequence_alignment_pairwise FROM :owner;
GRANT ALL ON TABLE viroserve.na_sequence_alignment_pairwise TO :owner;
GRANT SELECT ON TABLE viroserve.na_sequence_alignment_pairwise TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.na_sequence_alignment_pairwise TO :rw_user;


--
-- Name: TABLE na_sequence_latest_revision; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.na_sequence_latest_revision FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.na_sequence_latest_revision FROM :owner;
GRANT ALL ON TABLE viroserve.na_sequence_latest_revision TO :owner;
GRANT SELECT ON TABLE viroserve.na_sequence_latest_revision TO :ro_user;
GRANT SELECT ON TABLE viroserve.na_sequence_latest_revision TO :rw_user;


--
-- Name: TABLE sequence_reference_alignment; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.sequence_reference_alignment FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.sequence_reference_alignment FROM :owner;
GRANT ALL ON TABLE viroserve.sequence_reference_alignment TO :owner;
GRANT SELECT ON TABLE viroserve.sequence_reference_alignment TO :ro_user;
GRANT SELECT ON TABLE viroserve.sequence_reference_alignment TO :rw_user;


--
-- Name: TABLE sequence_reference_alignment_pairwise; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.sequence_reference_alignment_pairwise FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.sequence_reference_alignment_pairwise FROM :owner;
GRANT ALL ON TABLE viroserve.sequence_reference_alignment_pairwise TO :owner;
GRANT SELECT ON TABLE viroserve.sequence_reference_alignment_pairwise TO :ro_user;
GRANT SELECT ON TABLE viroserve.sequence_reference_alignment_pairwise TO :rw_user;


--
-- Name: TABLE hxb2_stats; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.hxb2_stats FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.hxb2_stats FROM :owner;
GRANT ALL ON TABLE viroserve.hxb2_stats TO :owner;
GRANT SELECT ON TABLE viroserve.hxb2_stats TO :ro_user;
GRANT SELECT ON TABLE viroserve.hxb2_stats TO :rw_user;


--
-- Name: TABLE import_job; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.import_job FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.import_job FROM :owner;
GRANT ALL ON TABLE viroserve.import_job TO :owner;
GRANT SELECT ON TABLE viroserve.import_job TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.import_job TO :rw_user;


--
-- Name: SEQUENCE import_job_import_job_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.import_job_import_job_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.import_job_import_job_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.import_job_import_job_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.import_job_import_job_id_seq TO :rw_user;


--
-- Name: SEQUENCE infection_infection_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.infection_infection_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.infection_infection_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.infection_infection_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.infection_infection_id_seq TO :rw_user;


--
-- Name: SEQUENCE lab_result_cat_lab_result_cat_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.lab_result_cat_lab_result_cat_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.lab_result_cat_lab_result_cat_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.lab_result_cat_lab_result_cat_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.lab_result_cat_lab_result_cat_id_seq TO :rw_user;


--
-- Name: TABLE lab_result_cat_type_group; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.lab_result_cat_type_group FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.lab_result_cat_type_group FROM :owner;
GRANT ALL ON TABLE viroserve.lab_result_cat_type_group TO :owner;
GRANT SELECT ON TABLE viroserve.lab_result_cat_type_group TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.lab_result_cat_type_group TO :rw_user;


--
-- Name: SEQUENCE lab_result_cat_type_lab_result_cat_type_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.lab_result_cat_type_lab_result_cat_type_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.lab_result_cat_type_lab_result_cat_type_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.lab_result_cat_type_lab_result_cat_type_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.lab_result_cat_type_lab_result_cat_type_id_seq TO :rw_user;


--
-- Name: SEQUENCE lab_result_cat_value_lab_result_cat_value_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.lab_result_cat_value_lab_result_cat_value_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.lab_result_cat_value_lab_result_cat_value_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.lab_result_cat_value_lab_result_cat_value_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.lab_result_cat_value_lab_result_cat_value_id_seq TO :rw_user;


--
-- Name: TABLE lab_result_group; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.lab_result_group FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.lab_result_group FROM :owner;
GRANT ALL ON TABLE viroserve.lab_result_group TO :owner;
GRANT SELECT ON TABLE viroserve.lab_result_group TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.lab_result_group TO :rw_user;


--
-- Name: SEQUENCE lab_result_group_lab_result_group_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.lab_result_group_lab_result_group_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.lab_result_group_lab_result_group_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.lab_result_group_lab_result_group_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.lab_result_group_lab_result_group_id_seq TO :rw_user;


--
-- Name: SEQUENCE lab_result_num_lab_result_num_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.lab_result_num_lab_result_num_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.lab_result_num_lab_result_num_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.lab_result_num_lab_result_num_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.lab_result_num_lab_result_num_id_seq TO :rw_user;


--
-- Name: TABLE lab_result_num_type_group; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.lab_result_num_type_group FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.lab_result_num_type_group FROM :owner;
GRANT ALL ON TABLE viroserve.lab_result_num_type_group TO :owner;
GRANT SELECT ON TABLE viroserve.lab_result_num_type_group TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.lab_result_num_type_group TO :rw_user;


--
-- Name: SEQUENCE lab_result_num_type_lab_result_num_type_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.lab_result_num_type_lab_result_num_type_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.lab_result_num_type_lab_result_num_type_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.lab_result_num_type_lab_result_num_type_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.lab_result_num_type_lab_result_num_type_id_seq TO :rw_user;


--
-- Name: TABLE location; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.location FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.location FROM :owner;
GRANT ALL ON TABLE viroserve.location TO :owner;
GRANT SELECT ON TABLE viroserve.location TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.location TO :rw_user;


--
-- Name: SEQUENCE location_location_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.location_location_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.location_location_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.location_location_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.location_location_id_seq TO :rw_user;


--
-- Name: SEQUENCE medication_medication_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.medication_medication_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.medication_medication_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.medication_medication_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.medication_medication_id_seq TO :rw_user;


--
-- Name: SEQUENCE na_sequence_na_sequence_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.na_sequence_na_sequence_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.na_sequence_na_sequence_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.na_sequence_na_sequence_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.na_sequence_na_sequence_id_seq TO :rw_user;


--
-- Name: TABLE sample_note; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.sample_note FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.sample_note FROM :owner;
GRANT ALL ON TABLE viroserve.sample_note TO :owner;
GRANT SELECT ON TABLE viroserve.sample_note TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.sample_note TO :rw_user;


--
-- Name: SEQUENCE note_note_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.note_note_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.note_note_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.note_note_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.note_note_id_seq TO :rw_user;


--
-- Name: TABLE notes; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.notes FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.notes FROM :owner;
GRANT ALL ON TABLE viroserve.notes TO :owner;
GRANT SELECT ON TABLE viroserve.notes TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.notes TO :rw_user;


--
-- Name: SEQUENCE notes_note_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.notes_note_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.notes_note_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.notes_note_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.notes_note_id_seq TO :rw_user;


--
-- Name: TABLE organism; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.organism FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.organism FROM :owner;
GRANT ALL ON TABLE viroserve.organism TO :owner;
GRANT SELECT ON TABLE viroserve.organism TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.organism TO :rw_user;


--
-- Name: SEQUENCE organism_organism_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.organism_organism_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.organism_organism_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.organism_organism_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.organism_organism_id_seq TO :rw_user;


--
-- Name: TABLE patient_cohort; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.patient_cohort FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.patient_cohort FROM :owner;
GRANT ALL ON TABLE viroserve.patient_cohort TO :owner;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.patient_cohort TO :rw_user;
GRANT SELECT ON TABLE viroserve.patient_cohort TO :ro_user;


--
-- Name: TABLE patient_group; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.patient_group FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.patient_group FROM :owner;
GRANT ALL ON TABLE viroserve.patient_group TO :owner;
GRANT SELECT ON TABLE viroserve.patient_group TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.patient_group TO :rw_user;


--
-- Name: SEQUENCE patient_group_patient_group_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.patient_group_patient_group_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.patient_group_patient_group_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.patient_group_patient_group_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.patient_group_patient_group_id_seq TO :rw_user;


--
-- Name: SEQUENCE patient_medication_patient_medication_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.patient_medication_patient_medication_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.patient_medication_patient_medication_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.patient_medication_patient_medication_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.patient_medication_patient_medication_id_seq TO :rw_user;


--
-- Name: TABLE patient_patient_group; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.patient_patient_group FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.patient_patient_group FROM :owner;
GRANT ALL ON TABLE viroserve.patient_patient_group TO :owner;
GRANT SELECT ON TABLE viroserve.patient_patient_group TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.patient_patient_group TO :rw_user;


--
-- Name: SEQUENCE patient_patient_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.patient_patient_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.patient_patient_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.patient_patient_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.patient_patient_id_seq TO :rw_user;


--
-- Name: TABLE pcr_cleanup; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.pcr_cleanup FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.pcr_cleanup FROM :owner;
GRANT ALL ON TABLE viroserve.pcr_cleanup TO :owner;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.pcr_cleanup TO :rw_user;
GRANT SELECT ON TABLE viroserve.pcr_cleanup TO :ro_user;


--
-- Name: SEQUENCE pcr_cleanup_pcr_cleanup_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.pcr_cleanup_pcr_cleanup_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.pcr_cleanup_pcr_cleanup_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.pcr_cleanup_pcr_cleanup_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.pcr_cleanup_pcr_cleanup_id_seq TO :rw_user;


--
-- Name: TABLE pcr_pool; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.pcr_pool FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.pcr_pool FROM :owner;
GRANT ALL ON TABLE viroserve.pcr_pool TO :owner;
GRANT SELECT ON TABLE viroserve.pcr_pool TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.pcr_pool TO :rw_user;


--
-- Name: SEQUENCE pcr_pool_pcr_pool_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.pcr_pool_pcr_pool_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.pcr_pool_pcr_pool_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.pcr_pool_pcr_pool_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.pcr_pool_pcr_pool_id_seq TO :rw_user;


--
-- Name: TABLE pcr_pool_pcr_product; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.pcr_pool_pcr_product FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.pcr_pool_pcr_product FROM :owner;
GRANT ALL ON TABLE viroserve.pcr_pool_pcr_product TO :owner;
GRANT SELECT ON TABLE viroserve.pcr_pool_pcr_product TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.pcr_pool_pcr_product TO :rw_user;


--
-- Name: SEQUENCE pcr_product_pcr_product_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.pcr_product_pcr_product_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.pcr_product_pcr_product_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.pcr_product_pcr_product_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.pcr_product_pcr_product_id_seq TO :rw_user;


--
-- Name: TABLE pcr_product_primer; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.pcr_product_primer FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.pcr_product_primer FROM :owner;
GRANT ALL ON TABLE viroserve.pcr_product_primer TO :owner;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.pcr_product_primer TO :rw_user;
GRANT SELECT ON TABLE viroserve.pcr_product_primer TO :ro_user;


--
-- Name: SEQUENCE pcr_template_pcr_template_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.pcr_template_pcr_template_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.pcr_template_pcr_template_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.pcr_template_pcr_template_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.pcr_template_pcr_template_id_seq TO :rw_user;


--
-- Name: SEQUENCE primer_primer_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.primer_primer_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.primer_primer_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.primer_primer_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.primer_primer_id_seq TO :rw_user;


--
-- Name: TABLE primer; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.primer FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.primer FROM :owner;
GRANT ALL ON TABLE viroserve.primer TO :owner;
GRANT SELECT ON TABLE viroserve.primer TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.primer TO :rw_user;


--
-- Name: TABLE primer_position; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.primer_position FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.primer_position FROM :owner;
GRANT ALL ON TABLE viroserve.primer_position TO :owner;
GRANT SELECT ON TABLE viroserve.primer_position TO :ro_user;
GRANT ALL ON TABLE viroserve.primer_position TO :rw_user;


--
-- Name: TABLE project; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.project FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.project FROM :owner;
GRANT ALL ON TABLE viroserve.project TO :owner;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.project TO :rw_user;
GRANT SELECT ON TABLE viroserve.project TO :ro_user;


--
-- Name: TABLE project_materials; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.project_materials FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.project_materials FROM :owner;
GRANT ALL ON TABLE viroserve.project_materials TO :owner;
GRANT SELECT ON TABLE viroserve.project_materials TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.project_materials TO :rw_user;


--
-- Name: TABLE sample_first_pcr_template_path; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.sample_first_pcr_template_path FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.sample_first_pcr_template_path FROM :owner;
GRANT ALL ON TABLE viroserve.sample_first_pcr_template_path TO :owner;
GRANT SELECT ON TABLE viroserve.sample_first_pcr_template_path TO :rw_user;
GRANT SELECT ON TABLE viroserve.sample_first_pcr_template_path TO :ro_user;


--
-- Name: TABLE project_material_scientist_progress; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.project_material_scientist_progress FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.project_material_scientist_progress FROM :owner;
GRANT ALL ON TABLE viroserve.project_material_scientist_progress TO :owner;
GRANT SELECT ON TABLE viroserve.project_material_scientist_progress TO :ro_user;
GRANT SELECT ON TABLE viroserve.project_material_scientist_progress TO :rw_user;


--
-- Name: SEQUENCE project_project_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.project_project_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.project_project_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.project_project_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.project_project_id_seq TO :rw_user;


--
-- Name: TABLE protocol; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.protocol FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.protocol FROM :owner;
GRANT ALL ON TABLE viroserve.protocol TO :owner;
GRANT SELECT ON TABLE viroserve.protocol TO :ro_user;
GRANT ALL ON TABLE viroserve.protocol TO :rw_user;


--
-- Name: SEQUENCE protocol_protocol_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.protocol_protocol_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.protocol_protocol_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.protocol_protocol_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.protocol_protocol_id_seq TO :rw_user;


--
-- Name: TABLE protocol_type; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.protocol_type FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.protocol_type FROM :owner;
GRANT ALL ON TABLE viroserve.protocol_type TO :owner;
GRANT ALL ON TABLE viroserve.protocol_type TO :rw_user;


--
-- Name: SEQUENCE protocol_type_protocol_type_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.protocol_type_protocol_type_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.protocol_type_protocol_type_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.protocol_type_protocol_type_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.protocol_type_protocol_type_id_seq TO :rw_user;


--
-- Name: SEQUENCE restriction_enzyme_restriction_enzyme_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.restriction_enzyme_restriction_enzyme_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.restriction_enzyme_restriction_enzyme_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.restriction_enzyme_restriction_enzyme_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.restriction_enzyme_restriction_enzyme_id_seq TO :rw_user;


--
-- Name: TABLE rt_primer; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.rt_primer FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.rt_primer FROM :owner;
GRANT ALL ON TABLE viroserve.rt_primer TO :owner;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.rt_primer TO :rw_user;
GRANT SELECT ON TABLE viroserve.rt_primer TO :ro_user;


--
-- Name: SEQUENCE rt_product_rt_product_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.rt_product_rt_product_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.rt_product_rt_product_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.rt_product_rt_product_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.rt_product_rt_product_id_seq TO :rw_user;


--
-- Name: TABLE sample_patient_date; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.sample_patient_date FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.sample_patient_date FROM :owner;
GRANT ALL ON TABLE viroserve.sample_patient_date TO :owner;
GRANT SELECT ON TABLE viroserve.sample_patient_date TO :ro_user;
GRANT SELECT ON TABLE viroserve.sample_patient_date TO :rw_user;


--
-- Name: SEQUENCE sample_sample_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.sample_sample_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.sample_sample_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.sample_sample_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.sample_sample_id_seq TO :rw_user;


--
-- Name: TABLE sample_type; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.sample_type FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.sample_type FROM :owner;
GRANT ALL ON TABLE viroserve.sample_type TO :owner;
GRANT SELECT ON TABLE viroserve.sample_type TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.sample_type TO :rw_user;


--
-- Name: TABLE scientist; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.scientist FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.scientist FROM :owner;
GRANT ALL ON TABLE viroserve.scientist TO :owner;
GRANT SELECT ON TABLE viroserve.scientist TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.scientist TO :rw_user;


--
-- Name: TABLE sample_search; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.sample_search FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.sample_search FROM :owner;
GRANT ALL ON TABLE viroserve.sample_search TO :owner;
GRANT SELECT ON TABLE viroserve.sample_search TO :ro_user;
GRANT SELECT ON TABLE viroserve.sample_search TO :rw_user;


--
-- Name: SEQUENCE sample_type_sample_type_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.sample_type_sample_type_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.sample_type_sample_type_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.sample_type_sample_type_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.sample_type_sample_type_id_seq TO :rw_user;


--
-- Name: TABLE scientist_group; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.scientist_group FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.scientist_group FROM :owner;
GRANT ALL ON TABLE viroserve.scientist_group TO :owner;
GRANT SELECT ON TABLE viroserve.scientist_group TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.scientist_group TO :rw_user;


--
-- Name: SEQUENCE scientist_group_scientist_group_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.scientist_group_scientist_group_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.scientist_group_scientist_group_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.scientist_group_scientist_group_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.scientist_group_scientist_group_id_seq TO :rw_user;


--
-- Name: TABLE scientist_scientist_group; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.scientist_scientist_group FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.scientist_scientist_group FROM :owner;
GRANT ALL ON TABLE viroserve.scientist_scientist_group TO :owner;
GRANT SELECT ON TABLE viroserve.scientist_scientist_group TO :ro_user;
GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE viroserve.scientist_scientist_group TO :rw_user;


--
-- Name: SEQUENCE scientist_scientist_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.scientist_scientist_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.scientist_scientist_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.scientist_scientist_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.scientist_scientist_id_seq TO :rw_user;


--
-- Name: TABLE sequence_genome_region; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.sequence_genome_region FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.sequence_genome_region FROM :owner;
GRANT ALL ON TABLE viroserve.sequence_genome_region TO :owner;
GRANT SELECT ON TABLE viroserve.sequence_genome_region TO :ro_user;
GRANT SELECT ON TABLE viroserve.sequence_genome_region TO :rw_user;


--
-- Name: TABLE sequence_type; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.sequence_type FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.sequence_type FROM :owner;
GRANT ALL ON TABLE viroserve.sequence_type TO :owner;
GRANT SELECT ON TABLE viroserve.sequence_type TO :ro_user;
GRANT ALL ON TABLE viroserve.sequence_type TO :rw_user;


--
-- Name: TABLE sequence_search; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.sequence_search FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.sequence_search FROM :owner;
GRANT ALL ON TABLE viroserve.sequence_search TO :owner;
GRANT SELECT ON TABLE viroserve.sequence_search TO :ro_user;
GRANT SELECT ON TABLE viroserve.sequence_search TO :rw_user;


--
-- Name: SEQUENCE tissue_type_tissue_type_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.tissue_type_tissue_type_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.tissue_type_tissue_type_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.tissue_type_tissue_type_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.tissue_type_tissue_type_id_seq TO :rw_user;


--
-- Name: SEQUENCE unit_unit_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.unit_unit_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.unit_unit_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.unit_unit_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.unit_unit_id_seq TO :rw_user;


--
-- Name: SEQUENCE visit_visit_id_seq; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON SEQUENCE viroserve.visit_visit_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE viroserve.visit_visit_id_seq FROM :owner;
GRANT ALL ON SEQUENCE viroserve.visit_visit_id_seq TO :owner;
GRANT ALL ON SEQUENCE viroserve.visit_visit_id_seq TO :rw_user;


--
-- Name: TABLE distinct_sample_search; Type: ACL; Schema: viroserve; Owner: :owner
--

REVOKE ALL ON TABLE viroserve.distinct_sample_search FROM PUBLIC;
REVOKE ALL ON TABLE viroserve.distinct_sample_search FROM :owner;
GRANT ALL ON TABLE viroserve.distinct_sample_search TO :owner;
GRANT SELECT ON TABLE viroserve.distinct_sample_search TO :ro_user;
GRANT SELECT ON TABLE viroserve.distinct_sample_search TO :rw_user;


--
-- PostgreSQL database dump complete
--

