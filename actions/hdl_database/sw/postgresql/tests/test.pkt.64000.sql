SET client_min_messages = warning;
\set ECHO none
\set ECHO all
\set max_parallel_workers_per_gather 8
\set max_parallel_maintenance_workers 8
RESET client_min_messages;

CREATE TABLE IF NOT EXISTS sm_pkt_64000(pkt text, id SERIAL);

CREATE OR REPLACE FUNCTION copy_if_not_exists_pkt_64000 ()
RETURNS void AS
$_$
BEGIN
    IF NOT EXISTS (select * from sm_pkt_64000) THEN
        COPY sm_pkt_64000 (pkt) FROM '/home/pengfei/capi/db/snap/actions/hdl_stringmatch/tests/packets/packet.1024.64000.txt' DELIMITER ' ' ;
    END IF;
END;
$_$ LANGUAGE plpgsql;

SELECT copy_if_not_exists_pkt_64000();

explain analyze SELECT psql_regex_capi('sm_pkt_64000', 'abc.*xyz', 0);
explain analyze SELECT psql_regex_capi('sm_pkt_64000', 'abc.*xyz', 0);
explain analyze SELECT psql_regex_capi('sm_pkt_64000', 'abc.*xyz', 0);
explain analyze SELECT psql_regex_capi('sm_pkt_64000', 'abc.*xyz', 0);
explain analyze SELECT pkt, (regexp_matches(pkt, 'abc.*xyz'))[0] from sm_pkt_64000;
explain analyze SELECT * FROM sm_pkt_64000 WHERE pkt ~ 'abc.*xyz';
