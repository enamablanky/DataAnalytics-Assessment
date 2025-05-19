-- Question 1: High-Value Customers with Multiple Products
-- Find customers with at least one funded savings plan AND one funded investment plan,
-- sorted by total deposits.
-- A plan is "funded" if it has associated deposit transactions.

WITH CustomerPlanTypes AS (
    -- Identify plan types for each customer
    SELECT
        pp.owner_id,
        pp.id AS plan_id,
        CASE WHEN pp.is_regular_savings = 1 THEN 1 ELSE 0 END AS is_savings_plan,
        CASE WHEN pp.is_a_fund = 1 THEN 1 ELSE 0 END AS is_investment_plan
    FROM plans_plan pp
    WHERE pp.is_regular_savings = 1 OR pp.is_a_fund = 1
),
FundedCustomerPlans AS (
    -- Correlate plans with actual deposits to ensure they are "funded"
    -- and count distinct funded plan types per customer
    SELECT
        cpt.owner_id,
        COUNT(DISTINCT CASE WHEN cpt.is_savings_plan = 1 THEN cpt.plan_id ELSE NULL END) AS savings_plan_count,
        COUNT(DISTINCT CASE WHEN cpt.is_investment_plan = 1 THEN cpt.plan_id ELSE NULL END) AS investment_plan_count
    FROM CustomerPlanTypes cpt
    JOIN savings_savingsaccount ssa ON cpt.plan_id = ssa.plan_id AND ssa.confirmed_amount > 0 -- Assuming funded means at least one deposit > 0
    GROUP BY cpt.owner_id
),
CustomerTotalDeposits AS (
    -- Calculate total deposits for each customer
    SELECT
        owner_id,
        SUM(confirmed_amount) AS total_deposits_kobo
    FROM savings_savingsaccount
    GROUP BY owner_id
)
SELECT
    fcp.owner_id,
    uc.name,
    fcp.savings_plan_count AS savings_count,    -- Renamed to match example output
    fcp.investment_plan_count AS investment_count, -- Renamed to match example output
    ctd.total_deposits_kobo / 100.0 AS total_deposits -- Convert kobo to main currency unit
FROM FundedCustomerPlans fcp
JOIN users_customuser uc ON fcp.owner_id = uc.id
JOIN CustomerTotalDeposits ctd ON fcp.owner_id = ctd.owner_id
WHERE
    fcp.savings_plan_count >= 1
    AND fcp.investment_plan_count >= 1
ORDER BY total_deposits DESC;

/*
Assumptions for Q1:
1. A plan is "funded" if there is at least one record in `savings_savingsaccount` for that `plan_id` with `confirmed_amount > 0`.
2. `users_customuser` has `id` and `name`.
3. `plans_plan` has `id`, `owner_id`, `is_regular_savings`, `is_a_fund`.
4. `savings_savingsaccount` has `owner_id`, `plan_id`, `confirmed_amount`.
5. `total_deposits` in the output refers to the sum of all deposits for the customer, converted from kobo.
*/