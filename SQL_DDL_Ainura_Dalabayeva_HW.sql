-- ================================================================
-- Social Media DB creation
-- Database: social_media
-- Schema: sm
-- ================================================================

-- ===============================================================
-- STEP 1. Created database manually
-- ===============================================================
-- PostgreSQL does not allow CREATE DATABASE inside a transaction,
-- and pgAdmin wraps each query in an implicit transaction block.
-- Because of this, CREATE DATABASE executed through the pgAdmin UI:
--
--    1. Right-click "Databases"
--    2. Choose: Create → Database
--    3. Enter name: social_media_db
--    4. Save
-- In other DBMS DB could also be created using the script:
DROP DATABASE IF EXISTS social_media;
CREATE DATABASE social_media
  WITH OWNER = postgres
       ENCODING = 'UTF8'
       CONNECTION LIMIT = -1;

-- ===============================================================
-- STEP 2. Created schema
-- ===============================================================
CREATE SCHEMA IF NOT EXISTS sm;
COMMENT ON SCHEMA sm IS 'Schema for Social Media model';

-- ============ 3) Created Parent tables ============

-- Friendship status (parent for friendship)
CREATE TABLE IF NOT EXISTS sm.friendship_status (
  friendship_status_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  status_name VARCHAR(50) NOT NULL,
  CONSTRAINT uq_friendship_status_name UNIQUE (status_name)
);
COMMENT ON TABLE sm.friendship_status IS 'Status types for friendship (pending, accepted, blocked).';

-- Users
CREATE TABLE IF NOT EXISTS sm.users (
  user_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  username VARCHAR(50) NOT NULL,
  first_name VARCHAR(50),
  last_name VARCHAR(50),
  email VARCHAR(100) NOT NULL,
  date_of_birth DATE NOT NULL,
  gender VARCHAR(10) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),

  CONSTRAINT uq_users_email UNIQUE (email),
  CONSTRAINT uq_users_username UNIQUE (username),
  CONSTRAINT chk_users_gender CHECK (gender IN ('Male','Female','Other')),
  CONSTRAINT chk_users_created_date CHECK (created_at > TIMESTAMP '2000-01-01 00:00:00'),

  -- ensure positive ids
  CONSTRAINT chk_users_id_positive CHECK (user_id > 0)
);
COMMENT ON TABLE sm.users IS 'Base user table.';

-- Location (Catalog of standardized geographical locations)
CREATE TABLE IF NOT EXISTS sm.location (
  location_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  country VARCHAR(100) NOT NULL,
  city VARCHAR(100) NOT NULL,
  latitude DECIMAL(9,6),
  longitude DECIMAL(9,6),
  CONSTRAINT uq_location_coords UNIQUE (country, city, latitude, longitude),
  -- coordinate validity checks
  CONSTRAINT chk_location_latitude CHECK (latitude IS NULL OR (latitude BETWEEN -90 AND 90)),
  CONSTRAINT chk_location_longitude CHECK (longitude IS NULL OR (longitude BETWEEN -180 AND 180)),
  CONSTRAINT chk_location_id_positive CHECK (location_id > 0)
);
COMMENT ON TABLE sm.location IS 'Catalog of standardized geographical locations.';


-- Interest
CREATE TABLE IF NOT EXISTS sm.interest (
  interest_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  interest_name VARCHAR(255) NOT NULL,
  CONSTRAINT uq_interest_name UNIQUE (interest_name),
  CONSTRAINT chk_interest_id_positive CHECK (interest_id > 0)
);
COMMENT ON TABLE sm.interest IS 'Catalog of interest types.';

-- Hashtag
CREATE TABLE IF NOT EXISTS sm.hashtag (
  hashtag_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  hashtag_text VARCHAR(50) NOT NULL,
  CONSTRAINT uq_hashtag_text UNIQUE (hashtag_text),
  CONSTRAINT chk_hashtag_id_positive CHECK (hashtag_id > 0)
);
COMMENT ON TABLE sm.hashtag IS 'Hashtag catalog.';

