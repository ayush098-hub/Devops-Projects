-- =========================================================
-- 1) EXTENSION + SCHEMA
-- =========================================================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE SCHEMA IF NOT EXISTS expense_tracker;

SET search_path TO expense_tracker, public;

-- =========================================================
-- 2) ENUM TYPES
-- =========================================================
DO $$ BEGIN
    CREATE TYPE expense_tracker.transaction_type AS ENUM ('INCOME', 'EXPENSE');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE expense_tracker.category_type AS ENUM ('INCOME', 'EXPENSE', 'BOTH');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE expense_tracker.frequency_type AS ENUM ('DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE expense_tracker.payment_mode_type AS ENUM (
        'CASH',
        'UPI',
        'CARD',
        'BANK_TRANSFER',
        'WALLET',
        'OTHER'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- =========================================================
-- 3) UPDATED_AT TRIGGER FUNCTION
-- =========================================================
CREATE OR REPLACE FUNCTION expense_tracker.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =========================================================
-- 4) USERS
-- =========================================================
CREATE TABLE IF NOT EXISTS expense_tracker.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    currency_code VARCHAR(10) NOT NULL DEFAULT 'INR',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS trg_users_updated_at ON expense_tracker.users;
CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON expense_tracker.users
FOR EACH ROW
EXECUTE FUNCTION expense_tracker.set_updated_at();

-- =========================================================
-- 5) CATEGORIES
-- =========================================================
CREATE TABLE IF NOT EXISTS expense_tracker.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    name VARCHAR(100) NOT NULL,
    type expense_tracker.category_type NOT NULL DEFAULT 'EXPENSE',
    icon VARCHAR(100),
    color VARCHAR(20),
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_categories_user
        FOREIGN KEY (user_id) REFERENCES expense_tracker.users(id)
        ON DELETE CASCADE,

    CONSTRAINT uq_categories_user_name
        UNIQUE (user_id, name)
);

CREATE INDEX IF NOT EXISTS idx_categories_user_id
    ON expense_tracker.categories(user_id);

DROP TRIGGER IF EXISTS trg_categories_updated_at ON expense_tracker.categories;
CREATE TRIGGER trg_categories_updated_at
BEFORE UPDATE ON expense_tracker.categories
FOR EACH ROW
EXECUTE FUNCTION expense_tracker.set_updated_at();

-- =========================================================
-- 6) TRANSACTIONS
-- =========================================================
CREATE TABLE IF NOT EXISTS expense_tracker.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    category_id UUID,
    type expense_tracker.transaction_type NOT NULL,
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    description TEXT,
    transaction_date DATE NOT NULL,
    payment_mode expense_tracker.payment_mode_type NOT NULL DEFAULT 'OTHER',
    reference_number VARCHAR(100),
    is_recurring BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_transactions_user
        FOREIGN KEY (user_id) REFERENCES expense_tracker.users(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_transactions_category
        FOREIGN KEY (category_id) REFERENCES expense_tracker.categories(id)
        ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_transactions_user_id
    ON expense_tracker.transactions(user_id);

CREATE INDEX IF NOT EXISTS idx_transactions_category_id
    ON expense_tracker.transactions(category_id);

CREATE INDEX IF NOT EXISTS idx_transactions_date
    ON expense_tracker.transactions(transaction_date);

CREATE INDEX IF NOT EXISTS idx_transactions_user_date
    ON expense_tracker.transactions(user_id, transaction_date);

DROP TRIGGER IF EXISTS trg_transactions_updated_at ON expense_tracker.transactions;
CREATE TRIGGER trg_transactions_updated_at
BEFORE UPDATE ON expense_tracker.transactions
FOR EACH ROW
EXECUTE FUNCTION expense_tracker.set_updated_at();

-- =========================================================
-- 7) BUDGETS
-- =========================================================
CREATE TABLE IF NOT EXISTS expense_tracker.budgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    category_id UUID NOT NULL,
    budget_month INT NOT NULL CHECK (budget_month BETWEEN 1 AND 12),
    budget_year INT NOT NULL CHECK (budget_year >= 2000),
    limit_amount NUMERIC(12,2) NOT NULL CHECK (limit_amount > 0),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_budgets_user
        FOREIGN KEY (user_id) REFERENCES expense_tracker.users(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_budgets_category
        FOREIGN KEY (category_id) REFERENCES expense_tracker.categories(id)
        ON DELETE CASCADE,

    CONSTRAINT uq_budget_user_category_month_year
        UNIQUE (user_id, category_id, budget_month, budget_year)
);

