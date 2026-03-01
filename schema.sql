-- International Student Wellbeing Analytics Database Schema
-- Database: student_db
-- Purpose: Store and analyze mental health metrics for international student populations
-- Author: Teslim Uthman Adeyanju
-- Date: February 28, 2026

-- Create database if not exists
CREATE DATABASE IF NOT EXISTS student_db
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE student_db;

-- Primary Table: Students Mental Health Metrics
-- Normalized structure (3NF) for analytical queries
CREATE TABLE IF NOT EXISTS students (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique student identifier',
    inter_dom VARCHAR(10) NOT NULL COMMENT 'Student classification: Inter (International) or Dom (Domestic)',
    region VARCHAR(50) COMMENT 'Geographic region: SEA, EA, SA, Others, JAP',
    stay INT NOT NULL COMMENT 'Duration of enrollment in years (1-10)',
    todep DECIMAL(5,2) NOT NULL COMMENT 'PHQ-9 Depression Score (0-50)',
    tosc DECIMAL(5,2) NOT NULL COMMENT 'Social Connectedness Scale Score (0-100)',
    toas DECIMAL(5,2) NOT NULL COMMENT 'Anxiety Scale Score (0-100)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation timestamp',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Record update timestamp',
    
    -- Indexes for query performance
    INDEX idx_inter_dom (inter_dom) COMMENT 'Index for student classification queries',
    INDEX idx_stay (stay) COMMENT 'Index for stay duration analysis',
    INDEX idx_region (region) COMMENT 'Index for regional analysis',
    
    -- Constraints
    CHECK (stay >= 1 AND stay <= 10) COMMENT 'Valid stay duration range',
    CHECK (todep >= 0 AND todep <= 50) COMMENT 'Valid PHQ-9 score range',
    CHECK (tosc >= 0 AND tosc <= 100) COMMENT 'Valid SCS score range',
    CHECK (toas >= 0 AND toas <= 100) COMMENT 'Valid anxiety score range',
    CHECK (inter_dom IN ('Inter', 'Dom')) COMMENT 'Valid student classification'
) ENGINE=InnoDB
CHARSET=utf8mb4
COLLATE=utf8mb4_unicode_ci
COMMENT='Core table for international student mental health metrics';

-- Optional: Second Normal Form Table for Region Reference Data
CREATE TABLE IF NOT EXISTS regions (
    region_id INT AUTO_INCREMENT PRIMARY KEY,
    region_name VARCHAR(50) NOT NULL UNIQUE,
    region_code VARCHAR(10),
    description VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    KEY idx_region_name (region_name)
) ENGINE=InnoDB
CHARSET=utf8mb4
COLLATE=utf8mb4_unicode_ci
COMMENT='Reference table for geographic regions';

-- Optional: Second Normal Form Table for Student Status Reference
CREATE TABLE IF NOT EXISTS student_classifications (
    classification_id INT AUTO_INCREMENT PRIMARY KEY,
    classification_code VARCHAR(10) NOT NULL UNIQUE,
    classification_name VARCHAR(50) NOT NULL,
    description VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    KEY idx_code (classification_code)
) ENGINE=InnoDB
CHARSET=utf8mb4
COLLATE=utf8mb4_unicode_ci
COMMENT='Reference table for student classifications';

-- Optional: Third Normal Form Table for Assessment Metadata
CREATE TABLE IF NOT EXISTS assessments (
    assessment_id INT AUTO_INCREMENT PRIMARY KEY,
    assessment_name VARCHAR(50) NOT NULL UNIQUE,
    assessment_code VARCHAR(10),
    min_score DECIMAL(5,2),
    max_score DECIMAL(5,2),
    description VARCHAR(300),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    KEY idx_code (assessment_code)
) ENGINE=InnoDB
CHARSET=utf8mb4
COLLATE=utf8mb4_unicode_ci
COMMENT='Reference table for psychological assessment instruments';

-- Sample data insertion for reference tables
INSERT INTO regions (region_name, region_code, description) VALUES
('Southeast Asia', 'SEA', 'Students from Southeast Asian nations'),
('East Asia', 'EA', 'Students from East Asian nations'),
('South Asia', 'SA', 'Students from South Asian nations'),
('Japan', 'JAP', 'Students from Japan'),
('Others', 'OTHER', 'Students from other regions');

INSERT INTO student_classifications (classification_code, classification_name, description) VALUES
('Inter', 'International', 'International student status'),
('Dom', 'Domestic', 'Domestic student status');

INSERT INTO assessments (assessment_name, assessment_code, min_score, max_score, description) VALUES
('PHQ-9 Depression', 'PHQ9', 0, 50, 'Patient Health Questionnaire-9 for depression screening'),
('Social Connectedness Scale', 'SCS', 0, 100, 'Measure of social connectedness and belonging'),
('Anxiety Scale', 'ASISS', 0, 100, 'Anxiety Sensitivity Index and Social Interaction Scales');

-- Data Dictionary for students table
-- =================================================================================
-- Field Name    | Type      | Description
-- =================================================================================
-- id            | INT       | Unique identifier for each student record
-- inter_dom     | VARCHAR   | Student type (Inter=International, Dom=Domestic)
-- region        | VARCHAR   | Geographic origin (SEA, EA, SA, JAP, Others)
-- stay          | INT       | Years of enrollment (1-10 years)
-- todep         | DECIMAL   | PHQ-9 depression score (0-50, higher = more depression)
-- tosc          | DECIMAL   | Social connectedness score (0-100, higher = more connected)
-- toas          | DECIMAL   | Anxiety scale score (0-100, higher = more anxiety)
-- created_at    | TIMESTAMP | Time record was created
-- updated_at    | TIMESTAMP | Time record was last updated

-- Database Design Notes
-- =================================================================================
-- NORMALIZATION LEVEL: Third Normal Form (3NF)
-- - No repeating groups (1NF)
-- - No partial dependencies (2NF)
-- - No transitive dependencies (3NF)
-- 
-- INDEXING STRATEGY:
-- - Composite key on frequently queried dimensions
-- - Individual indexes on join columns
-- - Separate index on numeric columns for range queries
--
-- CONSTRAINTS:
-- - CHECK constraints on valid ranges for all scores
-- - NOT NULL constraints on key metrics
-- - UNIQUE constraints on reference data
-- 
-- CHARACTER SET: UTF-8 MB4 ensures international character support
--
-- ENGINE: InnoDB for transaction support and referential integrity
