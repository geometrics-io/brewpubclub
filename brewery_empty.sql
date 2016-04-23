--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: alternate_member; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE alternate_member (
    membernumber integer,
    firstname character varying,
    lastname character varying
);


ALTER TABLE alternate_member OWNER TO postgres;

--
-- Name: member_number_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE member_number_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE member_number_seq OWNER TO postgres;

--
-- Name: members; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE members (
    membernumber integer DEFAULT nextval('member_number_seq'::regclass) NOT NULL,
    firstname character varying,
    lastname character varying
);


ALTER TABLE members OWNER TO postgres;

--
-- Name: all_members; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW all_members AS
 SELECT members.membernumber,
    members.firstname,
    members.lastname
   FROM members
UNION
 SELECT alternate_member.membernumber,
    alternate_member.firstname,
    alternate_member.lastname
   FROM alternate_member;


ALTER TABLE all_members OWNER TO postgres;

--
-- Name: member_status; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE member_status (
    membernumber integer NOT NULL,
    start_date date NOT NULL,
    membership character varying NOT NULL,
    memstat_id integer NOT NULL,
    total_raw_units numeric(8,2) DEFAULT 0
);


ALTER TABLE member_status OWNER TO postgres;

--
-- Name: member_transactions; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE member_transactions (
    membernumber integer NOT NULL,
    memstat_id integer NOT NULL,
    "timestamp" timestamp without time zone DEFAULT now() NOT NULL,
    raw_units numeric(8,3) NOT NULL
);


ALTER TABLE member_transactions OWNER TO postgres;

--
-- Name: membership_levels; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE membership_levels (
    name character varying NOT NULL,
    unit_type character varying,
    units numeric(8,2),
    unit_base integer
);


ALTER TABLE membership_levels OWNER TO postgres;

--
-- Name: membership_units_used; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW membership_units_used AS
 SELECT member_transactions.membernumber,
    member_transactions.memstat_id,
    sum(member_transactions.raw_units) AS raw_units_used
   FROM member_transactions
  GROUP BY member_transactions.memstat_id, member_transactions.membernumber
  ORDER BY member_transactions.membernumber;


ALTER TABLE membership_units_used OWNER TO postgres;

--
-- Name: memstat_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW memstat_view AS
 WITH data AS (
         SELECT membership_units_used.membernumber,
            membership_units_used.memstat_id,
            membership_units_used.raw_units_used,
            member_status.start_date,
            member_status.membership,
            member_status.total_raw_units,
            membership_levels.name,
            membership_levels.unit_type,
            membership_levels.units,
            membership_levels.unit_base
           FROM ((membership_units_used
             JOIN member_status USING (membernumber, memstat_id))
             LEFT JOIN membership_levels ON (((membership_levels.name)::text = (member_status.membership)::text)))
          ORDER BY membership_units_used.membernumber
        )
 SELECT data.membernumber,
    data.memstat_id,
    data.membership,
    round((data.total_raw_units / (data.unit_base)::numeric), 2) AS units,
    round((data.raw_units_used / (data.unit_base)::numeric), 2) AS units_used,
    (round((data.total_raw_units / (data.unit_base)::numeric)) - round((data.raw_units_used / (data.unit_base)::numeric), 2)) AS units_remaining
   FROM data;


ALTER TABLE memstat_view OWNER TO postgres;

--
-- Name: allthethings; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW allthethings AS
 SELECT mv.membernumber,
    mv.memstat_id,
    mv.membership,
    mv.units,
    mv.units_used,
    mv.units_remaining,
    members.firstname,
    members.lastname,
    am.firstname AS alt_firstname,
    am.lastname AS alt_lastname
   FROM ((memstat_view mv
     JOIN members USING (membernumber))
     LEFT JOIN alternate_member am ON ((mv.membernumber = am.membernumber)))
  ORDER BY mv.membernumber;


ALTER TABLE allthethings OWNER TO postgres;

--
-- Name: contact; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE contact (
    membernumber integer,
    street character varying(140),
    city character varying(85),
    state character varying(30),
    zip character varying(20),
    phone character varying(20),
    email character varying(254)
);