CREATE INDEX IF NOT EXISTS idx_budgets_user_id
    ON expense_tracker.budgets(user_id);

CREATE INDEX IF NOT EXISTS idx_budgets_category_id
    ON expense_tracker.budgets(category_id);

DROP TRIGGER IF EXISTS trg_budgets_updated_at ON expense_tracker.budgets;
CREATE TRIGGER trg_budgets_updated_at
BEFORE UPDATE ON expense_tracker.budgets
FOR EACH ROW
EXECUTE FUNCTION expense_tracker.set_updated_at();

-- =========================================================
-- 8) RECURRING RULES
-- =========================================================
CREATE TABLE IF NOT EXISTS expense_tracker.recurring_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    category_id UUID,
    type expense_tracker.transaction_type NOT NULL,
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    frequency expense_tracker.frequency_type NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    next_run_date DATE,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_recurring_rules_user
        FOREIGN KEY (user_id) REFERENCES expense_tracker.users(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_recurring_rules_category
        FOREIGN KEY (category_id) REFERENCES expense_tracker.categories(id)
        ON DELETE SET NULL,

    CONSTRAINT chk_recurring_dates
        CHECK (end_date IS NULL OR end_date >= start_date)
);

CREATE INDEX IF NOT EXISTS idx_recurring_rules_user_id
    ON expense_tracker.recurring_rules(user_id);

CREATE INDEX IF NOT EXISTS idx_recurring_rules_active
    ON expense_tracker.recurring_rules(active);

DROP TRIGGER IF EXISTS trg_recurring_rules_updated_at ON expense_tracker.recurring_rules;
CREATE TRIGGER trg_recurring_rules_updated_at
BEFORE UPDATE ON expense_tracker.recurring_rules
FOR EACH ROW
EXECUTE FUNCTION expense_tracker.set_updated_at();

-- =========================================================
-- 9) TAGS
-- =========================================================
CREATE TABLE IF NOT EXISTS expense_tracker.tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    name VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_tags_user
        FOREIGN KEY (user_id) REFERENCES expense_tracker.users(id)
        ON DELETE CASCADE,

    CONSTRAINT uq_tags_user_name
        UNIQUE (user_id, name)
);

CREATE INDEX IF NOT EXISTS idx_tags_user_id
    ON expense_tracker.tags(user_id);

DROP TRIGGER IF EXISTS trg_tags_updated_at ON expense_tracker.tags;
CREATE TRIGGER trg_tags_updated_at
BEFORE UPDATE ON expense_tracker.tags
FOR EACH ROW
EXECUTE FUNCTION expense_tracker.set_updated_at();

-- =========================================================
-- 10) TRANSACTION_TAGS (MANY-TO-MANY)
-- =========================================================
CREATE TABLE IF NOT EXISTS expense_tracker.transaction_tags (
    transaction_id UUID NOT NULL,
    tag_id UUID NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),

    PRIMARY KEY (transaction_id, tag_id),

    CONSTRAINT fk_transaction_tags_transaction
        FOREIGN KEY (transaction_id) REFERENCES expense_tracker.transactions(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_transaction_tags_tag
        FOREIGN KEY (tag_id) REFERENCES expense_tracker.tags(id)
        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_transaction_tags_tag_id
    ON expense_tracker.transaction_tags(tag_id);

-- =========================================================
-- 11) OPTIONAL: DEFAULT CATEGORIES TEMPLATE
--     Run this ONLY after inserting a real user.
-- =========================================================
-- INSERT INTO expense_tracker.categories (user_id, name, type, icon, color, is_default)
-- VALUES
-- ('<REAL_USER_ID>', 'Food', 'EXPENSE', 'utensils', '#F97316', TRUE),
-- ('<REAL_USER_ID>', 'Rent', 'EXPENSE', 'home', '#3B82F6', TRUE),
-- ('<REAL_USER_ID>', 'Salary', 'INCOME', 'wallet', '#22C55E', TRUE);
