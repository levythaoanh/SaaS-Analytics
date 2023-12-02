/* 
DOCUMENT:
    You are working for a company that offers Software as a Service ( SaaS) online. Their customers can try the product before purchasing. 
    If the work is too heavy, they must pay first. The transaction of the users is stored in the table events. 
    The information of the users is stored in the table user_info. 
    If the customer account is suspended, the last login date of the user will be recorded, the statistics of the account will be calculated and stored in the table.  
    The geography data contains the country code and the geospatial data in case you want to visualize a map. 

HINT:
    First you need to read the file Descriptive to understand what i do, which will describe the requirements of each question
*/

--Question 1 : Descriptive statistics. 
SELECT 
    count(distinct(user_id)) as total_user_by_date
    , date 
FROM `events.events` 
GROUP BY date;

SELECT 
	distinct(user_id) 
    , count(distinct(id)) as total_access 
    , platform
    , round(sum(volume),3) as used_time
    , ROUND(AVG(volume),2) AS avg_used_time
    , round(sum(fee),5) as total_cost  
FROM `events.events`
WHERE user_id IS NOT NULL
GROUP BY user_id , platform;

SELECT 
  mp_country_code
  , count(distinct(user_id)) as total_user
FROM `events.user_info` 
WHERE mp_country_code IS NOT NULL
GROUP BY mp_country_code
ORDER BY total_user DESC;

--Question 3 
WITH 
    day_retain AS (
        SELECT 
            user_id
            , date
            , dense_rank() over (partition by user_id order by date) as rank_date
        FROM `events.events`
        WHERE user_id IS NOT NULL
        GROUP BY user_id, date
    )
    SELECT 
        concat('Day', rank_date - 1) AS retention_day
        , COUNT(user_id) AS retained_user_by_date
        , ROUND(COUNT(user_id)/(SELECT COUNT(distinct(user_id)) FROM Q3_1), 2) AS retention_rate
    FROM Q3_1
    WHERE rank_date < 9
    GROUP BY rank_date
    ORDER BY 1;

--RETENTION RATE BY WEEK
WITH
    user_fisrt_week AS (
        SELECT 
            user_id
            , min(date) AS first_week
        FROM events.events 
        WHERE user_id IS NOT NULL
        GROUP BY user_id
    ), 
    user_retention_week AS (
        SELECT
            user_id
            , date as retention_week
        FROM `events.events`
        WHERE user_id IS NOT NULL
        GROUP BY user_id, date 
    ),
    new_user_by_week AS (
        SELECT 
            first_week
            , count(ufd.user_id) as new_user
        FROM user_fisrt_week ufd
        GROUP BY first_week
    ),
    retained_user_by_week AS (
        SELECT 
            first_week
            , retention_week
            , count(urw.user_id) as retained_user
        FROM user_retention_week urw
        LEFT JOIN user_fisrt_week ufw ON ufw.user_id = urw.user_id
        GROUP BY first_week, retention_week
    )
    SELECT 
        ru.first_week
        , ru.retention_week
        , CONCAT ('W' , ROUND(FLOOR( EXTRACT( DAY FROM (ru.retention_week - ru.first_week))/7), 0)) AS retention_week_no
        , nu.new_user
        , ru.retained_user
        , ru.retained_user/nu.new_user as retention_rate
    FROM retained_user_by_week ru
    LEFT JOIN new_user_by_week nu ON ru.first_week = nu.first_week
    ORDER BY ru.first_week, ru.retention_week;

--Question 4
WITH 
    count_account_per_user AS (
        SELECT 
            distinct(user_id)
            , count(created_date) as num_account
            , mp_country_code
        FROM `events.user_info`
        WHERE user_id IS NOT NULL
        GROUP BY user_id , mp_country_code
        ORDER BY num_account DESC
    ) ,
    avg_number_account AS (
        SELECT round(sum(apu.num_account)/count(distinct(user_id)),4) as avg
        FROM count_account_per_user apu
    ) 
    SELECT 
        user_id
        , apu.num_account
        , mp_country_code
    FROM count_account_per_user apu
    WHERE apu.num_account > (SELECT avg FROM avg_number_account);
 