ALTER TABLE contact OWNER TO postgres;

--
-- Name: bigpicture; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW bigpicture AS
 WITH data AS (
         SELECT allthethings.membernumber,
            allthethings.memstat_id,
            allthethings.membership,
            allthethings.units,
            allthethings.units_used,
            allthethings.units_remaining,
            allthethings.firstname,
            allthethings.lastname,
            allthethings.alt_firstname,
            allthethings.alt_lastname,
            ((((((allthethings.membernumber || ' : '::text) || (allthethings.membership)::text) || ' : '::text) || (allthethings.firstname)::text) || ' '::text) || (allthethings.lastname)::text) AS member_name
           FROM allthethings
        UNION
         SELECT allthethings.membernumber,
            allthethings.memstat_id,
            allthethings.membership,
            allthethings.units,
            allthethings.units_used,
            allthethings.units_remaining,
            allthethings.firstname,
            allthethings.lastname,
            allthethings.alt_firstname,
            allthethings.alt_lastname,
            ((((((allthethings.membernumber || ' : '::text) || (allthethings.membership)::text) || ' : '::text) || (allthethings.alt_firstname)::text) || ' '::text) || (allthethings.alt_lastname)::text) AS member_name
           FROM allthethings
        )
 SELECT data.membernumber,
    data.memstat_id,
    data.membership,
    data.units,
    data.units_used,
    data.units_remaining,
    data.firstname,
    data.lastname,
    data.alt_firstname,
    data.alt_lastname,
    data.member_name,
    contact.street,
    contact.city,
    contact.state,
    contact.zip,
    contact.phone,
    contact.email,
    member_status.start_date,
    date((member_status.start_date + '1 year'::interval)) AS end_date,
    max(member_transactions."timestamp") AS last_used,
    (member_status.total_raw_units - membership_units_used.raw_units_used) AS available_raw_units
   FROM ((((data
     LEFT JOIN contact ON ((contact.membernumber = data.membernumber)))
     LEFT JOIN member_status ON ((member_status.memstat_id = data.memstat_id)))
     LEFT JOIN membership_units_used ON ((membership_units_used.memstat_id = member_status.memstat_id)))
     LEFT JOIN member_transactions ON ((member_transactions.memstat_id = data.memstat_id)))
  WHERE (data.member_name <> ''::text)
  GROUP BY data.membernumber, data.memstat_id, data.membership, data.units, data.units_used, data.units_remaining, data.firstname, data.lastname, data.alt_firstname, data.alt_lastname, data.member_name, contact.street, contact.city, contact.state, contact.zip, contact.phone, contact.email, member_status.start_date, (member_status.total_raw_units - membership_units_used.raw_units_used), date((member_status.start_date + '1 year'::interval))
  ORDER BY data.membernumber;


ALTER TABLE bigpicture OWNER TO postgres;

--
-- Name: member_status_memstat_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE member_status_memstat_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE member_status_memstat_id_seq OWNER TO postgres;

--
-- Name: member_status_memstat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE member_status_memstat_id_seq OWNED BY member_status.memstat_id;


--
-- Name: membership_level_raw_units; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW membership_level_raw_units AS
 SELECT membership_levels.name,
    membership_levels.unit_type,
    membership_levels.units
   FROM membership_levels
  WHERE ((membership_levels.unit_type)::text = 'pints'::text)
UNION
 SELECT membership_levels.name,
    membership_levels.unit_type,
    (membership_levels.units * (4)::numeric) AS units
   FROM membership_levels
  WHERE ((membership_levels.unit_type)::text = 'growlers'::text);


ALTER TABLE membership_level_raw_units OWNER TO postgres;

