CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE admin_role_enum AS ENUM ('moderator', 'analyst', 'supervisor');
CREATE TYPE report_status_enum AS ENUM ('submitted', 'under_review', 'approved', 'rejected', 'archived');
CREATE TYPE brief_status_enum AS ENUM ('queued', 'generated', 'published');

CREATE TABLE admin_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role admin_role_enum NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE incident_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE location_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE incident_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    public_reference TEXT NOT NULL UNIQUE,
    category_id UUID NOT NULL REFERENCES incident_categories(id),
    location_type_id UUID NOT NULL REFERENCES location_types(id),
    occurred_at TIMESTAMPTZ NOT NULL,
    reported_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    description TEXT,
    geom GEOMETRY(Point, 4326) NOT NULL,
    approx_area_name TEXT,
    ward_or_district TEXT,
    language_code VARCHAR(10) NOT NULL DEFAULT 'en',
    consent_acknowledged BOOLEAN NOT NULL,
    status report_status_enum NOT NULL DEFAULT 'submitted',
    duplicate_of_report_id UUID REFERENCES incident_reports(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_occurred_at_not_future CHECK (occurred_at <= NOW()),
    CONSTRAINT chk_consent_acknowledged CHECK (consent_acknowledged = TRUE)
);

CREATE INDEX idx_incident_reports_category_id ON incident_reports(category_id);
CREATE INDEX idx_incident_reports_location_type_id ON incident_reports(location_type_id);
CREATE INDEX idx_incident_reports_occurred_at ON incident_reports(occurred_at);
CREATE INDEX idx_incident_reports_status ON incident_reports(status);
CREATE INDEX idx_incident_reports_geom ON incident_reports USING GIST (geom);

CREATE TABLE report_status_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID NOT NULL REFERENCES incident_reports(id) ON DELETE CASCADE,
    previous_status report_status_enum,
    new_status report_status_enum NOT NULL,
    moderation_note TEXT,
    changed_by_admin_id UUID REFERENCES admin_users(id),
    changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_report_status_history_report_id ON report_status_history(report_id);
CREATE INDEX idx_report_status_history_changed_at ON report_status_history(changed_at);

CREATE TABLE monthly_briefs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    date_from DATE NOT NULL,
    date_to DATE NOT NULL,
    status brief_status_enum NOT NULL DEFAULT 'queued',
    summary_text TEXT,
    file_path TEXT,
    generated_by_admin_id UUID REFERENCES admin_users(id),
    generated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_monthly_briefs_date_range CHECK (date_to >= date_from)
);

CREATE INDEX idx_monthly_briefs_date_from ON monthly_briefs(date_from);
CREATE INDEX idx_monthly_briefs_date_to ON monthly_briefs(date_to);

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_user_id UUID REFERENCES admin_users(id),
    action_type TEXT NOT NULL,
    target_type TEXT NOT NULL,
    target_id UUID,
    details JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_admin_user_id ON audit_logs(admin_user_id);
CREATE INDEX idx_audit_logs_action_type ON audit_logs(action_type);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);

INSERT INTO incident_categories (code, name, description, sort_order) VALUES
('VERBAL', 'Verbal harassment', 'Insults, catcalling, or abusive verbal behavior.', 1),
('STALKING', 'Stalking or persistent following', 'Following or monitoring a person without consent.', 2),
('GESTURES', 'Unwanted sexual comments or gestures', 'Sexualized gestures, sounds, or propositions.', 3),
('TOUCHING', 'Unwanted touching', 'Non-consensual physical contact.', 4),
('THREAT', 'Physical intimidation or threat', 'Threatening behavior or menacing conduct.', 5),
('ASSAULT', 'Physical assault', 'Direct physical attack or violence.', 6),
('AUTHORITY_ABUSE', 'Coercion, extortion, or abuse by authority figure', 'Abuse involving transport staff, police, guards, or other authority figures.', 7),
('OTHER', 'Other gender-based safety incident', 'Any incident not covered by the categories above.', 8);

INSERT INTO location_types (code, name, description, sort_order) VALUES
('STREET', 'Street or roadside', 'Open roads, walkways, and roadside corridors.', 1),
('BUS_STOP', 'Bus stop or transport terminal', 'Formal or informal transport waiting points.', 2),
('PUBLIC_TRANSPORT', 'Public transport vehicle', 'Buses, minibuses, taxis, or shared transport.', 3),
('MARKET', 'Market or shopping area', 'Markets, malls, shops, and busy trading areas.', 4),
('SCHOOL', 'School or university area', 'Education facilities and surrounding grounds.', 5),
('WORKPLACE', 'Workplace or office area', 'Work-related locations and office zones.', 6),
('PARK', 'Park or recreation area', 'Public gardens, fields, and recreation zones.', 7),
('ENTERTAINMENT', 'Bar, club, or entertainment area', 'Nightlife or leisure spaces.', 8),
('RESIDENTIAL', 'Residential area', 'Neighborhoods and housing-adjacent public space.', 9),
('OTHER', 'Other public space', 'Any other public or semi-public location.', 10);
