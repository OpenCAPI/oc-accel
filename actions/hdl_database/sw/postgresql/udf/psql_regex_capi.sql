CREATE OR REPLACE FUNCTION psql_regex_capi_win(text, text) RETURNS int
AS '$libdir/psql_regex_capi', 'psql_regex_capi_win'
LANGUAGE C IMMUTABLE STRICT WINDOW;

CREATE OR REPLACE FUNCTION psql_regex_capi(text, text, int)
RETURNS cstring
AS '$libdir/psql_regex_capi', 'psql_regex_capi'
LANGUAGE C STRICT;
