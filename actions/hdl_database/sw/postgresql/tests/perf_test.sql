--
-- Copyright 2019 International Business Machines
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
SET client_min_messages = warning;
\set ECHO none
\set ECHO all
RESET client_min_messages;

-- Create the perf test data tables if not exist
CREATE OR REPLACE FUNCTION create_table()
RETURNS void AS
$_$
DECLARE
r           character varying;    
_cmd        text;
split_data  text[];
BEGIN
    SELECT INTO split_data regexp_split_to_array('4K,8K,16K,32K,64K,128K,256K,512K',',');
    FOREACH r IN array split_data LOOP
        _cmd := 
            format(
                'CREATE TABLE IF NOT EXISTS perf_test_%1$s(pkt text, id SERIAL);',
                r
            );
        EXECUTE _cmd;
    END LOOP;
END;
$_$ LANGUAGE plpgsql;

-- Copy data to perf test data tables if not exist
CREATE OR REPLACE FUNCTION count_line(tbl text) RETURNS INTEGER
AS $$
DECLARE total INTEGER;
BEGIN
    EXECUTE format('select count(*) from %s limit 1', tbl) into total;
    RETURN total::integer;
END;
$$  LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION copy_if_not_exists ()
RETURNS void AS
$_$
DECLARE
r           character varying;    
_cmd        text;
split_data  text[];
BEGIN
    SELECT INTO split_data regexp_split_to_array('4K,8K,16K,32K,64K,128K,256K,512K',',');
    FOREACH r IN array split_data LOOP
        IF count_line(format('perf_test_%s', r)) = 0 THEN
            _cmd := 
                format(
                    'COPY perf_test_%1$s (pkt) FROM ''/home/postgres/capi/tests/perf_test/packet.1024.%1$s.txt'' DELIMITER '' ''; ',
                    r
                );
            EXECUTE _cmd;
        END IF;
    END LOOP;
END;
$_$ LANGUAGE plpgsql;

-- Create tables to store perf data
--CREATE table if not exists perf_data (test_name text, regex_capi text, regex_capi_win text, regexp_matches text, where_clause text, ts timestamp);
CREATE table if not exists perf_data (test_name text, regex_capi double precision, regex_capi_win double precision, where_clause double precision, ts timestamp);
CREATE table if not exists psql_regex_capi_perf_breakdown_tmp (results text, ts timestamp);

CREATE OR REPLACE FUNCTION measure_run_time(cmd text, no_of_runs integer)
RETURNS FLOAT AS
$func$
declare c integer; results text; tmp text; sum float; max float; min float;
BEGIN
    c := 0;
    sum := 0.0;
    max := 0.0;
    raise notice 'cmd to run: %s', cmd;
    LOOP EXIT WHEN c = no_of_runs; c := c + 1;
        execute format('EXPLAIN (ANALYZE, FORMAT JSON) %1$s', cmd) into results;
        tmp := results::jsonb-> 0 -> 'Execution Time'; 
        sum := sum + tmp::float;
        raise notice '%f', tmp::float;
        IF c = 1 THEN
            min := tmp::float;
        END IF;
        IF tmp::float > max THEN
            max := tmp::float;
        END IF;
        IF tmp::float < min THEN
            min := tmp::float;
        END IF;
    END LOOP;
    RAISE NOTICE 'Max: %f, Min: %f, Average run time: %f', max, min, (sum - max - min)/(no_of_runs - 2);
    RETURN (sum - max - min)/(no_of_runs - 2);