-- ============ 4) Created Child and associative tables ============

-- User_Profile (Extended user profile attributes, 1:1 with users)
CREATE TABLE IF NOT EXISTS sm.user_profile (
  profile_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id INTEGER NOT NULL,
  bio VARCHAR(255),
  profile_picture_url VARCHAR(255),
  location_id INTEGER,
  CONSTRAINT uq_user_id_profile UNIQUE (user_id),
  CONSTRAINT fk_userprofile_user FOREIGN KEY (user_id) REFERENCES sm.users (user_id) ON DELETE CASCADE,
  CONSTRAINT fk_userprofile_location FOREIGN KEY (location_id) REFERENCES sm.location (location_id) ON DELETE SET NULL,
  CONSTRAINT chk_user_profile_id_positive CHECK (profile_id > 0)
);
COMMENT ON TABLE sm.user_profile IS 'Extended user profile attributes (1:1 with users).';

-- Posts
CREATE TABLE IF NOT EXISTS sm.posts (
  post_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id INTEGER NOT NULL,
  content TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  location_id INTEGER,
  CONSTRAINT fk_posts_user FOREIGN KEY (user_id) REFERENCES sm.users (user_id) ON DELETE CASCADE,
  CONSTRAINT fk_posts_location FOREIGN KEY (location_id) REFERENCES sm.location (location_id) ON DELETE SET NULL,
  CONSTRAINT chk_posts_created_date CHECK (created_at > TIMESTAMP '2000-01-01 00:00:00'),
  CONSTRAINT chk_posts_id_positive CHECK (post_id > 0)
);
COMMENT ON TABLE sm.posts IS 'User-generated posts.';

-- Media
CREATE TABLE IF NOT EXISTS sm.media (
  media_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  post_id INTEGER NOT NULL,
  file_url VARCHAR(255) NOT NULL,
  media_type VARCHAR(50) NOT NULL,
  CONSTRAINT fk_media_post FOREIGN KEY (post_id) REFERENCES sm.posts (post_id) ON DELETE CASCADE,
  CONSTRAINT chk_media_id_positive CHECK (media_id > 0)
);
COMMENT ON TABLE sm.media IS 'Media attachments for posts (images, video).';

-- Post_Hashtag
CREATE TABLE IF NOT EXISTS sm.post_hashtag (
  post_id INTEGER NOT NULL,
  hashtag_id INTEGER NOT NULL,
  CONSTRAINT pk_post_hashtag PRIMARY KEY (post_id, hashtag_id),
  CONSTRAINT fk_ph_post FOREIGN KEY (post_id) REFERENCES sm.posts (post_id) ON DELETE CASCADE,
  CONSTRAINT fk_ph_hashtag FOREIGN KEY (hashtag_id) REFERENCES sm.hashtag (hashtag_id) ON DELETE CASCADE
);
COMMENT ON TABLE sm.post_hashtag IS 'Linking table between posts and hashtags (M:N).';

-- Likes
CREATE TABLE IF NOT EXISTS sm.likes (
  like_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  post_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  liked_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  CONSTRAINT fk_likes_post FOREIGN KEY (post_id) REFERENCES sm.posts (post_id) ON DELETE CASCADE,
  CONSTRAINT fk_likes_user FOREIGN KEY (user_id) REFERENCES sm.users (user_id) ON DELETE CASCADE,
  CONSTRAINT uq_likes_unique UNIQUE (post_id, user_id),
  CONSTRAINT chk_likes_liked_date CHECK (liked_at > TIMESTAMP '2000-01-01 00:00:00'),
  CONSTRAINT chk_likes_id_positive CHECK (like_id > 0)
);
COMMENT ON TABLE sm.likes IS 'User likes for posts.';