--
-- Name: monthly_raw_totals; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW monthly_raw_totals AS
 WITH data AS (
         SELECT member_transactions.membernumber,
            member_transactions.memstat_id,
            date_part('year'::text, date(member_transactions."timestamp")) AS year,
            date_part('month'::text, date(member_transactions."timestamp")) AS month,
            member_transactions."timestamp",
            member_transactions.raw_units,
            member_status.membership,
            membership_levels_1.unit_base
           FROM ((member_transactions
             LEFT JOIN member_status ON ((member_status.memstat_id = member_transactions.memstat_id)))
             LEFT JOIN membership_levels membership_levels_1 ON (((membership_levels_1.name)::text = (member_status.membership)::text)))
        )
 SELECT data.membership,
    data.year,
    data.month,
    round(sum(data.raw_units), 2) AS monthly_total_raw,
    membership_levels.unit_base
   FROM (data
     LEFT JOIN membership_levels ON (((membership_levels.name)::text = (data.membership)::text)))
  GROUP BY data.membership, data.year, data.month, membership_levels.unit_base, date_trunc('month'::text, data."timestamp")
  ORDER BY data.year, data.month, data.membership;


ALTER TABLE monthly_raw_totals OWNER TO postgres;

--
-- Name: monthlies_report; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW monthlies_report AS
 WITH jan AS (
         SELECT monthly_raw_totals.year,
            monthly_raw_totals.membership,
            round((monthly_raw_totals.monthly_total_raw / (monthly_raw_totals.unit_base)::numeric), 2) AS jan
           FROM monthly_raw_totals
          WHERE (monthly_raw_totals.month = (1)::double precision)
        ), feb AS (
         SELECT monthly_raw_totals.year,
            monthly_raw_totals.membership,
            round((monthly_raw_totals.monthly_total_raw / (monthly_raw_totals.unit_base)::numeric), 2) AS feb
           FROM monthly_raw_totals
          WHERE (monthly_raw_totals.month = (2)::double precision)
        ), mar AS (
         SELECT monthly_raw_totals.year,
            monthly_raw_totals.membership,
            round((monthly_raw_totals.monthly_total_raw / (monthly_raw_totals.unit_base)::numeric), 2) AS mar
           FROM monthly_raw_totals
          WHERE (monthly_raw_totals.month = (3)::double precision)
        ), apr AS (
         SELECT monthly_raw_totals.year,
            monthly_raw_totals.membership,
            round((monthly_raw_totals.monthly_total_raw / (monthly_raw_totals.unit_base)::numeric), 2) AS apr
           FROM monthly_raw_totals
          WHERE (monthly_raw_totals.month = (4)::double precision)
        ), may AS (
         SELECT monthly_raw_totals.year,
            monthly_raw_totals.membership,
            round((monthly_raw_totals.monthly_total_raw / (monthly_raw_totals.unit_base)::numeric), 2) AS may
           FROM monthly_raw_totals
          WHERE (monthly_raw_totals.month = (5)::double precision)
        ), jun AS (
         SELECT monthly_raw_totals.year,
            monthly_raw_totals.membership,
            round((monthly_raw_totals.monthly_total_raw / (monthly_raw_totals.unit_base)::numeric), 2) AS jun
           FROM monthly_raw_totals
          WHERE (monthly_raw_totals.month = (6)::double precision)
        ), jul AS (
         SELECT monthly_raw_totals.year,
            monthly_raw_totals.membership,
            round((monthly_raw_totals.monthly_total_raw / (monthly_raw_totals.unit_base)::numeric), 2) AS jul
           FROM monthly_raw_totals
          WHERE (monthly_raw_totals.month = (7)::double precision)
        ), aug AS (
         SELECT monthly_raw_totals.year,
            monthly_raw_totals.membership,
            round((monthly_raw_totals.monthly_total_raw / (monthly_raw_totals.unit_base)::numeric), 2) AS aug
           FROM monthly_raw_totals
          WHERE (monthly_raw_totals.month = (8)::double precision)
        ), sep AS (
         SELECT monthly_raw_totals.year,
            monthly_raw_totals.membership,
            round((monthly_raw_totals.monthly_total_raw / (monthly_raw_totals.unit_base)::numeric), 2) AS sep
           FROM monthly_raw_totals
          WHERE (monthly_raw_totals.month = (9)::double precision)
        ), oct AS (
         SELECT monthly_raw_totals.year,
            monthly_raw_totals.membership,
            round((monthly_raw_totals.monthly_total_raw / (monthly_raw_totals.unit_base)::numeric), 2) AS oct
           FROM monthly_raw_totals
          WHERE (monthly_raw_totals.month = (10)::double precision)
        ), nov AS (
         SELECT monthly_raw_totals.year,
            monthly_raw_totals.membership,
            round((monthly_raw_totals.monthly_total_raw / (monthly_raw_totals.unit_base)::numeric), 2) AS nov
           FROM monthly_raw_totals
          WHERE (monthly_raw_totals.month = (11)::double precision)
        ), "dec" AS (
         SELECT monthly_raw_totals.year,
            monthly_raw_totals.membership,
            round((monthly_raw_totals.monthly_total_raw / (monthly_raw_totals.unit_base)::numeric), 2) AS "dec"
           FROM monthly_raw_totals
          WHERE (monthly_raw_totals.month = (12)::double precision)
        )
 SELECT jan.year,
    jan.membership,
    jan.jan,
    feb.feb,
    mar.mar,
    apr.apr,
    may.may,
    jun.jun,
    jul.jul,
    aug.aug,
    sep.sep,
    oct.oct,
    nov.nov,
    "dec"."dec"
   FROM (((((((((((jan
     LEFT JOIN feb ON ((((jan.membership)::text = (feb.membership)::text) AND (jan.year = feb.year))))
     LEFT JOIN mar ON ((((jan.membership)::text = (mar.membership)::text) AND (jan.year = mar.year))))
     LEFT JOIN apr ON ((((jan.membership)::text = (apr.membership)::text) AND (jan.year = apr.year))))
     LEFT JOIN may ON ((((jan.membership)::text = (may.membership)::text) AND (jan.year = may.year))))
     LEFT JOIN jun ON ((((jan.membership)::text = (jun.membership)::text) AND (jan.year = jun.year))))
     LEFT JOIN jul ON ((((jan.membership)::text = (jul.membership)::text) AND (jan.year = jul.year))))
     LEFT JOIN aug ON ((((jan.membership)::text = (aug.membership)::text) AND (jan.year = aug.year))))
     LEFT JOIN sep ON ((((jan.membership)::text = (sep.membership)::text) AND (jan.year = sep.year))))
     LEFT JOIN oct ON ((((jan.membership)::text = (oct.membership)::text) AND (jan.year = oct.year))))
     LEFT JOIN nov ON ((((jan.membership)::text = (nov.membership)::text) AND (jan.year = nov.year))))
     LEFT JOIN "dec" ON ((((jan.membership)::text = ("dec".membership)::text) AND (jan.year = "dec".year))));