--Question 5
WITH 
    num_access AS (
        SELECT  
            user_id
            , max(access_time) as time_diff
            , 1 as rank_diff
        FROM (
            SELECT *
                , IFNULL( TIMESTAMP_DIFF(datetime, LAG(datetime) OVER ( PARTITION BY user_id ORDER BY datetime), HOUR ), 0) AS access_time,
            FROM `events.events`
        )
        WHERE access_time < 6
        GROUP BY rank_diff, user_id 

        UNION ALL

        SELECT  
            user_id
            , access_time time_diff
            , row_number() over (PARTITION BY user_id ORDER BY access_time asc) +1 as rank_diff
        FROM (
            SELECT *
                ,IFNULL( TIMESTAMP_DIFF(datetime, LAG(datetime) OVER ( PARTITION BY user_id ORDER BY datetime), HOUR ), 0) AS access_time,
            FROM `events.events`
        )
        WHERE access_time >= 6
    )
    SELECT 
        user_id
        , COUNT(rank_diff) total_access
    FROM num_access
    WHERE user_id IS NOT NULL
    GROUP BY user_id
    ORDER BY user_id;

--Question 6 : Customer Segmentation 
WITH 
    active_account AS (
        SELECT 
            user_id,
            CASE 
                WHEN MIN(created_date) < '2023-01-01' THEN '2023-01-01'
                ELSE MIN(created_date)
            END AS created_date
        FROM `events.user_info`
        group by user_id
    ),
    RFM_statistics AS (
        SELECT 
            ev.user_id 
            ,IFNULL(ABS(DATE_DIFF(max(ev.date), '2023-03-05', day)), 100)  as Recency
            ,IFNULL(ROUND(SUM(ev.volume)/ABS(DATE_DIFF(min(aa.created_date), '2023-03-05', day)),2), 0) as Frequency
            ,IFNULL(SUM(ev.fee), 0) as Monetary
        FROM `events.events` ev
        LEFT JOIN active_account aa ON aa.user_id = ev.user_id
        WHERE ev.user_id IS NOT NULL
        GROUP BY ev.user_id 
    ),
    RFM_calculation AS (
        SELECT *,
            CASE 
                WHEN Recency >= 55 THEN '4'
                WHEN Recency >= 40 AND Recency < 55 THEN '3'
                WHEN Recency >= 20 AND Recency < 40 THEN '2'
                ELSE '1'
            END AS R,
            CASE 
                WHEN Frequency = 0 THEN '1'
                WHEN Frequency > 0 AND Frequency < 0.1 THEN '2'
                WHEN Frequency >= 0.1 AND Frequency < 2 THEN '3'
                ELSE '4'
            END AS F,
            CASE 
                WHEN Monetary < 0.000000001 THEN '1'
                WHEN Monetary >= 0.000000001 AND Monetary < 0.1 THEN '2'
                WHEN Monetary >= 0.1 AND Monetary < 0.5 THEN '3'
                ELSE '4'
            END AS M
        FROM RFM_statistics
    ) ,
    mapping_RFM AS (
    SELECT *, 
        concat (R,F,M) as RFM
    FROM RFM_calculation
    ) 
    SELECT user_id, Recency, Frequency, Monetary, R, F, M, RFM,
        CASE 
            WHEN RFM IN ('444') THEN 'Champions'
            WHEN RFM IN ('334', '342', '343', '344', '433', '434', '443') THEN 'Loyal Customers'
            WHEN RFM IN ('332','333','341','412','413','414','431','432','441','442','421','422','423','424') THEN 'Potential Loyalist'
            WHEN RFM IN ('411') THEN 'Recent Customers'
            WHEN RFM IN ('311', '312', '313', '331') THEN 'Promising'
            WHEN RFM IN ('212','213','214','231','232','233','241','314','321','322','323','324') THEN 'Customer Needing Attention'
            WHEN RFM IN ('211') THEN 'About to Sleep'
            WHEN RFM IN ('112','113','114','131','132','133','142','124','123','122','121','224','223','222','221') THEN 'At Risk'
            WHEN RFM IN ('134','143','144','234','242','243','244') THEN "Can't Lose Them"
            WHEN RFM IN ('141') THEN 'Hibernating'
            ELSE 'Lost'
        END AS Segment_Name  
    FROM mapping_RFM