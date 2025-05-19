-- Question 2: Transaction Frequency Analysis
-- Calculate the average number of transactions per customer per month and categorize them.

WITH CustomerMonthlyTransactions AS (
    -- Count transactions per customer per month
    SELECT
        owner_id,
        STRFTIME('%Y-%m', transaction_date) AS transaction_month,
        COUNT(id) AS transactions_in_month -- Assuming 'id' is PK of savings_savingsaccount
    FROM savings_savingsaccount
    GROUP BY owner_id, STRFTIME('%Y-%m', transaction_date)
),
CustomerAverageTransactions AS (
    -- Calculate average monthly transactions for each customer
    -- This is total transactions / number of distinct months they transacted
    SELECT
        owner_id,
        SUM(transactions_in_month) AS total_transactions,
        COUNT(DISTINCT transaction_month) AS distinct_months_transacted,
        SUM(transactions_in_month) * 1.0 / COUNT(DISTINCT transaction_month) AS avg_transactions_per_active_month
    FROM CustomerMonthlyTransactions
    GROUP BY owner_id
),
CategorizedCustomers AS (
    -- Categorize customers based on their average monthly transactions
    SELECT
        owner_id,
        avg_transactions_per_active_month,
        CASE
            WHEN avg_transactions_per_active_month >= 10 THEN 'High Frequency'
            WHEN avg_transactions_per_active_month >= 3 AND avg_transactions_per_active_month < 10 THEN 'Medium Frequency'
            ELSE 'Low Frequency'
        END AS frequency_category
    FROM CustomerAverageTransactions
)
SELECT
    cc.frequency_category,
    COUNT(DISTINCT cc.owner_id) AS customer_count,
    ROUND(AVG(cc.avg_transactions_per_active_month), 1) AS avg_transactions_per_month
FROM CategorizedCustomers cc
GROUP BY cc.frequency_category
ORDER BY
    CASE cc.frequency_category -- Custom sort order to match example
        WHEN 'High Frequency' THEN 1
        WHEN 'Medium Frequency' THEN 2
        WHEN 'Low Frequency' THEN 3
    END;

/*
Assumptions for Q2:
1. "Average number of transactions per customer per month" means:
   (Total transactions for a customer) / (Number of distinct months in which that customer made any transaction).
   It does not consider months where the customer was active but made no transactions.
2. `savings_savingsaccount` has `owner_id`, `transaction_date`, and `id` (as transaction PK).
3. `users_customuser` is implicitly used via `owner_id`.
*/