ALTER TABLE monthlies_report OWNER TO postgres;

--
-- Name: months_left; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW months_left AS
 SELECT member_status.membernumber,
    date_part('months'::text, age((member_status.start_date + '1 year'::interval), (date(now()))::timestamp without time zone)) AS months_left
   FROM member_status;


ALTER TABLE months_left OWNER TO postgres;

--
-- Name: the_members_data; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW the_members_data AS
 SELECT a.membernumber,
    a.firstname,
    a.lastname,
    b.firstname AS alt_firstname,
    b.lastname AS alt_lastname,
    c.membership,
    c.memstat_id,
    c.units,
    c.units_used,
    c.units_remaining,
    d.start_date
   FROM (((members a
     LEFT JOIN alternate_member b ON ((a.membernumber = b.membernumber)))
     LEFT JOIN memstat_view c ON ((a.membernumber = c.membernumber)))
     LEFT JOIN member_status d ON ((c.memstat_id = d.memstat_id)))
  ORDER BY a.membernumber;


ALTER TABLE the_members_data OWNER TO postgres;

--
-- Name: units_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW units_view AS
 SELECT member_status.membernumber,
    member_status.start_date,
    member_status.membership,
    member_status.memstat_id,
    member_status.total_raw_units,
    membership_level_raw_units.name,
    membership_level_raw_units.unit_type,
    membership_level_raw_units.units
   FROM (member_status
     JOIN membership_level_raw_units ON (((membership_level_raw_units.name)::text = (member_status.membership)::text)));


