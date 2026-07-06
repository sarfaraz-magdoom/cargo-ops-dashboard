-- Creating db

IF DB_ID('CargoOps') IS NULL
    CREATE DATABASE CargoOps;
GO

USE CargoOps;
GO

-- OTP by carrier

CREATE OR ALTER VIEW vw_otp_by_carrier AS
SELECT  carrier,
        COUNT(*)                                              AS flights,
        SUM(on_time)                                          AS on_time_flights,
        CAST(100.0 * SUM(on_time) / COUNT(*) AS DECIMAL(5,2)) AS otp_pct,
        AVG(CAST(arr_delay AS FLOAT))                         AS avg_arr_delay
FROM    fact_flights
GROUP BY carrier;
GO


-- milestone variance

CREATE OR ALTER VIEW vw_milestone_variance AS
SELECT 'RCS' AS milestone, AVG(var_rcs) AS avg_slip_min, SUM(fap) AS fap_count, COUNT(*) AS shipments FROM fact_cargo_iq
UNION ALL
SELECT 'DEP', AVG(var_dep), SUM(fap), COUNT(*) FROM fact_cargo_iq
UNION ALL
SELECT 'RCF', AVG(var_rcf), SUM(fap), COUNT(*) FROM fact_cargo_iq
UNION ALL
SELECT 'DLV', AVG(var_dlv), SUM(fap), COUNT(*) FROM fact_cargo_iq;
GO


-- tonnage by route which is Commercial freight volume per route (from the BTS T-100 fact).

CREATE OR ALTER VIEW vw_tonnage_by_route AS
SELECT  r.route, r.origin, r.dest,
        SUM(t.freight_tonnes)                                 AS freight_tonnes,
        SUM(t.mail_tonnes)                                    AS mail_tonnes,
        COUNT(*)                                              AS segments
FROM    fact_tonnage t
JOIN    dim_route r ON r.route = t.route
GROUP BY r.route, r.origin, r.dest;
GO


-- carrier scorecard

CREATE OR ALTER VIEW vw_carrier_scorecard AS
WITH ops AS (
    SELECT carrier,
           CAST(100.0 * SUM(on_time) / COUNT(*) AS DECIMAL(5,2)) AS otp_pct,
           COUNT(*) AS flights
		   FROM fact_flights GROUP BY carrier),
comm AS (
    SELECT carrier,
           SUM(freight_tonnes) AS freight_tonnes,
           100.0 * SUM(ftk) / NULLIF(SUM(aftk), 0) AS avg_load_factor
    FROM   fact_tonnage GROUP BY carrier)
SELECT  c.carrier,
        o.otp_pct,
        o.flights,
        m.freight_tonnes,
        CAST(m.freight_tonnes / NULLIF(o.flights,0) AS DECIMAL(10,2)) AS tonnes_per_flight,
		CAST(m.avg_load_factor AS DECIMAL(5,2)) AS avg_load_factor
FROM    dim_carrier c
INNER JOIN ops  o ON o.carrier = c.carrier
INNER JOIN comm m ON m.carrier = c.carrier;
GO


-- monthly OTP trend + MA
-- calculated using Window function: 3-month moving average of OTP, ordered by month
CREATE OR ALTER VIEW vw_otp_trend AS
WITH monthly AS (
    SELECT  d.year, d.month, d.month_name,
            CAST(100.0 * SUM(f.on_time) / COUNT(*) AS DECIMAL(5,2)) AS otp_pct
    FROM    fact_flights f
    JOIN    dim_date d ON d.flight_date = f.flight_date
    GROUP BY d.year, d.month, d.month_name)
SELECT  year, month, month_name, otp_pct,
        AVG(otp_pct) OVER (ORDER BY year, month
                           ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS otp_3mo_ma
FROM    monthly;
GO


-- load factor by route
-- How full the hold was, per route
CREATE OR ALTER VIEW vw_load_factor_by_route AS
SELECT  r.route, r.origin, r.dest,
        SUM(t.ftk)   AS rftk,
        SUM(t.aftk)  AS aftk,
        CAST(100.0 * SUM(t.ftk) / NULLIF(SUM(t.aftk), 0) AS DECIMAL(5,2)) AS load_factor_pct,
        SUM(t.freight_tonnes)   AS freight_tonnes,
        COUNT(*)                AS segments
FROM    fact_tonnage t
JOIN    dim_route r ON r.route = t.route
GROUP BY r.route, r.origin, r.dest;
GO


-- yield by carrier
-- below view gives Commercial efficiency: revenue earned per freight tonne-kilometre.
-- NOTE: revenue is MODELLED as rate is picked from actual cargo yield figure in recent IATA data

CREATE OR ALTER VIEW vw_yield_by_carrier AS
SELECT  carrier,
        SUM(est_revenue)                                      AS est_revenue,
        SUM(ftk)                                              AS total_ftk,
        SUM(freight_tonnes)                                   AS freight_tonnes,
        CAST(SUM(est_revenue) / NULLIF(SUM(ftk),0) AS DECIMAL(10,4)) AS yield_per_ftk
FROM    fact_tonnage
GROUP BY carrier;
GO


-- dwell by hub
-- Average ground dwell time is (RCF -> DLV) per hub
CREATE OR ALTER VIEW vw_dwell_by_hub AS
SELECT  hub,
        CAST(AVG(dwell_min) AS DECIMAL(10,2))                 AS avg_dwell_min,
        SUM(fap)                                              AS fap_count,
        COUNT(*)                                              AS shipments
FROM    fact_cargo_iq
GROUP BY hub;
GO
