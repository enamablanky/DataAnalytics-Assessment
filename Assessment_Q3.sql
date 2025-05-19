-- Question 3: Account Inactivity Alert

-- For reproducibility of the example's inactivity_days, one might need a fixed 'current_date'.
-- Let's assume 'now' is '2023-11-10' to match the example's 92 days for a 2023-08-10 transaction.
-- However, for a general solution, DATE('now') is better. I will use DATE('now').
-- The example output might be illustrative of columns, not necessarily a row that passes the filter under typical 'now'.

WITH PlanLastTransaction AS (
    -- Get the last transaction date for each plan
    SELECT
        plan_id,
        MAX(transaction_date) AS last_transaction_date
    FROM savings_savingsaccount
    GROUP BY plan_id
),
ActivePlansDetails AS (
    -- Get details of active plans (savings or investments)
    SELECT
        p.id AS plan_id,
        p.owner_id,
        CASE
            WHEN p.is_regular_savings = 1 THEN 'Savings'
            WHEN p.is_a_fund = 1 THEN 'Investment'
            ELSE 'Other' -- Should not happen based on problem context
        END AS type,
        COALESCE(plt.last_transaction_date, p.creation_date) AS effective_last_activity_date, -- Use plan creation if no transactions
        plt.last_transaction_date AS actual_last_transaction_date, -- Store actual last transaction date separately
        p.creation_date -- Needed if no transactions ever
    FROM plans_plan p
    LEFT JOIN PlanLastTransaction plt ON p.id = plt.plan_id
    WHERE p.is_regular_savings = 1 OR p.is_a_fund = 1
)
SELECT
    apd.plan_id,
    apd.owner_id,
    apd.type,
    apd.actual_last_transaction_date AS last_transaction_date, -- Show actual last transaction date, which can be NULL
    -- Inactivity days calculated from 'now' to the effective_last_activity_date
    -- The example output's inactivity_days (92 for 2023-08-10) implies 'now' is around 2023-11-10.
    -- If last_transaction_date is NULL, inactivity is from plan creation.
    CAST(JULIANDAY(DATE('now')) - JULIANDAY(apd.effective_last_activity_date) AS INTEGER) AS inactivity_days
FROM ActivePlansDetails apd
WHERE
    apd.effective_last_activity_date < DATE('now', '-365 days');

/*
Assumptions for Q3:
1. "Active accounts" are plans where `is_regular_savings = 1` OR `is_a_fund = 1`.
2. "No transactions in the last 1 year" means the `MAX(transaction_date)` for the plan is older than 365 days ago,
   OR the plan has never had any transactions AND its `creation_date` is older than 365 days ago.
   The `effective_last_activity_date` handles this by taking `creation_date` if no transactions.
3. `plans_plan` has `id`, `owner_id`, `is_regular_savings`, `is_a_fund`, and `creation_date`.
4. `savings_savingsaccount` has `plan_id`, `transaction_date`.
5. `DATE('now')` is used as the current date. The example output's `inactivity_days` might imply a fixed 'current date' for the assessment environment (e.g., '2023-11-10').
   If `last_transaction_date` is `2023-08-10` and `inactivity_days` is 92, then `DATE('now')` is `2023-11-10`.
   A plan with `last_transaction_date = 2023-08-10` would NOT be selected by the filter `effective_last_activity_date < DATE('now', '-365 days')` if `DATE('now')` is `2023-11-10`.
   The query strictly follows the "no transactions in the last 1 year" filter.
*/