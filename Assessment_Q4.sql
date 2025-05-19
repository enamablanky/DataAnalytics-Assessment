-- Question 4: Customer Lifetime Value (CLV) Estimation
-- For each customer, calculate: Account tenure (months since signup), Total transactions, Estimated CLV.
-- CLV = (total_transactions / tenure) * 12 * avg_profit_per_transaction
-- Profit_per_transaction = 0.1% of the transaction value.
-- Amounts are in kobo. CLV output seems to be in main currency unit.

WITH CustomerTransactionSummary AS (
    -- Calculate total transactions and total value for each customer
    SELECT
        owner_id,
        COUNT(id) AS total_transactions_count, -- Assuming 'id' is PK of savings_savingsaccount
        SUM(confirmed_amount) AS total_value_kobo -- Sum of all transaction values in kobo
    FROM savings_savingsaccount
    GROUP BY owner_id
),
CustomerDetails AS (
    -- Get customer details and calculate tenure in months
    SELECT
        u.id AS customer_id,
        u.name,
        -- Calculate tenure in months. Add 1 to avoid zero tenure for new users in their first month.
        -- (STRFTIME('%Y', DATE('now')) - STRFTIME('%Y', u.date_joined)) * 12 +
        -- (STRFTIME('%m', DATE('now')) - STRFTIME('%m', u.date_joined)) + 1 AS tenure_months
        -- A more robust way for tenure, ensuring it's at least 1:
        MAX(1, ROUND((JULIANDAY(DATE('now')) - JULIANDAY(u.date_joined)) / 30.4375)) AS tenure_months,
        COALESCE(cts.total_transactions_count, 0) AS total_transactions,
        COALESCE(cts.total_value_kobo, 0) AS total_value_kobo
    FROM users_customuser u
    LEFT JOIN CustomerTransactionSummary cts ON u.id = cts.owner_id
)
SELECT
    cd.customer_id,
    cd.name,
    CAST(cd.tenure_months AS INTEGER) AS tenure_months, -- Cast to integer as per example
    cd.total_transactions,
    -- CLV Calculation:
    -- avg_profit_per_transaction_kobo = (total_value_kobo * 0.001) / total_transactions (if total_transactions > 0)
    -- CLV = (total_transactions / tenure_months) * 12 * avg_profit_per_transaction_kobo / 100 (for main currency)
    -- Simplified: CLV = (12 / tenure_months) * (total_value_kobo * 0.001 / 100)
    -- CLV = (12 / tenure_months) * total_value_kobo * 0.00001
    CASE
        WHEN cd.tenure_months > 0 AND cd.total_transactions > 0 THEN -- Ensure no division by zero and transactions exist
            ROUND(
                (12.0 / cd.tenure_months) * (cd.total_value_kobo * 0.001 / 100.0) -- Profit converted to main currency
            , 2)
        ELSE 0.00 -- Default CLV to 0 if no tenure or no transactions
    END AS estimated_clv
FROM CustomerDetails cd
ORDER BY estimated_clv DESC;

/*
Assumptions for Q4:
1. `users_customuser` has `id`, `name`, and `date_joined`.
2. `savings_savingsaccount` has `owner_id`, `confirmed_amount` (in kobo), and `id` (transaction PK).
3. Tenure is calculated in months from `date_joined` to `DATE('now')`. Minimum tenure is 1 month.
   The division by 30.4375 (avg days in a month) is an approximation.
4. Profit per transaction is 0.1% of `confirmed_amount`.
5. `total_transactions` in the CLV formula refers to the count of deposit transactions.
6. `avg_profit_per_transaction` is calculated as `(Total_Profit_from_all_transactions / total_transactions_count)`.
   Total_Profit = SUM(transaction_value * 0.001).
   So, avg_profit_per_transaction = (SUM(transaction_value_kobo) * 0.001) / total_transactions_count.
   The CLV formula simplifies to: (12 / tenure_months) * SUM(confirmed_amount_kobo) * 0.00001 (if CLV is in main currency).
7. The final CLV is rounded to 2 decimal places and presented in the main currency unit (kobo amounts / 100).
8. If a customer has no transactions or tenure is zero/negative (which is handled by MAX(1, ...)), CLV is 0.
*/