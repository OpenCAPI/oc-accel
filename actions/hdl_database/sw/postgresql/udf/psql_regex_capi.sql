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
CREATE OR REPLACE FUNCTION psql_regex_capi_win(text, text) RETURNS int
AS '$libdir/psql_regex_capi', 'psql_regex_capi_win'
LANGUAGE C IMMUTABLE STRICT WINDOW;

CREATE OR REPLACE FUNCTION psql_regex_capi(text, text, int)
RETURNS cstring
AS '$libdir/psql_regex_capi', 'psql_regex_capi'
LANGUAGE C STRICT;