-- Comments
CREATE TABLE IF NOT EXISTS sm.comments (
  comment_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  post_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  content VARCHAR(255) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  CONSTRAINT fk_comments_post FOREIGN KEY (post_id) REFERENCES sm.posts (post_id) ON DELETE CASCADE,
  CONSTRAINT fk_comments_user FOREIGN KEY (user_id) REFERENCES sm.users (user_id) ON DELETE CASCADE,
  CONSTRAINT chk_comments_created_date CHECK (created_at > TIMESTAMP '2000-01-01 00:00:00'),
  CONSTRAINT chk_comments_id_positive CHECK (comment_id > 0)
);
COMMENT ON TABLE sm.comments IS 'Comments made by users on posts.';

-- Shares
CREATE TABLE IF NOT EXISTS sm.shares (
  share_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  post_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  share_message TEXT,
  shared_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  CONSTRAINT fk_shares_post FOREIGN KEY (post_id) REFERENCES sm.posts (post_id) ON DELETE CASCADE,
  CONSTRAINT fk_shares_user FOREIGN KEY (user_id) REFERENCES sm.users (user_id) ON DELETE CASCADE,
  CONSTRAINT chk_shares_shared_date CHECK (shared_at > TIMESTAMP '2000-01-01 00:00:00'),
  CONSTRAINT chk_shares_id_positive CHECK (share_id > 0)
);
COMMENT ON TABLE sm.shares IS 'Post shares by users.';

-- Followers
CREATE TABLE IF NOT EXISTS sm.followers (
  follower_id INTEGER NOT NULL,
  following_id INTEGER NOT NULL,
  followed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  CONSTRAINT pk_followers PRIMARY KEY (follower_id, following_id),
  CONSTRAINT fk_followers_follower FOREIGN KEY (follower_id) REFERENCES sm.users (user_id) ON DELETE CASCADE,
  CONSTRAINT fk_followers_following FOREIGN KEY (following_id) REFERENCES sm.users (user_id) ON DELETE CASCADE,
  CONSTRAINT chk_followers_date CHECK (followed_at > TIMESTAMP '2000-01-01 00:00:00')
);
COMMENT ON TABLE sm.followers IS 'Self-referential follows relationship between users (M:N).';

-- Friendship
CREATE TABLE IF NOT EXISTS sm.friendship (
  user_id INTEGER NOT NULL,
  friend_id INTEGER NOT NULL,
  friendship_status_id INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  CONSTRAINT pk_friendship PRIMARY KEY (user_id, friend_id),
  CONSTRAINT fk_friendship_user FOREIGN KEY (user_id) REFERENCES sm.users (user_id) ON DELETE CASCADE,
  CONSTRAINT fk_friendship_friend FOREIGN KEY (friend_id) REFERENCES sm.users (user_id) ON DELETE CASCADE,
  CONSTRAINT fk_friendship_status FOREIGN KEY (friendship_status_id) REFERENCES sm.friendship_status (friendship_status_id) ON DELETE RESTRICT,
  CONSTRAINT chk_friendship_created_date CHECK (created_at > TIMESTAMP '2000-01-01 00:00:00')
);
COMMENT ON TABLE sm.friendship IS 'Friendship links between users with a status.';

-- User_interest
CREATE TABLE IF NOT EXISTS sm.user_interest (
  user_id INTEGER NOT NULL,
  interest_id INTEGER NOT NULL,
  CONSTRAINT pk_user_interest PRIMARY KEY (user_id, interest_id),
  CONSTRAINT fk_ui_user FOREIGN KEY (user_id) REFERENCES sm.users (user_id) ON DELETE CASCADE,
  CONSTRAINT fk_ui_interest FOREIGN KEY (interest_id) REFERENCES sm.interest (interest_id) ON DELETE CASCADE
);
COMMENT ON TABLE sm.user_interest IS 'User to interest mapping (M:N).';

-- ============ 5) Inserted sample data ============