END;
$func$  LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION regex_capi_perf_test()
RETURNS void AS
$func$
DECLARE
v_table text;
rc_regexp double precision;
rc_where double precision;
rc_regex_capi double precision;
rc_regex_capi_win double precision;
--counter integer;
BEGIN
    FOR v_table IN
        SELECT table_name  
        FROM   information_schema.tables 
        WHERE  table_catalog = 'pengfei' 
        AND    table_schema = 'public'
        AND    table_name LIKE 'perf_test_%'
        LOOP
            --execute format('EXPLAIN (ANALYZE, FORMAT JSON) SELECT pkt, (regexp_matches(pkt, ''abc.*xyz''))[0] from %I'
            --    , v_table) into rc_regexp;
            --counter := 0;
            --loop exit when counter = 5;
                --execute format('EXPLAIN (ANALYZE, FORMAT JSON) SELECT * FROM %I WHERE pkt ~ ''abc.*xyz'''
                --    , v_table) into rc_where;

                rc_regex_capi := measure_run_time(format('INSERT INTO psql_regex_capi_perf_breakdown_tmp (results, ts) VALUES (psql_regex_capi(''%I'', ''abc.*xyz'', 0)::text, current_timestamp)'
                    , v_table), 10);

                --rc_regex_capi_win := measure_run_time(format('SELECT psql_regex_capi_win(pkt, ''abc.*xyz'') over(), pkt, id from %I'
                --    , v_table), 10);
                rc_where := measure_run_time(format('SELECT * FROM %I WHERE pkt ~ ''abc.*xyz'''
                    , v_table), 10);
                --execute format('EXPLAIN (ANALYZE, format JSON) INSERT INTO psql_regex_capi_perf_breakdown_tmp (results, ts) VALUES (psql_regex_capi(''%I'', ''abc.*xyz'', 0)::text, current_timestamp)'
                --    , v_table) into rc_regex_capi;
                --rc_regex_capi := measure_run_time(format('INSERT INTO psql_regex_capi_perf_breakdown_tmp (results, ts) VALUES (psql_regex_capi(''%I'', ''abc.*xyz'', 0)::text, current_timestamp)'
                --    , v_table), 10);
                --execute format('EXPLAIN (ANALYZE, format JSON) SELECT psql_regex_capi_win(pkt, ''abc.*xyz'') over(), pkt, id from %I'
                --    , v_table) into rc_regex_capi_win;
                --rc_regex_capi_win := measure_run_time(format('SELECT psql_regex_capi_win(pkt, ''abc.*xyz'') over(), pkt, id from %I'
                --    , v_table), 10);
                --insert into perf_data (test_name, regex_capi, regex_capi_win, regexp_matches, where_clause, ts) values (
                insert into perf_data (test_name, regex_capi, regex_capi_win, where_clause, ts) values (
                    format('%s', v_table),
                    rc_regex_capi, 0.0, rc_where,
                    --0.0, 0.0, rc_where,
                    --rc_regex_capi::jsonb-> 0 -> 'Execution Time',
                    --rc_regex_capi_win::jsonb-> 0 -> 'Execution Time',
                    --rc_regexp::jsonb-> 0 -> 'Execution Time',
                    --rc_where::jsonb-> 0 -> 'Execution Time',
                    current_timestamp
                ); 
                --counter := counter + 1;
            --end loop;
        END LOOP;
    END;
$func$  LANGUAGE plpgsql;

-- Perform the test
SELECT create_table();
SELECT copy_if_not_exists();
--SELECT regex_capi_perf_test();
--SELECT * from perf_data;
----SELECT * from psql_regex_capi_perf_breakdown_tmp;
--
---- Transform the performance table to a proper form
--create table if not exists psql_regex_capi_perf_breakdown (num_pkt bigint,pkt_size bigint,init bigint,patt bigint,pkt_cpy bigint,pkt_other bigint,hw_re_scan bigint,harvest bigint,cleanup bigint,hw_perf_mb_s float,num_matched_pkt integer,ts timestamp);
--insert into psql_regex_capi_perf_breakdown select a[1]::bigint as num_pkt, a[2]::bigint as pkt_size, a[3]::bigint as init, a[4]::bigint as patt, a[5]::bigint as pkt_cpy, a[6]::bigint as pkt_other, a[7]::bigint as hw_re_scan, a[8]::bigint as harvest, a[9]::bigint as cleanup, a[10]::float as hw_perf_mb_s, a[11]::integer as num_matched_pkt, current_timestamp as ts from (select string_to_array(results, ',') from psql_regex_capi_perf_breakdown_tmp) as dt(a);
--
--\copy perf_data TO './perf_data.csv' DELIMITER ',' CSV HEADER;
--\copy psql_regex_capi_perf_breakdown TO './psql_regex_capi_perf_breakdown.csv' DELIMITER ',' CSV HEADER;
--
--DROP table psql_regex_capi_perf_breakdown_tmp;
--DROP table perf_data;
