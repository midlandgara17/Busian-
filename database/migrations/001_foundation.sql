
-- ============================================================
-- BUSIAN FOUNDATION DATABASE
-- Migration: 001_foundation.sql
-- Database: PostgreSQL
-- ============================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================
-- USERS
-- ============================================================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100),

    phone VARCHAR(30),
    email VARCHAR(255),

    password_hash TEXT NOT NULL,

    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_login_at TIMESTAMPTZ,

    CONSTRAINT users_status_check
        CHECK (status IN (
            'ACTIVE',
            'SUSPENDED',
            'BLOCKED',
            'PENDING',
            'DELETED'
        ))
);

CREATE UNIQUE INDEX users_email_unique_idx
ON users (LOWER(email))
WHERE email IS NOT NULL;

CREATE UNIQUE INDEX users_phone_unique_idx
ON users (phone)
WHERE phone IS NOT NULL;


-- ============================================================
-- ROLES
-- ============================================================

CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name VARCHAR(50) NOT NULL UNIQUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- USER ROLES
-- ============================================================

CREATE TABLE user_roles (
    user_id UUID NOT NULL,
    role_id UUID NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (user_id, role_id),

    FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    FOREIGN KEY (role_id)
        REFERENCES roles(id)
        ON DELETE CASCADE
);


-- ============================================================
-- COUNTRIES
-- ============================================================

CREATE TABLE countries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name VARCHAR(100) NOT NULL,
    code VARCHAR(10) NOT NULL UNIQUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- COUNTIES
-- ============================================================

CREATE TABLE counties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    country_id UUID NOT NULL,

    name VARCHAR(100) NOT NULL,
    code VARCHAR(20),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    FOREIGN KEY (country_id)
        REFERENCES countries(id)
        ON DELETE RESTRICT,

    UNIQUE (country_id, name)
);

CREATE INDEX counties_country_idx
ON counties (country_id);


-- ============================================================
-- SUB-COUNTIES
-- ============================================================

CREATE TABLE sub_counties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    county_id UUID NOT NULL,

    name VARCHAR(100) NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    FOREIGN KEY (county_id)
        REFERENCES counties(id)
        ON DELETE RESTRICT,

    UNIQUE (county_id, name)
);

CREATE INDEX sub_counties_county_idx
ON sub_counties (county_id);


-- ============================================================
-- TOWNS
-- ============================================================

CREATE TABLE towns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    sub_county_id UUID NOT NULL,

    name VARCHAR(100) NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    FOREIGN KEY (sub_county_id)
        REFERENCES sub_counties(id)
        ON DELETE RESTRICT,

    UNIQUE (sub_county_id, name)
);

CREATE INDEX towns_sub_county_idx
ON towns (sub_county_id);


-- ============================================================
-- AREAS
-- ============================================================

CREATE TABLE areas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    town_id UUID NOT NULL,

    name VARCHAR(100) NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    FOREIGN KEY (town_id)
        REFERENCES towns(id)
        ON DELETE RESTRICT,

    UNIQUE (town_id, name)
);

CREATE INDEX areas_town_idx
ON areas (town_id);


-- ============================================================
-- DELIVERY ZONES
-- ============================================================

CREATE TABLE delivery_zones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    area_id UUID NOT NULL,

    name VARCHAR(100) NOT NULL,

    delivery_fee NUMERIC(12,2) NOT NULL DEFAULT 0,
    estimated_minutes INTEGER,

    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    FOREIGN KEY (area_id)
        REFERENCES areas(id)
        ON DELETE RESTRICT,

    CHECK (delivery_fee >= 0),

    CHECK (
        estimated_minutes IS NULL
        OR estimated_minutes >= 0
    ),

    CHECK (status IN (
        'ACTIVE',
        'INACTIVE'
    )),

    UNIQUE (area_id, name)
);

CREATE INDEX delivery_zones_area_idx
ON delivery_zones (area_id);


-- ============================================================
-- ADDRESSES
-- ============================================================

CREATE TABLE addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL,

    country_id UUID,
    county_id UUID,
    sub_county_id UUID,
    town_id UUID,
    area_id UUID,
    delivery_zone_id UUID,

    address_line VARCHAR(255),
    building VARCHAR(150),
    floor VARCHAR(50),

    latitude NUMERIC(10,7),
    longitude NUMERIC(10,7),

    delivery_instructions TEXT,

    is_default BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    FOREIGN KEY (country_id)
        REFERENCES countries(id)
        ON DELETE RESTRICT,

    FOREIGN KEY (county_id)
        REFERENCES counties(id)
        ON DELETE RESTRICT,

    FOREIGN KEY (sub_county_id)
        REFERENCES sub_counties(id)
        ON DELETE RESTRICT,

    FOREIGN KEY (town_id)
        REFERENCES towns(id)
        ON DELETE RESTRICT,

    FOREIGN KEY (area_id)
        REFERENCES areas(id)
        ON DELETE RESTRICT,

    FOREIGN KEY (delivery_zone_id)
        REFERENCES delivery_zones(id)
        ON DELETE RESTRICT,

    CHECK (
        latitude IS NULL
        OR latitude BETWEEN -90 AND 90
    ),

    CHECK (
        longitude IS NULL
        OR longitude BETWEEN -180 AND 180
    )
);

CREATE INDEX addresses_user_idx
ON addresses (user_id);

CREATE INDEX addresses_delivery_zone_idx
ON addresses (delivery_zone_id);

CREATE UNIQUE INDEX addresses_one_default_per_user_idx
ON addresses (user_id)
WHERE is_default = TRUE;


-- ============================================================
-- MERCHANTS
-- ============================================================