-- Users
INSERT INTO sm.users (username, first_name, last_name, email, date_of_birth, gender, password_hash, created_at)
VALUES
  ('anna_k', 'Anna', 'Kim', 'anna.kim@example.com', DATE '1996-04-12', 'Female', 'h$92jd91msk2', TIMESTAMP '2024-01-14 09:23:11'),
  ('max_travel', 'Max', 'Turner', 'max.turner@example.com', DATE '1993-11-02', 'Male', '7dhA82mslQW', TIMESTAMP '2024-02-03 13:47:55'),
  ('sofia.creative', 'Sofia', 'Mendes', 'sofia.mendes@example.com', DATE '1999-07-25', 'Female', 'k2L9dk20As8', TIMESTAMP '2024-02-19 16:10:05'),
  ('oleg_writer', 'Oleg', 'Ivanov', 'oleg.ivanov@example.com', DATE '1990-05-05', 'Male', 'pw1', TIMESTAMP '2023-12-01 10:00:00'),
  ('lara_art', 'Lara', 'Gomez', 'lara.gomez@example.com', DATE '1995-08-20', 'Female', 'pw2', TIMESTAMP '2024-03-10 11:11:11'),
  ('mina_music', 'Mina', 'Park', 'mina.park@example.com', DATE '1998-02-14', 'Female', 'pw3', TIMESTAMP '2024-04-01 09:09:09')
ON CONFLICT (email) DO NOTHING;

-- Locations
INSERT INTO sm.location (country, city, latitude, longitude)
VALUES
  ('USA', 'New York', 40.7128, -74.0060),
  ('Spain', 'Madrid', 40.4168, -3.7038),
  ('Japan', 'Tokyo', 35.6895, 139.6917),
  ('Kazakhstan', 'Astana', 51.1657, 71.4510),
  ('France', 'Paris', 48.8566, 2.3522),
  ('Germany', 'Berlin', 52.5200, 13.4050)
ON CONFLICT (country, city, latitude, longitude) DO NOTHING;

-- User_Profile
INSERT INTO sm.user_profile (user_id, bio, profile_picture_url, location_id)
VALUES
  ((SELECT user_id FROM sm.users WHERE username='anna_k'), 'Coffee enthusiast', '/img/user1.jpg', (SELECT location_id FROM sm.location WHERE country='USA' AND city='New York' LIMIT 1)),
  ((SELECT user_id FROM sm.users WHERE username='max_travel'), 'Traveler and foodie 🌍', '/img/user2.jpg', (SELECT location_id FROM sm.location WHERE country='Spain' AND city='Madrid' LIMIT 1)),
  ((SELECT user_id FROM sm.users WHERE username='sofia.creative'), 'Tech lover 💻', '/img/user3.jpg', (SELECT location_id FROM sm.location WHERE country='Japan' AND city='Tokyo' LIMIT 1))
ON CONFLICT DO NOTHING;

-- Friendship_status
INSERT INTO sm.friendship_status (status_name)
VALUES
  ('pending'),
  ('accepted'),
  ('blocked')
ON CONFLICT (status_name) DO NOTHING;

-- Interest
INSERT INTO sm.interest (interest_name)
VALUES
  ('Sports'),
  ('Music'),
  ('Technology')
ON CONFLICT (interest_name) DO NOTHING;

-- Hashtags
INSERT INTO sm.hashtag (hashtag_text)
VALUES
  ('project'),
  ('travel'),
  ('photography'),
  ('tech'),
  ('art')
ON CONFLICT (hashtag_text) DO NOTHING;

