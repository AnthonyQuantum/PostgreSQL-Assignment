--
-- PostgreSQL database dump
--

-- Dumped from database version 12.3 (Ubuntu 12.3-1.pgdg18.04+1)
-- Dumped by pg_dump version 12.3 (Ubuntu 12.3-1.pgdg18.04+1)

-- Started on 2020-05-26 00:50:32 MSK

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 3 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO postgres;

--
-- TOC entry 3024 (class 0 OID 0)
-- Dependencies: 3
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- TOC entry 214 (class 1255 OID 16796)
-- Name: cancel_transaction(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.cancel_transaction(trans_id integer)
    LANGUAGE sql
    AS $$DELETE FROM sold_products WHERE transaction_id = trans_id;
DELETE FROM transactions WHERE id = trans_id;
$$;


ALTER PROCEDURE public.cancel_transaction(trans_id integer) OWNER TO postgres;

--
-- TOC entry 215 (class 1255 OID 16797)
-- Name: check_phone_number(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_phone_number() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
  IF NEW.phone_number SIMILAR TO '%[^0-9]%'
  THEN
    RAISE EXCEPTION 'Invalid phone number format of customer [id:%]',
    NEW.id;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_phone_number() OWNER TO postgres;

--
-- TOC entry 216 (class 1255 OID 16835)
-- Name: get_price_with_discount(double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_price_with_discount(price double precision) RETURNS double precision
    LANGUAGE plpgsql
    AS $$
DECLARE min_discount_price DOUBLE PRECISION;
DECLARE discount_value DOUBLE PRECISION;
DECLARE price_with_discount DOUBLE PRECISION;
BEGIN
	SELECT
	(MAX(min_price)) INTO min_discount_price
	FROM total_price_discounts
	WHERE total_price_discounts.min_price <= price;
	
	SELECT
	(value) INTO discount_value
	FROM total_price_discounts
	WHERE total_price_discounts.min_price = min_discount_price;
	
	price_with_discount := price - price * COALESCE(discount_value, 0);

    RETURN price_with_discount;
END;
$$;


ALTER FUNCTION public.get_price_with_discount(price double precision) OWNER TO postgres;

--
-- TOC entry 229 (class 1255 OID 16836)
-- Name: get_product_price_with_discount(integer, double precision, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_product_price_with_discount(id integer, price double precision, amount integer) RETURNS double precision
    LANGUAGE plpgsql
    AS $$
DECLARE min_amount_for_discount INTEGER;
DECLARE discount_value DOUBLE PRECISION;
DECLARE price_with_discount DOUBLE PRECISION;
BEGIN
	SELECT
	(MAX(min_amount)) INTO min_amount_for_discount
	FROM product_discounts
	WHERE product_discounts.min_amount <= amount AND product_discounts.product_id = id;
	
	SELECT
	(value) INTO discount_value
	FROM product_discounts
	WHERE product_discounts.min_amount = min_amount_for_discount;
	
	price_with_discount := price * amount * COALESCE(1 - discount_value, 1);

    RETURN price_with_discount;
END;
$$;


ALTER FUNCTION public.get_product_price_with_discount(id integer, price double precision, amount integer) OWNER TO postgres;

--
-- TOC entry 231 (class 1255 OID 16868)
-- Name: most_freq_func(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.most_freq_func(val integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE result_value INTEGER;
BEGIN
SELECT customer_id 
FROM transactions
GROUP BY value
ORDER BY count(*) DESC
LIMIT 1 INTO result_value;

RETURN result_value;
END;
$$;


ALTER FUNCTION public.most_freq_func(val integer) OWNER TO postgres;

--
-- TOC entry 230 (class 1255 OID 16859)
-- Name: most_freq_func(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.most_freq_func(val integer, sth integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE result_value INTEGER;
BEGIN
SELECT customer_id 
FROM transactions
GROUP BY value
ORDER BY count(*) DESC
LIMIT 1 INTO result_value;

RETURN result_value;
END;
$$;


ALTER FUNCTION public.most_freq_func(val integer, sth integer) OWNER TO postgres;

--
-- TOC entry 671 (class 1255 OID 16860)
-- Name: most_freq_accum(integer); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE public.most_freq_accum(integer) (
    SFUNC = public.most_freq_func,
    STYPE = integer,
    INITCOND = '-1'
);


ALTER AGGREGATE public.most_freq_accum(integer) OWNER TO postgres;

--
-- TOC entry 1442 (class 2617 OID 16869)
-- Name: +; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR public.+ (
    FUNCTION = public.most_freq_accum,
    LEFTARG = integer
);


ALTER OPERATOR public.+ (integer, NONE) OWNER TO postgres;

--
-- TOC entry 1443 (class 2617 OID 16870)
-- Name: +; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR public.+ (
    FUNCTION = public.most_freq_accum,
    RIGHTARG = integer
);


ALTER OPERATOR public.+ (NONE, integer) OWNER TO postgres;

--
-- TOC entry 1445 (class 2617 OID 16872)
-- Name: =|=; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR public.=|= (
    FUNCTION = public.most_freq_accum,
    RIGHTARG = integer
);


ALTER OPERATOR public.=|= (NONE, integer) OWNER TO postgres;

--
-- TOC entry 1444 (class 2617 OID 16871)
-- Name: =||=; Type: OPERATOR; Schema: public; Owner: postgres
--

CREATE OPERATOR public.=||= (
    FUNCTION = public.most_freq_accum,
    RIGHTARG = integer
);


ALTER OPERATOR public.=||= (NONE, integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 203 (class 1259 OID 16694)
-- Name: customers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customers (
    id integer NOT NULL,
    phone_number text NOT NULL,
    contact_name text NOT NULL,
    address text NOT NULL
);


ALTER TABLE public.customers OWNER TO postgres;

--
-- TOC entry 205 (class 1259 OID 16727)
-- Name: customers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.customers ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.customers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 202 (class 1259 OID 16686)
-- Name: products; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.products (
    id integer NOT NULL,
    name text NOT NULL,
    wholesale_price double precision NOT NULL,
    retail_price double precision NOT NULL,
    description text,
    CONSTRAINT retail_price CHECK ((retail_price > (0.0)::double precision)),
    CONSTRAINT wholesale_price CHECK ((wholesale_price > (0.0)::double precision))
);


ALTER TABLE public.products OWNER TO postgres;

--
-- TOC entry 208 (class 1259 OID 16737)
-- Name: sold_products; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sold_products (
    transaction_id integer NOT NULL,
    product_id integer NOT NULL,
    amount integer NOT NULL,
    CONSTRAINT amount CHECK ((amount > 0))
);


ALTER TABLE public.sold_products OWNER TO postgres;

--
-- TOC entry 204 (class 1259 OID 16702)
-- Name: transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transactions (
    id integer NOT NULL,
    "time" timestamp without time zone NOT NULL,
    customer_id integer NOT NULL,
    is_wholesale boolean NOT NULL,
    CONSTRAINT "time" CHECK (("time" < LOCALTIMESTAMP))
);


ALTER TABLE public.transactions OWNER TO postgres;

--
-- TOC entry 211 (class 1259 OID 16813)
-- Name: high_demand_products; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.high_demand_products AS
 SELECT products.id,
    products.name,
    ( SELECT COALESCE(sum(sold_products.amount), (0)::bigint) AS "coalesce"
           FROM (public.sold_products
             JOIN public.transactions ON ((transactions.id = sold_products.transaction_id)))
          WHERE ((sold_products.product_id = products.id) AND transactions.is_wholesale)) AS sold_as_wholesale,
    ( SELECT COALESCE(sum(sold_products.amount), (0)::bigint) AS "coalesce"
           FROM (public.sold_products
             JOIN public.transactions ON ((transactions.id = sold_products.transaction_id)))
          WHERE ((sold_products.product_id = products.id) AND (NOT transactions.is_wholesale))) AS sold_as_retail,
    ( SELECT COALESCE(sum(sold_products.amount), (0)::bigint) AS "coalesce"
           FROM (public.sold_products
             JOIN public.transactions ON ((transactions.id = sold_products.transaction_id)))
          WHERE (sold_products.product_id = products.id)) AS sold_total
   FROM public.products;


ALTER TABLE public.high_demand_products OWNER TO postgres;

--
-- TOC entry 209 (class 1259 OID 16747)
-- Name: product_discounts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product_discounts (
    product_id integer NOT NULL,
    min_amount integer NOT NULL,
    value double precision NOT NULL,
    CONSTRAINT min_amount CHECK ((min_amount >= 1)),
    CONSTRAINT value CHECK (((value > (0.0)::double precision) AND (value <= (1.0)::double precision)))
);


ALTER TABLE public.product_discounts OWNER TO postgres;

--
-- TOC entry 206 (class 1259 OID 16729)
-- Name: products_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.products ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.products_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 212 (class 1259 OID 16873)
-- Name: transaction_info; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.transaction_info AS
 SELECT transactions.id,
    transactions."time",
    customers.id AS customer_id,
    customers.contact_name,
        CASE
            WHEN transactions.is_wholesale THEN 'Wholesale'::text
            ELSE 'Retail'::text
        END AS sell_type,
    ( SELECT string_agg(concat(sold_products.amount, ' x ', products.name), ', '::text) AS string_agg
           FROM (public.sold_products
             JOIN public.products ON ((sold_products.product_id = products.id)))
          WHERE (sold_products.transaction_id = transactions.id)) AS contents,
    ( SELECT public.get_price_with_discount(sum(public.get_product_price_with_discount(sold_products.product_id,
                CASE
                    WHEN transactions.is_wholesale THEN products.wholesale_price
                    ELSE products.retail_price
                END, sold_products.amount))) AS get_price_with_discount
           FROM (public.sold_products
             JOIN public.products ON ((sold_products.product_id = products.id)))
          WHERE (sold_products.transaction_id = transactions.id)) AS total_price_with_all_discounts
   FROM (public.transactions
     JOIN public.customers ON ((transactions.customer_id = customers.id)))
  ORDER BY transactions.id;


ALTER TABLE public.transaction_info OWNER TO postgres;

--
-- TOC entry 213 (class 1259 OID 16878)
-- Name: top_customers; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.top_customers AS
 SELECT customers.id,
    customers.contact_name,
    customers.phone_number,
    customers.address,
    ( SELECT sum(transaction_info.total_price_with_all_discounts) AS sum
           FROM public.transaction_info
          WHERE (transaction_info.customer_id = customers.id)) AS revenue,
    ( SELECT max(transactions."time") AS max
           FROM public.transactions
          WHERE (transactions.customer_id = customers.id)) AS last_purchase
   FROM public.customers
  ORDER BY ( SELECT sum(transaction_info.total_price_with_all_discounts) AS sum
           FROM public.transaction_info
          WHERE (transaction_info.customer_id = customers.id)) DESC;


ALTER TABLE public.top_customers OWNER TO postgres;

--
-- TOC entry 210 (class 1259 OID 16767)
-- Name: total_price_discounts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.total_price_discounts (
    min_price double precision NOT NULL,
    value double precision NOT NULL,
    CONSTRAINT min_price CHECK ((min_price > (0.0)::double precision)),
    CONSTRAINT value CHECK (((value > (0.0)::double precision) AND (value <= (1.0)::double precision)))
);


ALTER TABLE public.total_price_discounts OWNER TO postgres;

--
-- TOC entry 207 (class 1259 OID 16735)
-- Name: transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.transactions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 3011 (class 0 OID 16694)
-- Dependencies: 203
-- Data for Name: customers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.customers (id, phone_number, contact_name, address) FROM stdin;
1	9999999991	Alex Smith	51 Main Ave
2	9999999992	John Doe	30 One Street
3	9999999993	Ivan Smirnov	42 Sth Road
93	79609999999	Customer OK	A 123
\.


--
-- TOC entry 3017 (class 0 OID 16747)
-- Dependencies: 209
-- Data for Name: product_discounts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.product_discounts (product_id, min_amount, value) FROM stdin;
1	100	0.2
1	10	0.05
3	3	0.3
\.


--
-- TOC entry 3010 (class 0 OID 16686)
-- Dependencies: 202
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.products (id, name, wholesale_price, retail_price, description) FROM stdin;
1	Product A	80	100	Description of "Product A"
2	Product B	300	450	Description of "Product B"
3	Product C	11500	15000	Description of "Product C"
\.


--
-- TOC entry 3016 (class 0 OID 16737)
-- Dependencies: 208
-- Data for Name: sold_products; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sold_products (transaction_id, product_id, amount) FROM stdin;
1	1	120
1	2	30
3	1	1000
3	2	1000
3	3	1000
4	3	1
5	1	50
\.


--
-- TOC entry 3018 (class 0 OID 16767)
-- Dependencies: 210
-- Data for Name: total_price_discounts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.total_price_discounts (min_price, value) FROM stdin;
10000	0.05
100000	0.1
1000000	0.15
\.


--
-- TOC entry 3012 (class 0 OID 16702)
-- Dependencies: 204
-- Data for Name: transactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.transactions (id, "time", customer_id, is_wholesale) FROM stdin;
1	2020-05-20 01:20:33	2	t
3	2020-05-24 12:30:54	3	t
4	2020-05-24 15:40:00	1	f
5	2020-05-24 19:00:42	1	t
\.


--
-- TOC entry 3025 (class 0 OID 0)
-- Dependencies: 205
-- Name: customers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.customers_id_seq', 94, true);


--
-- TOC entry 3026 (class 0 OID 0)
-- Dependencies: 206
-- Name: products_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.products_id_seq', 3, true);


--
-- TOC entry 3027 (class 0 OID 0)
-- Dependencies: 207
-- Name: transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.transactions_id_seq', 5, true);


--
-- TOC entry 2867 (class 2606 OID 16701)
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (id);


--
-- TOC entry 2863 (class 2606 OID 16795)
-- Name: products name; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT name UNIQUE (name) INCLUDE (name);


--
-- TOC entry 2873 (class 2606 OID 16751)
-- Name: product_discounts product_discounts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_discounts
    ADD CONSTRAINT product_discounts_pkey PRIMARY KEY (product_id, min_amount);


--
-- TOC entry 2865 (class 2606 OID 16693)
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- TOC entry 2871 (class 2606 OID 16741)
-- Name: sold_products sold_products_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sold_products
    ADD CONSTRAINT sold_products_pkey PRIMARY KEY (transaction_id, product_id);


--
-- TOC entry 2875 (class 2606 OID 16771)
-- Name: total_price_discounts total_price_discounts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.total_price_discounts
    ADD CONSTRAINT total_price_discounts_pkey PRIMARY KEY (min_price);


--
-- TOC entry 2869 (class 2606 OID 16706)
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- TOC entry 2880 (class 2620 OID 16798)
-- Name: customers verify_phone_number; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER verify_phone_number BEFORE INSERT ON public.customers FOR EACH ROW EXECUTE FUNCTION public.check_phone_number();


--
-- TOC entry 2876 (class 2606 OID 16742)
-- Name: transactions customer_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT customer_id FOREIGN KEY (customer_id) REFERENCES public.customers(id);


--
-- TOC entry 2878 (class 2606 OID 16762)
-- Name: sold_products product_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sold_products
    ADD CONSTRAINT product_id FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- TOC entry 2879 (class 2606 OID 16826)
-- Name: product_discounts product_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_discounts
    ADD CONSTRAINT product_id FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- TOC entry 2877 (class 2606 OID 16757)
-- Name: sold_products transaction_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sold_products
    ADD CONSTRAINT transaction_id FOREIGN KEY (transaction_id) REFERENCES public.transactions(id);


-- Completed on 2020-05-26 00:50:32 MSK

--
-- PostgreSQL database dump complete
--

