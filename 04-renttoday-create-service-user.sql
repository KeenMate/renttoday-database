-- Recreates service user with limited permissions that you can use for your applications

DROP OWNED BY renttoday; -- remove old permissions of the user
DROP ROLE IF EXISTS renttoday; -- remove the user
CREATE ROLE renttoday WITH LOGIN PASSWORD 'passwd'; -- create it again and assign proper permissions

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO renttoday;
GRANT SELECT ON ALL TABLES IN SCHEMA const TO renttoday;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA helpers TO renttoday;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO renttoday;

GRANT CONNECT ON DATABASE renttoday TO renttoday;