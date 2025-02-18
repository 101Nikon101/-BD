CREATE TABLE IF NOT EXISTS st.ndam_log (
    dt DATE,
    link VARCHAR(50),
    user_agent VARCHAR(200),
    region VARCHAR(30)
);

INSERT INTO st.ndam_log (dt, link, user_agent, region)
SELECT
    log_data.dt,
    log_data.link,
    log_data.user_agent,
    ip_data.region
FROM (
    SELECT

        substring(data FROM '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+') AS ip,


        to_timestamp(substring(data FROM '\t([0-9]{14})\t'), 'YYYYMMDDHH24MISS')::DATE AS dt,


        trim(substring(data FROM '\t(http[^\t]+)')) AS link,


        trim(substring(data FROM '\t[0-9]+\t[0-9]+\t(.+)')) AS user_agent
    FROM de.log
) AS log_data
LEFT JOIN (
    SELECT

        split_part(data, E'\t', 1) AS ip,

        split_part(data, E'\t', 2) AS region
    FROM de.ip
) AS ip_data
ON log_data.ip = ip_data.ip;

CREATE TABLE IF NOT EXISTS st.ndam_log_report (
    region VARCHAR(30),
    browser VARCHAR(10)
);

INSERT INTO st.ndam_log_report (region, browser)
SELECT region, browser
FROM (
    SELECT region, 
           substring(user_agent FROM '([A-Z][a-zA-Z]+)') AS browser,
           count(*) AS browser_count
    FROM st.ndam_log
    GROUP BY region, browser
) AS browser_data
WHERE (region, browser_count) IN (
    SELECT region, max(browser_count)
    FROM (
        SELECT region, 
               substring(user_agent FROM '([A-Z][a-zA-Z]+)') AS browser,
               count(*) AS browser_count
        FROM st.ndam_log
        GROUP BY region, browser
    ) AS inner_data
    GROUP BY region
);

SELECT * FROM st.ndam_log;
SELECT * FROM st.ndam_log_report;