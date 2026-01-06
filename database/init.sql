-- GFOS Digital Idea Board - Database Schema
-- PostgreSQL 15+

-- Drop existing tables if they exist (for clean reinstall)
DROP TABLE IF EXISTS user_badges CASCADE;
DROP TABLE IF EXISTS badges CASCADE;
DROP TABLE IF EXISTS audit_logs CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS survey_votes CASCADE;
DROP TABLE IF EXISTS survey_options CASCADE;
DROP TABLE IF EXISTS surveys CASCADE;
DROP TABLE IF EXISTS comment_reactions CASCADE;
DROP TABLE IF EXISTS comments CASCADE;
DROP TABLE IF EXISTS likes CASCADE;
DROP TABLE IF EXISTS file_attachments CASCADE;
DROP TABLE IF EXISTS idea_tags CASCADE;
DROP TABLE IF EXISTS ideas CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Enum Types
DROP TYPE IF EXISTS user_role CASCADE;
DROP TYPE IF EXISTS idea_status CASCADE;
DROP TYPE IF EXISTS notification_type CASCADE;
DROP TYPE IF EXISTS audit_action CASCADE;

CREATE TYPE user_role AS ENUM ('EMPLOYEE', 'PROJECT_MANAGER', 'ADMIN');
CREATE TYPE idea_status AS ENUM ('CONCEPT', 'IN_PROGRESS', 'COMPLETED');
CREATE TYPE notification_type AS ENUM ('LIKE', 'COMMENT', 'REACTION', 'STATUS_CHANGE', 'BADGE_EARNED', 'LEVEL_UP', 'MENTION');
CREATE TYPE audit_action AS ENUM ('CREATE', 'UPDATE', 'DELETE', 'STATUS_CHANGE', 'LOGIN', 'LOGOUT');

-- =====================================================
-- USERS TABLE
-- =====================================================
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    role user_role NOT NULL DEFAULT 'EMPLOYEE',
    avatar_url VARCHAR(500),
    xp_points INTEGER NOT NULL DEFAULT 0,
    level INTEGER NOT NULL DEFAULT 1,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_login TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- =====================================================