-- Posts
INSERT INTO sm.posts (user_id, content, created_at, updated_at, location_id)
VALUES
  ((SELECT user_id FROM sm.users WHERE username='anna_k'), 'Just finished a new project!', TIMESTAMP '2024-05-03 12:00:00', TIMESTAMP '2024-05-03 12:30:00', (SELECT location_id FROM sm.location WHERE country='USA' AND city='New York' LIMIT 1)),
  ((SELECT user_id FROM sm.users WHERE username='max_travel'), 'Exploring the old streets today!', TIMESTAMP '2024-06-10 09:45:00', TIMESTAMP '2024-06-10 09:45:00', (SELECT location_id FROM sm.location WHERE country='Spain' AND city='Madrid' LIMIT 1)),
  ((SELECT user_id FROM sm.users WHERE username='sofia.creative'), 'Testing a new camera lens.', TIMESTAMP '2024-04-20 08:30:00', TIMESTAMP '2024-04-20 08:35:00', (SELECT location_id FROM sm.location WHERE country='Japan' AND city='Tokyo' LIMIT 1)),
  ((SELECT user_id FROM sm.users WHERE username='oleg_writer'), 'Writing about tech and travel', TIMESTAMP '2024-02-14 10:10:00', TIMESTAMP '2024-02-14 10:11:00', (SELECT location_id FROM sm.location WHERE country='Kazakhstan' AND city='Astana' LIMIT 1)),
  ((SELECT user_id FROM sm.users WHERE username='lara_art'), 'New painting completed!', TIMESTAMP '2024-03-20 14:00:00', NULL, (SELECT location_id FROM sm.location WHERE country='France' AND city='Paris' LIMIT 1))
ON CONFLICT DO NOTHING;

-- Post_Hashtag
INSERT INTO sm.post_hashtag (post_id, hashtag_id)
VALUES
  ((SELECT post_id FROM sm.posts WHERE content ILIKE 'Just finished a new project!' LIMIT 1), (SELECT hashtag_id FROM sm.hashtag WHERE hashtag_text='project' LIMIT 1)),
  ((SELECT post_id FROM sm.posts WHERE content ILIKE 'Exploring the old streets today!' LIMIT 1), (SELECT hashtag_id FROM sm.hashtag WHERE hashtag_text='travel' LIMIT 1)),
  ((SELECT post_id FROM sm.posts WHERE content ILIKE 'Testing a new camera lens.' LIMIT 1), (SELECT hashtag_id FROM sm.hashtag WHERE hashtag_text='photography' LIMIT 1)),
  ((SELECT post_id FROM sm.posts WHERE content ILIKE 'Writing about tech and travel' LIMIT 1), (SELECT hashtag_id FROM sm.hashtag WHERE hashtag_text='tech' LIMIT 1)),
  ((SELECT post_id FROM sm.posts WHERE content ILIKE 'New painting completed!' LIMIT 1), (SELECT hashtag_id FROM sm.hashtag WHERE hashtag_text='art' LIMIT 1))
ON CONFLICT DO NOTHING;

-- Media
INSERT INTO sm.media (post_id, file_url, media_type)
VALUES
  ((SELECT post_id FROM sm.posts WHERE content ILIKE 'Just finished a new project!' LIMIT 1), '/media/project.png', 'image'),
  ((SELECT post_id FROM sm.posts WHERE content ILIKE 'Exploring the old streets today!' LIMIT 1), '/media/madrid.jpg', 'image'),
  ((SELECT post_id FROM sm.posts WHERE content ILIKE 'Testing a new camera lens.' LIMIT 1), '/media/lens.mp4', 'video')
ON CONFLICT DO NOTHING;

-- Likes
INSERT INTO sm.likes (post_id, user_id, liked_at)
VALUES
  ((SELECT post_id FROM sm.posts WHERE content ILIKE 'Just finished a new project!' LIMIT 1), (SELECT user_id FROM sm.users WHERE username='max_travel' LIMIT 1), TIMESTAMP '2024-05-03 12:10:00'),
  ((SELECT post_id FROM sm.posts WHERE content ILIKE 'Exploring the old streets today!' LIMIT 1), (SELECT user_id FROM sm.users WHERE username='sofia.creative' LIMIT 1), TIMESTAMP '2024-06-10 10:00:00'),
  ((SELECT post_id FROM sm.posts WHERE content ILIKE 'Testing a new camera lens.' LIMIT 1), (SELECT user_id FROM sm.users WHERE username='anna_k' LIMIT 1), TIMESTAMP '2024-04-20 09:00:00')
ON CONFLICT (post_id, user_id) DO NOTHING;