ALTER TABLE units_view OWNER TO postgres;

--
-- Name: memstat_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY member_status ALTER COLUMN memstat_id SET DEFAULT nextval('member_status_memstat_id_seq'::regclass);


--
-- Data for Name: alternate_member; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY alternate_member (membernumber, firstname, lastname) FROM stdin;
\.


--
-- Data for Name: contact; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY contact (membernumber, street, city, state, zip, phone, email) FROM stdin;
\.


--
-- Name: member_number_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('member_number_seq', 1, false);


--
-- Data for Name: member_status; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY member_status (membernumber, start_date, membership, memstat_id, total_raw_units) FROM stdin;
\.


--
-- Name: member_status_memstat_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('member_status_memstat_id_seq', 1, false);


--
-- Data for Name: member_transactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY member_transactions (membernumber, memstat_id, "timestamp", raw_units) FROM stdin;
\.


--
-- Data for Name: members; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY members (membernumber, firstname, lastname) FROM stdin;
\.


--
-- Data for Name: membership_levels; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY membership_levels (name, unit_type, units, unit_base) FROM stdin;
flex	growlers	12.00	4
full	growlers	52.00	4
half	growlers	26.00	4
social	pints	50.00	1
\.


--
-- Name: member_status_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY member_status
    ADD CONSTRAINT member_status_pkey PRIMARY KEY (memstat_id);


--
-- Name: members_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY members
    ADD CONSTRAINT members_pkey PRIMARY KEY (membernumber);


--
-- Name: membership_levels_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY membership_levels
    ADD CONSTRAINT membership_levels_pkey PRIMARY KEY (name);


--
-- Name: alternate_member_membernumber_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY alternate_member
    ADD CONSTRAINT alternate_member_membernumber_fkey FOREIGN KEY (membernumber) REFERENCES members(membernumber);


--
-- Name: contact_membernumber_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY contact
    ADD CONSTRAINT contact_membernumber_fkey FOREIGN KEY (membernumber) REFERENCES members(membernumber);


--
-- Name: member_status_membernumber_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY member_status
    ADD CONSTRAINT member_status_membernumber_fkey FOREIGN KEY (membernumber) REFERENCES members(membernumber);


--
-- Name: member_status_membership_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY member_status
    ADD CONSTRAINT member_status_membership_fkey FOREIGN KEY (membership) REFERENCES membership_levels(name);


--
-- Name: member_transactions_membernumber_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY member_transactions
    ADD CONSTRAINT member_transactions_membernumber_fkey FOREIGN KEY (membernumber) REFERENCES members(membernumber);


--
-- Name: member_transactions_memstat_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY member_transactions
    ADD CONSTRAINT member_transactions_memstat_id_fkey FOREIGN KEY (memstat_id) REFERENCES member_status(memstat_id);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- Name: alternate_member; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE alternate_member FROM PUBLIC;
REVOKE ALL ON TABLE alternate_member FROM postgres;
GRANT ALL ON TABLE alternate_member TO postgres;


--
-- Name: members; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE members FROM PUBLIC;
REVOKE ALL ON TABLE members FROM postgres;
GRANT ALL ON TABLE members TO postgres;


--
-- Name: member_status; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE member_status FROM PUBLIC;
REVOKE ALL ON TABLE member_status FROM postgres;
GRANT ALL ON TABLE member_status TO postgres;


--
-- Name: member_transactions; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE member_transactions FROM PUBLIC;
REVOKE ALL ON TABLE member_transactions FROM postgres;
GRANT ALL ON TABLE member_transactions TO postgres;


--
-- Name: membership_levels; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE membership_levels FROM PUBLIC;
REVOKE ALL ON TABLE membership_levels FROM postgres;
GRANT ALL ON TABLE membership_levels TO postgres;


--
-- Name: contact; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE contact FROM PUBLIC;
REVOKE ALL ON TABLE contact FROM postgres;
GRANT ALL ON TABLE contact TO postgres;


--
-- PostgreSQL database dump complete
--