-- IDEAS TABLE
-- =====================================================
CREATE TABLE ideas (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(100) NOT NULL,
    status idea_status NOT NULL DEFAULT 'CONCEPT',
    progress_percentage INTEGER NOT NULL DEFAULT 0 CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    author_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    like_count INTEGER NOT NULL DEFAULT 0,
    comment_count INTEGER NOT NULL DEFAULT 0,
    view_count INTEGER NOT NULL DEFAULT 0,
    is_featured BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ideas_author ON ideas(author_id);
CREATE INDEX idx_ideas_category ON ideas(category);
CREATE INDEX idx_ideas_status ON ideas(status);
CREATE INDEX idx_ideas_created_at ON ideas(created_at DESC);
CREATE INDEX idx_ideas_like_count ON ideas(like_count DESC);

-- =====================================================
-- IDEA TAGS TABLE
-- =====================================================
CREATE TABLE idea_tags (
    id BIGSERIAL PRIMARY KEY,
    idea_id BIGINT NOT NULL REFERENCES ideas(id) ON DELETE CASCADE,
    tag_name VARCHAR(50) NOT NULL,
    UNIQUE(idea_id, tag_name)
);

CREATE INDEX idx_idea_tags_idea ON idea_tags(idea_id);
CREATE INDEX idx_idea_tags_name ON idea_tags(tag_name);

-- =====================================================
-- FILE ATTACHMENTS TABLE
-- =====================================================
CREATE TABLE file_attachments (
    id BIGSERIAL PRIMARY KEY,
    idea_id BIGINT NOT NULL REFERENCES ideas(id) ON DELETE CASCADE,
    filename VARCHAR(255) NOT NULL,
    original_name VARCHAR(255) NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    file_size BIGINT NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    uploaded_by BIGINT NOT NULL REFERENCES users(id),
    uploaded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_file_attachments_idea ON file_attachments(idea_id);

-- =====================================================
-- LIKES TABLE
-- =====================================================
CREATE TABLE likes (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    idea_id BIGINT NOT NULL REFERENCES ideas(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, idea_id)
);

CREATE INDEX idx_likes_user ON likes(user_id);
CREATE INDEX idx_likes_idea ON likes(idea_id);
CREATE INDEX idx_likes_created_at ON likes(created_at);

-- =====================================================
-- COMMENTS TABLE
-- =====================================================
CREATE TABLE comments (
    id BIGSERIAL PRIMARY KEY,
    idea_id BIGINT NOT NULL REFERENCES ideas(id) ON DELETE CASCADE,
    author_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content VARCHAR(200) NOT NULL,
    reaction_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_comments_idea ON comments(idea_id);
CREATE INDEX idx_comments_author ON comments(author_id);
CREATE INDEX idx_comments_created_at ON comments(created_at DESC);

-- =====================================================
-- COMMENT REACTIONS TABLE
-- =====================================================
CREATE TABLE comment_reactions (
    id BIGSERIAL PRIMARY KEY,
    comment_id BIGINT NOT NULL REFERENCES comments(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    emoji VARCHAR(20) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(comment_id, user_id, emoji)
);

CREATE INDEX idx_comment_reactions_comment ON comment_reactions(comment_id);
CREATE INDEX idx_comment_reactions_user ON comment_reactions(user_id);

-- =====================================================
-- SURVEYS TABLE
-- =====================================================
CREATE TABLE surveys (
    id BIGSERIAL PRIMARY KEY,
    creator_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    question VARCHAR(500) NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_anonymous BOOLEAN NOT NULL DEFAULT FALSE,
    allow_multiple_votes BOOLEAN NOT NULL DEFAULT FALSE,
    total_votes INTEGER NOT NULL DEFAULT 0,
    expires_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_surveys_creator ON surveys(creator_id);
CREATE INDEX idx_surveys_active ON surveys(is_active);
CREATE INDEX idx_surveys_created_at ON surveys(created_at DESC);

-- =====================================================
-- SURVEY OPTIONS TABLE
-- =====================================================
CREATE TABLE survey_options (
    id BIGSERIAL PRIMARY KEY,
    survey_id BIGINT NOT NULL REFERENCES surveys(id) ON DELETE CASCADE,
    option_text VARCHAR(200) NOT NULL,
    vote_count INTEGER NOT NULL DEFAULT 0,
    display_order INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX idx_survey_options_survey ON survey_options(survey_id);

-- =====================================================
-- SURVEY VOTES TABLE
-- =====================================================
CREATE TABLE survey_votes (
    id BIGSERIAL PRIMARY KEY,
    survey_id BIGINT NOT NULL REFERENCES surveys(id) ON DELETE CASCADE,
    option_id BIGINT NOT NULL REFERENCES survey_options(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(survey_id, user_id, option_id)
);

CREATE INDEX idx_survey_votes_survey ON survey_votes(survey_id);
CREATE INDEX idx_survey_votes_user ON survey_votes(user_id);

-- =====================================================
-- BADGES TABLE
-- =====================================================
CREATE TABLE badges (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    display_name VARCHAR(100),
    description VARCHAR(500) NOT NULL,
    icon VARCHAR(100) NOT NULL,
    criteria VARCHAR(500),
    xp_reward INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- USER BADGES TABLE
-- =====================================================
CREATE TABLE user_badges (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    badge_id BIGINT NOT NULL REFERENCES badges(id) ON DELETE CASCADE,
    earned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, badge_id)
);

CREATE INDEX idx_user_badges_user ON user_badges(user_id);
CREATE INDEX idx_user_badges_badge ON user_badges(badge_id);

-- =====================================================
-- AUDIT LOGS TABLE
-- =====================================================
CREATE TABLE audit_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    action audit_action NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id BIGINT,
    old_value JSONB,
    new_value JSONB,
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);

-- =====================================================
-- NOTIFICATIONS TABLE
-- =====================================================
CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type notification_type NOT NULL,
    title VARCHAR(200) NOT NULL,
    message VARCHAR(500) NOT NULL,
    link VARCHAR(500),
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    sender_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    related_entity_type VARCHAR(50),
    related_entity_id BIGINT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);

-- =====================================================
-- FUNCTIONS AND TRIGGERS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ideas_updated_at
    BEFORE UPDATE ON ideas
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_comments_updated_at
    BEFORE UPDATE ON comments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to update idea like count
CREATE OR REPLACE FUNCTION update_idea_like_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE ideas SET like_count = like_count + 1 WHERE id = NEW.idea_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE ideas SET like_count = like_count - 1 WHERE id = OLD.idea_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_update_like_count
    AFTER INSERT OR DELETE ON likes
    FOR EACH ROW EXECUTE FUNCTION update_idea_like_count();

-- Function to update idea comment count
CREATE OR REPLACE FUNCTION update_idea_comment_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE ideas SET comment_count = comment_count + 1 WHERE id = NEW.idea_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE ideas SET comment_count = comment_count - 1 WHERE id = OLD.idea_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_update_comment_count
    AFTER INSERT OR DELETE ON comments
    FOR EACH ROW EXECUTE FUNCTION update_idea_comment_count();

-- Function to update comment reaction count
CREATE OR REPLACE FUNCTION update_comment_reaction_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE comments SET reaction_count = reaction_count + 1 WHERE id = NEW.comment_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE comments SET reaction_count = reaction_count - 1 WHERE id = OLD.comment_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_update_reaction_count
    AFTER INSERT OR DELETE ON comment_reactions
    FOR EACH ROW EXECUTE FUNCTION update_comment_reaction_count();

-- Function to update survey vote count
CREATE OR REPLACE FUNCTION update_survey_vote_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE survey_options SET vote_count = vote_count + 1 WHERE id = NEW.option_id;
        UPDATE surveys SET total_votes = total_votes + 1 WHERE id = NEW.survey_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE survey_options SET vote_count = vote_count - 1 WHERE id = OLD.option_id;
        UPDATE surveys SET total_votes = total_votes - 1 WHERE id = OLD.survey_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_update_vote_count
    AFTER INSERT OR DELETE ON survey_votes
    FOR EACH ROW EXECUTE FUNCTION update_survey_vote_count();

-- =====================================================
-- SEED DATA
-- =====================================================

-- Insert default badges (name matches GamificationService badge criteria)
INSERT INTO badges (name, display_name, description, icon, criteria, xp_reward) VALUES
    ('first_idea', 'First Idea', 'Submitted your first innovation idea', 'lightbulb', 'Submit first idea', 25),
    ('idea_machine', 'Idea Machine', 'Submitted 10 innovation ideas', 'rocket', 'Submit 10 ideas', 100),
    ('popular', 'Popular', 'Received 10 likes on a single idea', 'star', 'Get 10 likes on one idea', 50),
    ('trendsetter', 'Trendsetter', 'Received 50 likes total', 'trending_up', 'Get 50 total likes', 150),
    ('commentator', 'Commentator', 'Left 50 comments on ideas', 'chat', 'Post 50 comments', 75),
    ('supporter', 'Supporter', 'Used all likes 4 weeks in a row', 'favorite', 'Use all likes 4 consecutive weeks', 100),
    ('contributor_month', 'Contributor of the Month', 'Most ideas submitted in a month', 'emoji_events', 'Top contributor monthly', 200),
    ('team_player', 'Team Player', 'Commented on 20 different ideas', 'groups', 'Comment on 20 unique ideas', 50),
    ('innovator', 'Innovator', 'Had an idea reach Completed status', 'check_circle', 'Idea reaches Completed', 150),
    ('early_bird', 'Early Bird', 'One of the first 100 users', 'schedule', 'Register in first 100 users', 50);

-- Insert admin user (password: admin123)
INSERT INTO users (username, email, password_hash, first_name, last_name, role, xp_points, level) VALUES
    ('admin', 'admin@gfos.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4.G.xZ7VQq0CkX8G', 'System', 'Administrator', 'ADMIN', 0, 1);

-- Insert test users (password: password123)
INSERT INTO users (username, email, password_hash, first_name, last_name, role, xp_points, level) VALUES
    ('jsmith', 'john.smith@gfos.com', '$2a$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'John', 'Smith', 'EMPLOYEE', 150, 2),
    ('mwilson', 'mary.wilson@gfos.com', '$2a$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Mary', 'Wilson', 'PROJECT_MANAGER', 350, 3),
    ('tjohnson', 'tom.johnson@gfos.com', '$2a$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Tom', 'Johnson', 'EMPLOYEE', 75, 1);

-- Insert sample ideas
INSERT INTO ideas (title, description, category, status, progress_percentage, author_id) VALUES
    ('AI-Powered Customer Support', 'Implement an AI chatbot for 24/7 customer support to reduce response times and improve customer satisfaction. The bot would handle common queries and escalate complex issues to human agents.', 'Technology', 'IN_PROGRESS', 45, 2),
    ('Green Office Initiative', 'Reduce paper usage by 80% through digital transformation. Implement digital signatures, cloud storage, and paperless meeting rooms.', 'Sustainability', 'CONCEPT', 0, 3),
    ('Employee Wellness Program', 'Launch a comprehensive wellness program including gym memberships, mental health resources, and flexible working hours.', 'HR', 'COMPLETED', 100, 4),
    ('Mobile App for Field Workers', 'Develop a mobile application for field workers to submit reports, track time, and communicate with the office in real-time.', 'Technology', 'CONCEPT', 0, 2),
    ('Customer Feedback Loop', 'Create an automated system to collect, analyze, and act on customer feedback across all touchpoints.', 'Customer Experience', 'IN_PROGRESS', 30, 3);

-- Insert sample tags
INSERT INTO idea_tags (idea_id, tag_name) VALUES
    (1, 'AI'), (1, 'automation'), (1, 'customer-service'),
    (2, 'sustainability'), (2, 'digital'), (2, 'cost-saving'),
    (3, 'wellness'), (3, 'employee-benefit'), (3, 'culture'),
    (4, 'mobile'), (4, 'field-service'), (4, 'productivity'),
    (5, 'feedback'), (5, 'analytics'), (5, 'customer-experience');

-- Insert sample likes
INSERT INTO likes (user_id, idea_id) VALUES
    (2, 3), (3, 1), (4, 1), (4, 2), (2, 5);

-- Insert sample comments
INSERT INTO comments (idea_id, author_id, content) VALUES
    (1, 3, 'Great idea! This could significantly reduce our support costs.'),
    (1, 4, 'I have experience with chatbot implementation. Happy to help!'),
    (2, 2, 'We should start with the most paper-intensive departments.'),
    (3, 2, 'The gym membership perk is fantastic!'),
    (5, 4, 'Can we integrate this with our existing CRM?');

-- Insert sample reactions
INSERT INTO comment_reactions (comment_id, user_id, emoji) VALUES
    (1, 2, 'thumbs_up'), (1, 4, 'heart'),
    (2, 3, 'thumbs_up'),
    (4, 3, 'heart'), (4, 4, 'celebrate');

-- Insert sample survey
INSERT INTO surveys (creator_id, question, description, is_active) VALUES
    (2, 'Which new feature should we prioritize?', 'Help us decide the next big feature for our platform.', true);

INSERT INTO survey_options (survey_id, option_text, display_order) VALUES
    (1, 'Dark Mode', 1),
    (1, 'Mobile App', 2),
    (1, 'API Integrations', 3),
    (1, 'Advanced Analytics', 4);

INSERT INTO survey_votes (survey_id, option_id, user_id) VALUES
    (1, 1, 3), (1, 2, 4);

-- Grant first badges
INSERT INTO user_badges (user_id, badge_id) VALUES
    (2, 1), -- John: First Idea
    (3, 1), -- Mary: First Idea
    (4, 1); -- Tom: First Idea
