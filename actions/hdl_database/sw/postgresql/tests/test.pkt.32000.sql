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
\set max_parallel_workers_per_gather 8
\set max_parallel_maintenance_workers 8
RESET client_min_messages;

CREATE TABLE IF NOT EXISTS sm_pkt_32000(pkt text, id SERIAL);

CREATE OR REPLACE FUNCTION copy_if_not_exists_pkt_32000 ()
RETURNS void AS
$_$
BEGIN
    IF NOT EXISTS (select * from sm_pkt_32000) THEN
        COPY sm_pkt_32000 (pkt) FROM '/home/pengfei/capi/db/snap/actions/hdl_stringmatch/tests/packets/packet.1024.32000.txt' DELIMITER ' ' ;
    END IF;
END;
$_$ LANGUAGE plpgsql;

SELECT copy_if_not_exists_pkt_32000();

explain analyze SELECT psql_regex_capi('sm_pkt_32000', 'abc.*xyz', 0);
explain analyze SELECT psql_regex_capi('sm_pkt_32000', 'abc.*xyz', 0);
explain analyze SELECT psql_regex_capi('sm_pkt_32000', 'abc.*xyz', 0);
explain analyze SELECT psql_regex_capi('sm_pkt_32000', 'abc.*xyz', 0);
explain analyze SELECT pkt, (regexp_matches(pkt, 'abc.*xyz'))[0] from sm_pkt_32000;
explain analyze SELECT * FROM sm_pkt_32000 WHERE pkt ~ 'abc.*xyz';