-- Comments
INSERT INTO sm.comments (post_id, user_id, content, created_at)
VALUES
  ((SELECT post_id FROM sm.posts WHERE content ILIKE 'Just finished a new project!' LIMIT 1), (SELECT user_id FROM sm.users WHERE username='sofia.creative' LIMIT 1), 'Great job!', TIMESTAMP '2024-05-03 12:15:00'),
  ((SELECT post_id FROM sm.posts WHERE content ILIKE 'Exploring the old streets today!' LIMIT 1), (SELECT user_id FROM sm.users WHERE username='anna_k' LIMIT 1), 'Amazing view!', TIMESTAMP '2024-06-10 10:20:00'),
  ((SELECT post_id FROM sm.posts WHERE content ILIKE 'Testing a new camera lens.' LIMIT 1), (SELECT user_id FROM sm.users WHERE username='max_travel' LIMIT 1), 'Love this photo!', TIMESTAMP '2024-04-20 09:30:00')
ON CONFLICT DO NOTHING;

-- Shares
INSERT INTO sm.shares (post_id, user_id, share_message, shared_at)
VALUES
  ((SELECT post_id FROM sm.posts WHERE content ILIKE 'Just finished a new project!' LIMIT 1), (SELECT user_id FROM sm.users WHERE username='max_travel' LIMIT 1), 'Inspiring post!', TIMESTAMP '2024-05-03 13:00:00'),
  ((SELECT post_id FROM sm.posts WHERE content ILIKE 'Exploring the old streets today!' LIMIT 1), (SELECT user_id FROM sm.users WHERE username='sofia.creative' LIMIT 1), 'Beautiful city!', TIMESTAMP '2024-06-10 11:00:00')
ON CONFLICT DO NOTHING;

-- Followers
INSERT INTO sm.followers (follower_id, following_id, followed_at)
VALUES
  ((SELECT user_id FROM sm.users WHERE username='max_travel' LIMIT 1), (SELECT user_id FROM sm.users WHERE username='anna_k' LIMIT 1), TIMESTAMP '2024-05-01 10:20:00'),
  ((SELECT user_id FROM sm.users WHERE username='sofia.creative' LIMIT 1), (SELECT user_id FROM sm.users WHERE username='max_travel' LIMIT 1), TIMESTAMP '2024-06-15 15:45:00'),
  ((SELECT user_id FROM sm.users WHERE username='anna_k' LIMIT 1), (SELECT user_id FROM sm.users WHERE username='sofia.creative' LIMIT 1), TIMESTAMP '2024-07-05 09:00:00')
ON CONFLICT DO NOTHING;

-- Friendship
INSERT INTO sm.friendship (user_id, friend_id, friendship_status_id, created_at)
VALUES
  ((SELECT user_id FROM sm.users WHERE username='anna_k' LIMIT 1), (SELECT user_id FROM sm.users WHERE username='max_travel' LIMIT 1), (SELECT friendship_status_id FROM sm.friendship_status WHERE status_name='accepted' LIMIT 1), TIMESTAMP '2024-03-01 09:00:00'),
  ((SELECT user_id FROM sm.users WHERE username='max_travel' LIMIT 1), (SELECT user_id FROM sm.users WHERE username='sofia.creative' LIMIT 1), (SELECT friendship_status_id FROM sm.friendship_status WHERE status_name='pending' LIMIT 1), TIMESTAMP '2024-03-02 10:15:00')
ON CONFLICT DO NOTHING;

-- User_interest
INSERT INTO sm.user_interest (user_id, interest_id)
VALUES
  ((SELECT user_id FROM sm.users WHERE username='sofia.creative' LIMIT 1), (SELECT interest_id FROM sm.interest WHERE interest_name='Technology' LIMIT 1)),
  ((SELECT user_id FROM sm.users WHERE username='max_travel' LIMIT 1), (SELECT interest_id FROM sm.interest WHERE interest_name='Music' LIMIT 1)),
  ((SELECT user_id FROM sm.users WHERE username='anna_k' LIMIT 1), (SELECT interest_id FROM sm.interest WHERE interest_name='Sports' LIMIT 1))
