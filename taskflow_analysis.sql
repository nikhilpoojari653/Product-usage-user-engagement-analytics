DROP TABLE events;

CREATE TABLE events(
	user_id INT ,
	event_date DATE,
	event_type VARCHAR,
	feature_name VARCHAR);

COPY events
FROM 'C:\Users\Nikhil Poojari\OneDrive\Desktop\Portfolio projects\Product Usage Analysis\events.csv'
DELIMITER ','
CSV HEADER;

SELECT * FROM events
ORDER BY user_id;

CREATE TABLE sessions(
	user_id	INT,
	session_id	INT,
	session_start TIMESTAMP,
	session_end TIMESTAMP);

COPY sessions
FROM 'C:\Users\Nikhil Poojari\OneDrive\Desktop\Portfolio projects\Product Usage Analysis\sessions.csv'
DELIMITER ','
CSV HEADER;

SELECT * FROM sessions
ORDER BY user_id;

CREATE TABLE users(
	user_id	INT,
	signup_date	TIMESTAMP ,
	plan_type TEXT,
	team_size INT,
	country TEXT);

COPY users
FROM 'C:\Users\Nikhil Poojari\OneDrive\Desktop\Portfolio projects\Product Usage Analysis\users.csv'
DELIMITER ','
CSV HEADER;

SELECT * FROM users
ORDER BY user_id;


SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM events;
SELECT COUNT(*) FROM sessions;

---When did users sign up?
SELECT DATE(signup_date) AS signup_day,COUNT(*) AS users_signed_up
FROM users
GROUP BY signup_day
ORDER BY signup_day;

---User distribution by plan
SELECT plan_type,COUNT(*) AS users
FROM users
GROUP BY plan_type;

---Team size vs users
SELECT team_size,COUNT(*) AS users
FROM users
GROUP BY team_size
ORDER BY team_size;

---DAU
SELECT event_date, COUNT(DISTINCT user_id) AS dau
FROM events
GROUP BY event_date
ORDER BY event_date;

---MAU
SELECT DATE_TRUNC('month', event_date) AS month, COUNT(DISTINCT user_id) AS mau
FROM events
GROUP BY month
ORDER BY month;

---Event type distribution
SELECT 
    event_type,
    COUNT(*) AS total_events
FROM events
GROUP BY event_type
ORDER BY total_events DESC;

---Feature adoption (users per feature)
SELECT 
    feature_name,
    COUNT(DISTINCT user_id) AS users_using_feature
FROM events
GROUP BY feature_name
ORDER BY users_using_feature DESC;

---Sessions per user
SELECT 
    user_id,
    COUNT(*) AS total_sessions
FROM sessions
GROUP BY user_id
ORDER BY user_id;

---Average session duration
SELECT 
    AVG(EXTRACT(EPOCH FROM (session_end - session_start)) / 60) AS avg_session_minutes
FROM sessions;

---Find users who created a task
SELECT DISTINCT user_id
FROM events
WHERE event_type = 'create_task';

---Find users who completed a task
SELECT DISTINCT user_id
FROM events
WHERE event_type = 'complete_task';

---Attach signup date to events
SELECT
    e.user_id,
    u.signup_date,
    e.event_type,
    e.event_date,
    (e.event_date - u.signup_date) AS days_after_signup
FROM events e
JOIN users u ON e.user_id = u.user_id;

---Users who created AND completed tasks within 7 days
WITH user_actions AS (
    SELECT
        e.user_id,
        MIN(CASE WHEN e.event_type = 'create_task' THEN e.event_date END) AS first_task_created,
        MIN(CASE WHEN e.event_type = 'complete_task' THEN e.event_date END) AS first_task_completed
    FROM events e
    GROUP BY e.user_id
)
SELECT
    ua.user_id
FROM user_actions ua
JOIN users u ON ua.user_id = u.user_id
WHERE
    ua.first_task_created IS NOT NULL
    AND ua.first_task_completed IS NOT NULL
    AND ua.first_task_created <= u.signup_date + INTERVAL '7 days'
    AND ua.first_task_completed <= u.signup_date + INTERVAL '7 days';


---Activation Rate (BIG KPI)
WITH activated_users AS (
    SELECT
        ua.user_id
    FROM (
        SELECT
            e.user_id,
            MIN(CASE WHEN e.event_type = 'create_task' THEN e.event_date END) AS first_task_created,
            MIN(CASE WHEN e.event_type = 'complete_task' THEN e.event_date END) AS first_task_completed
        FROM events e
        GROUP BY e.user_id
    ) ua
    JOIN users u ON ua.user_id = u.user_id
    WHERE
        ua.first_task_created IS NOT NULL
        AND ua.first_task_completed IS NOT NULL
        AND ua.first_task_created <= u.signup_date + INTERVAL '7 days'
        AND ua.first_task_completed <= u.signup_date + INTERVAL '7 days'
)
SELECT
    COUNT(DISTINCT au.user_id) * 1.0 / COUNT(DISTINCT u.user_id) AS activation_rate
FROM users u
LEFT JOIN activated_users au ON u.user_id = au.user_id;

---FUNNEL ANALYSIS
SELECT
    COUNT(DISTINCT u.user_id) AS signed_up,
    COUNT(DISTINCT CASE WHEN e.event_type = 'login' THEN u.user_id END) AS logged_in,
    COUNT(DISTINCT CASE WHEN e.event_type = 'create_task' THEN u.user_id END) AS created_task,
    COUNT(DISTINCT CASE WHEN e.event_type = 'complete_task' THEN u.user_id END) AS completed_task
FROM users u
LEFT JOIN events e ON u.user_id = e.user_id;

---Events per user
SELECT
    user_id,
    COUNT(*) AS total_events
FROM events
GROUP BY user_id;













