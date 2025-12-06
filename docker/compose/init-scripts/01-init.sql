-- LocalStore Platform - PostgreSQL Init Script
-- This script runs on first database initialization

-- Create required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Row-Level Security helper functions
-- Reference: specs/architecture/backend-setup-guide.md

-- Function to set current tenant for RLS
CREATE OR REPLACE FUNCTION set_current_tenant(tenant_uuid UUID)
RETURNS VOID AS $$
BEGIN
    PERFORM set_config('app.current_tenant_id', tenant_uuid::TEXT, FALSE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get current tenant for RLS policies
CREATE OR REPLACE FUNCTION get_current_tenant()
RETURNS UUID AS $$
BEGIN
    RETURN NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION set_current_tenant(UUID) TO PUBLIC;
GRANT EXECUTE ON FUNCTION get_current_tenant() TO PUBLIC;

-- Log successful initialization
DO $$
BEGIN
    RAISE NOTICE 'LocalStore Platform database initialized successfully';
    RAISE NOTICE 'RLS helper functions created: set_current_tenant(), get_current_tenant()';
END $$;