ON CONFLICT DO NOTHING;

-- ================================================================
-- 6) Added record_ts column to each table using ALTER TABLE, filled nulls and set NOT NULL
-- ================================================================

-- USERS
ALTER TABLE sm.users ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT current_date;
UPDATE sm.users SET record_ts = current_date WHERE record_ts IS NULL;
ALTER TABLE sm.users ALTER COLUMN record_ts SET NOT NULL;

-- LOCATION
ALTER TABLE sm.location ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT current_date;
UPDATE sm.location SET record_ts = current_date WHERE record_ts IS NULL;
ALTER TABLE sm.location ALTER COLUMN record_ts SET NOT NULL;

-- USER PROFILE
ALTER TABLE sm.user_profile ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT current_date;
UPDATE sm.user_profile SET record_ts = current_date WHERE record_ts IS NULL;
ALTER TABLE sm.user_profile ALTER COLUMN record_ts SET NOT NULL;

-- POSTS
ALTER TABLE sm.posts ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT current_date;
UPDATE sm.posts SET record_ts = current_date WHERE record_ts IS NULL;
ALTER TABLE sm.posts ALTER COLUMN record_ts SET NOT NULL;

-- MEDIA
ALTER TABLE sm.media ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT current_date;
UPDATE sm.media SET record_ts = current_date WHERE record_ts IS NULL;
ALTER TABLE sm.media ALTER COLUMN record_ts SET NOT NULL;

-- POST_HASHTAGS
ALTER TABLE sm.post_hashtag ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT current_date;
UPDATE sm.post_hashtag SET record_ts = current_date WHERE record_ts IS NULL;
ALTER TABLE sm.post_hashtag ALTER COLUMN record_ts SET NOT NULL;

-- LIKES
ALTER TABLE sm.likes ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT current_date;
UPDATE sm.likes SET record_ts = current_date WHERE record_ts IS NULL;
ALTER TABLE sm.likes ALTER COLUMN record_ts SET NOT NULL;

-- COMMENTS
ALTER TABLE sm.comments ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT current_date;
UPDATE sm.comments SET record_ts = current_date WHERE record_ts IS NULL;
ALTER TABLE sm.comments ALTER COLUMN record_ts SET NOT NULL;

-- SHARES
ALTER TABLE sm.shares ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT current_date;
UPDATE sm.shares SET record_ts = current_date WHERE record_ts IS NULL;
ALTER TABLE sm.shares ALTER COLUMN record_ts SET NOT NULL;

-- FOLLOWERS
ALTER TABLE sm.followers ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT current_date;
UPDATE sm.followers SET record_ts = current_date WHERE record_ts IS NULL;
ALTER TABLE sm.followers ALTER COLUMN record_ts SET NOT NULL;

-- FRIENDSHIP
ALTER TABLE sm.friendship ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT current_date;
UPDATE sm.friendship SET record_ts = current_date WHERE record_ts IS NULL;
ALTER TABLE sm.friendship ALTER COLUMN record_ts SET NOT NULL;

-- FRIENDSHIP STATUS
ALTER TABLE sm.friendship_status ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT current_date;
UPDATE sm.friendship_status SET record_ts = current_date WHERE record_ts IS NULL;
ALTER TABLE sm.friendship_status ALTER COLUMN record_ts SET NOT NULL;

-- INTERESTS
ALTER TABLE sm.interest ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT current_date;
UPDATE sm.interest SET record_ts = current_date WHERE record_ts IS NULL;
ALTER TABLE sm.interest ALTER COLUMN record_ts SET NOT NULL;

-- HASHTAG
ALTER TABLE sm.hashtag ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT current_date;
UPDATE sm.hashtag SET record_ts = current_date WHERE record_ts IS NULL;
ALTER TABLE sm.hashtag ALTER COLUMN record_ts SET NOT NULL;

-- ================================================================

-- End of script
-- ================================================================
```