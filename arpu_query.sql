-- Задание 3. Кумулятивный ARPU


WITH monthly_data AS (      -- табличное выражение для расчета суммы платежей и количества пользователей за месяц
    SELECT
        EXTRACT(YEAR FROM p.payment_at) AS payment_year, 
        EXTRACT(MONTH FROM p.payment_at) AS payment_month, 
        SUM(p.amount) AS monthly_sum, 
        COUNT(DISTINCT u.user_id) AS monthly_users 
    FROM 
        user AS u
    INNER JOIN    -- внутреннее объединение, чтобы оставить только тех пользователей, которые совершали платежи
        payment AS p
    ON 
        u.user_id = p.user_id
    WHERE 
        EXTRACT(MONTH FROM u.installed_at) = 1   -- фильтр для пользователей, установивших приложение в январе 2023 г. 
        AND EXTRACT(YEAR FROM u.installed_at) = 2023
    GROUP BY 
        EXTRACT(YEAR FROM p.payment_at), 
        EXTRACT(MONTH FROM p.payment_at) 
),
cumulative_data AS ( -- табличное выражение, для расчета накопительной суммы, и накопительного количества пользователей
    SELECT
        payment_year,
        payment_month,
        SUM(monthly_sum) OVER (ORDER BY payment_year, payment_month) AS cumulative_sum,    -- расчет показателей с помощью оконной функции
        SUM(monthly_users) OVER (ORDER BY payment_year, payment_month) AS cumulative_users 
    FROM 
        monthly_data
)
SELECT
    payment_year,
    payment_month,
    cumulative_sum / cumulative_users AS cumulative_arpu  -- расчет ARPU
FROM 
    cumulative_data
ORDER BY 
    payment_year, 
    payment_month;