CREATE TABLE merchants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    owner_user_id UUID NOT NULL,

    business_name VARCHAR(200) NOT NULL,
    business_type VARCHAR(100),

    description TEXT,

    phone VARCHAR(30),
    email VARCHAR(255),

    logo_url TEXT,

    status VARCHAR(30) NOT NULL DEFAULT 'PENDING',

    verification_status VARCHAR(30)
        NOT NULL DEFAULT 'PENDING',

    rating NUMERIC(3,2) NOT NULL DEFAULT 0,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    FOREIGN KEY (owner_user_id)
        REFERENCES users(id)
        ON DELETE RESTRICT,

    CHECK (status IN (
        'PENDING',
        'ACTIVE',
        'SUSPENDED',
        'BLOCKED',
        'CLOSED'
    )),

    CHECK (verification_status IN (
        'PENDING',
        'UNDER_REVIEW',
        'VERIFIED',
        'REJECTED'
    )),

    CHECK (rating BETWEEN 0 AND 5)
);

CREATE INDEX merchants_owner_idx
ON merchants (owner_user_id);

CREATE INDEX merchants_status_idx
ON merchants (status);


-- ============================================================
-- MERCHANT BRANCHES
-- ============================================================

CREATE TABLE merchant_branches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    merchant_id UUID NOT NULL,

    name VARCHAR(150) NOT NULL,

    address_id UUID,

    phone VARCHAR(30),

    opening_time TIME,
    closing_time TIME,

    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    FOREIGN KEY (merchant_id)
        REFERENCES merchants(id)
        ON DELETE CASCADE,

    FOREIGN KEY (address_id)
        REFERENCES addresses(id)
        ON DELETE SET NULL,

    CHECK (status IN (
        'ACTIVE',
        'INACTIVE',
        'CLOSED'
    ))
);

CREATE INDEX merchant_branches_merchant_idx
ON merchant_branches (merchant_id);


-- ============================================================
-- CATEGORIES
-- ============================================================

CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    parent_id UUID,

    name VARCHAR(150) NOT NULL,
    slug VARCHAR(180) NOT NULL UNIQUE,

    description TEXT,
    image_url TEXT,

    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',

    sort_order INTEGER NOT NULL DEFAULT 0,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    FOREIGN KEY (parent_id)
        REFERENCES categories(id)
        ON DELETE SET NULL,

    CHECK (status IN (
        'ACTIVE',
        'INACTIVE'
    ))
);

CREATE INDEX categories_parent_idx
ON categories (parent_id);


-- ============================================================
-- PRODUCTS
-- ============================================================

CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    merchant_id UUID NOT NULL,
    branch_id UUID,

    name VARCHAR(200) NOT NULL,
    slug VARCHAR(220) NOT NULL,

    description TEXT,

    product_type VARCHAR(50),
    brand VARCHAR(150),

    sku VARCHAR(100),

    price NUMERIC(12,2) NOT NULL,

    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    FOREIGN KEY (merchant_id)
        REFERENCES merchants(id)
        ON DELETE CASCADE,

    FOREIGN KEY (branch_id)
        REFERENCES merchant_branches(id)
        ON DELETE SET NULL,

    CHECK (price >= 0),

    CHECK (status IN (
        'DRAFT',
        'ACTIVE',
        'INACTIVE',
        'OUT_OF_STOCK',
        'ARCHIVED'
    )),

    UNIQUE (merchant_id, slug)
);

CREATE INDEX products_merchant_idx
ON products (merchant_id);

CREATE INDEX products_branch_idx
ON products (branch_id);

CREATE INDEX products_status_idx
ON products (status);


-- ============================================================
-- PRODUCT CATEGORIES
-- ============================================================

CREATE TABLE product_categories (
    product_id UUID NOT NULL,
    category_id UUID NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (product_id, category_id),

    FOREIGN KEY (product_id)
        REFERENCES products(id)
        ON DELETE CASCADE,

    FOREIGN KEY (category_id)
        REFERENCES categories(id)
        ON DELETE CASCADE
);

CREATE INDEX product_categories_category_idx
ON product_categories (category_id);


-- ============================================================
-- PRODUCT IMAGES
-- ============================================================

CREATE TABLE product_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    product_id UUID NOT NULL,

    image_url TEXT NOT NULL,

    sort_order INTEGER NOT NULL DEFAULT 0,

    is_primary BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    FOREIGN KEY (product_id)
        REFERENCES products(id)
        ON DELETE CASCADE
);

CREATE INDEX product_images_product_idx
ON product_images (product_id);

CREATE UNIQUE INDEX product_images_one_primary_idx
ON product_images (product_id)
WHERE is_primary = TRUE;


-- ============================================================
-- INITIAL ROLES
-- ============================================================

INSERT INTO roles (name)
VALUES
    ('CUSTOMER'),
    ('MERCHANT'),
    ('MERCHANT_STAFF'),
    ('RIDER'),
    ('BUSINESS_MEMBER'),
    ('BUSINESS_ADMIN'),
    ('BUSIAN_ADMIN'),
    ('SUPER_ADMIN')
ON CONFLICT (name) DO NOTHING;


-- ============================================================
-- UPDATED_AT FUNCTION
-- ============================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- ============================================================
-- UPDATED_AT TRIGGERS
-- ============================================================

CREATE TRIGGER users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER delivery_zones_updated_at
BEFORE UPDATE ON delivery_zones
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER addresses_updated_at
BEFORE UPDATE ON addresses
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER merchants_updated_at
BEFORE UPDATE ON merchants
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER merchant_branches_updated_at
BEFORE UPDATE ON merchant_branches
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER categories_updated_at
BEFORE UPDATE ON categories
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER products_updated_at
BEFORE UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

COMMIT;
