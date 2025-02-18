CREATE TABLE st.ndam_salary_hist (
    PERSON VARCHAR(255),
    CLASS VARCHAR(255),
    SALARY NUMERIC(10,2),
    EFFECTIVE_FROM DATE,
    EFFECTIVE_TO DATE
);

WITH hist AS (
    SELECT 
        person,
        class,
        salary,
        dt::DATE AS effective_from,
        -- Если следующей даты нет, ставим максимально возможную ,
        -- а затем отнимаем 1 день, чтобы задать корректный диапазон
        LEAD(dt::DATE, 1, '9999-12-31'::DATE) OVER (PARTITION BY person ORDER BY dt::DATE)
          - INTERVAL '1 day' AS effective_to
    FROM de.histgroup
)
INSERT INTO ST.ndam_SALARY_HIST (PERSON, CLASS, SALARY, EFFECTIVE_FROM, EFFECTIVE_TO)
SELECT person, class, salary, effective_from, effective_to
FROM hist;

CREATE TABLE ST.ndam_SALARY_LOG (
    PAYMENT_DT DATE,
    PERSON VARCHAR(255),
    PAYMENT NUMERIC(10,2),
    MONTH_PAID NUMERIC(10,2),
    MONTH_REST NUMERIC(10,2)
);

WITH salary_payments AS (
    -- Приводим дату платежа к типу DATE и выделяем год и месяц
    SELECT
        dt::DATE AS payment_dt,
        person,
        payment,
        EXTRACT(YEAR FROM dt::DATE) AS payment_year,
        EXTRACT(MONTH FROM dt::DATE) AS payment_month
    FROM de.salary_payments
),
salary_info AS (
    -- Объединяем платежи с историей зарплат:
    -- для каждого платежа находим запись из ST.ndam_SALARY_HIST,
    -- в которой payment_dt попадает в диапазон EFFECTIVE_FROM и EFFECTIVE_TO
    SELECT
        h.person,
        h.salary,
        h.effective_from,
        h.effective_to,
        sp.payment_dt,
        sp.payment,
        sp.payment_year,
        sp.payment_month
    FROM ST.ndam_SALARY_HIST h
    JOIN salary_payments sp
        ON h.person = sp.person
       AND sp.payment_dt BETWEEN h.effective_from AND h.effective_to
),
monthly_aggregation AS (
    -- Группируем по сотруднику, году и месяцу, рассчитываем:
    -- 1. Сумму всех платежей в месяце (MONTH_PAID)
    -- 2. Ожидаемую зарплату за месяц (берем, например, MAX(salary), поскольку в пределах месяца она одинакова)
    SELECT
       person,
       payment_year,
       payment_month,
       MAX(salary) AS expected_salary,
       SUM(payment) AS monthly_paid
    FROM salary_info
    GROUP BY person, payment_year, payment_month
)
-- Сохраняем результат в таблицу ST.ndam_SALARY_LOG.
-- Для каждого платежа выводим его дату, сумму и добавляем агрегированные значения за месяц.
INSERT INTO ST.ndam_SALARY_LOG (PAYMENT_DT, PERSON, PAYMENT, MONTH_PAID, MONTH_REST)
SELECT 
    si.payment_dt,
    si.person,
    si.payment,
    ma.monthly_paid AS month_paid,
    (ma.expected_salary - ma.monthly_paid) AS month_rest
FROM salary_info si
JOIN monthly_aggregation ma 
   ON si.person = ma.person 
   AND si.payment_year = ma.payment_year 
   AND si.payment_month = ma.payment_month
ORDER BY si.payment_dt;

select * from st.ndam_salary_hist
select * from st.ndam_salary_log