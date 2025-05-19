# Data Analytics SQL Assessment

This repository contains the SQL solutions for the Data Analyst Assessment. Each SQL file corresponds to one of the questions in the assessment.

## Database Tables Overview

The queries operate on the following conceptual tables:

- `users_customuser`: Customer demographic and contact information (e.g., `id`, `name`, `date_joined`).
- `savings_savingsaccount`: Records of deposit transactions (e.g., `id`, `owner_id`, `plan_id`, `confirmed_amount`, `transaction_date`).
- `plans_plan`: Records of plans created by customers (e.g., `id`, `owner_id`, `is_regular_savings`, `is_a_fund`, `creation_date`).
- `withdrawals_withdrawal`: Records of withdrawal transactions (not directly used in these specific queries but part of the schema).

**Key Hints Utilized:**

- `owner_id` is a foreign key to `users_customuser.id`.
- `plan_id` is a foreign key to `plans_plan.id`.
- Savings plan: `plans_plan.is_regular_savings = 1`.
- Investment plan: `plans_plan.is_a_fund = 1`.
- `confirmed_amount` is the field for value of inflow (assumed to be in kobo).
- All amount fields are in kobo (100 kobo = 1 main currency unit).

## Per-Question Explanations

All queries use Common Table Expressions (CTEs) for clarity and modularity. SQLite syntax for date functions (`DATE('now')`, `JULIANDAY()`, `STRFTIME()`) is used.

### Assessment_Q1.sql: High-Value Customers with Multiple Products

- **Objective:** Identify customers with at least one funded savings plan AND one funded investment plan, sorted by total deposits.
- **Approach:**
  1.  `CustomerPlanTypes` CTE: Identifies plans belonging to customers and flags them as savings or investment types based on `is_regular_savings` and `is_a_fund` columns in `plans_plan`.
  2.  `FundedCustomerPlans` CTE: Joins `CustomerPlanTypes` with `savings_savingsaccount` to ensure plans have associated deposits (i.e., are "funded"). It then counts distinct funded savings plans and funded investment plans per customer.
  3.  `CustomerTotalDeposits` CTE: Calculates the sum of `confirmed_amount` from `savings_savingsaccount` for each customer.
  4.  Final `SELECT`: Joins these CTEs with `users_customuser` to get customer names, filters for customers having at least one of each plan type, and orders by total deposits (converted from kobo to main currency unit).

### Assessment_Q2.sql: Transaction Frequency Analysis

- **Objective:** Calculate the average number of transactions per customer per month and categorize them into "High", "Medium", or "Low" frequency.
- **Approach:**
  1.  `CustomerMonthlyTransactions` CTE: Groups transactions by `owner_id` and month (`STRFTIME('%Y-%m', transaction_date)`) to count transactions made by each customer in each specific month.
  2.  `CustomerAverageTransactions` CTE: Calculates the average number of transactions per _active_ month for each customer. This is derived by dividing their total transactions by the count of distinct months in which they transacted.
  3.  `CategorizedCustomers` CTE: Applies a `CASE` statement to categorize customers based on their `avg_transactions_per_active_month`.
  4.  Final `SELECT`: Groups the categorized customers to count the number of customers in each `frequency_category` and calculates the overall average `avg_transactions_per_month` for that category. Results are rounded and ordered.

### Assessment_Q3.sql: Account Inactivity Alert

- **Objective:** Find active accounts (savings or investments) with no inflow transactions in the last 1 year (365 days).
- **Approach:**
  1.  `PlanLastTransaction` CTE: Determines the most recent `transaction_date` for each `plan_id` from `savings_savingsaccount`.
  2.  `ActivePlansDetails` CTE: Selects "active" plans (savings or investment) from `plans_plan`. It joins with `PlanLastTransaction` to get the `last_transaction_date`. If a plan has no transactions, its `creation_date` is used as the `effective_last_activity_date`. The actual `last_transaction_date` (which can be NULL) is also preserved.
  3.  Final `SELECT`: Filters `ActivePlansDetails` for plans where `effective_last_activity_date` is older than 365 days from `DATE('now')`. It outputs plan details, owner ID, plan type, the actual last transaction date, and `inactivity_days` (calculated as the difference between `DATE('now')` and `effective_last_activity_date`).
  - **Note on Example Output:** The query strictly adheres to the "no transactions in the last 1 year" condition. The example output for Q3 shows a plan with `inactivity_days = 92`, which would typically not meet this filter. The query prioritizes the textual requirement.

### Assessment_Q4.sql: Customer Lifetime Value (CLV) Estimation

- **Objective:** For each customer, calculate account tenure, total transactions, and an estimated CLV.
- **CLV Formula:** `CLV = (total_transactions / tenure_months) * 12 * avg_profit_per_transaction`
- **Profit per transaction:** 0.1% of the transaction value (kobo).
- **Approach:**
  1.  `CustomerTransactionSummary` CTE: Calculates the total number of transactions (`total_transactions_count`) and the sum of `confirmed_amount` (`total_value_kobo`) for each `owner_id` from `savings_savingsaccount`.
  2.  `CustomerDetails` CTE: Joins `users_customuser` with `CustomerTransactionSummary`. It calculates `tenure_months` using `JULIANDAY` difference between `DATE('now')` and `date_joined`, ensuring a minimum tenure of 1 month. It also retrieves total transactions and total value.
  3.  Final `SELECT`: Calculates the `estimated_clv`. The CLV formula was simplified to `(12 / tenure_months) * total_value_kobo * 0.00001` to directly use the total transaction value in kobo and output CLV in the main currency unit (by applying the 0.1% profit margin and kobo-to-main-currency conversion). Handles cases with zero tenure or zero transactions by defaulting CLV to 0.00. Results are ordered by `estimated_clv` descending.

## Challenges and Assumptions

- **Schema Details:** Assumed column names like `users_customuser.name`, `users_customuser.date_joined`, `plans_plan.creation_date`, and `savings_savingsaccount.transaction_date` based on problem descriptions and typical database design.
- **Date Functions:** Used SQLite specific date functions (`DATE('now')`, `JULIANDAY`, `STRFTIME`). These might need adjustment for other SQL databases.
- **"Funded" Plan (Q1):** Assumed a plan is "funded" if it has at least one associated deposit transaction with `confirmed_amount > 0` in `savings_savingsaccount`.
- **"Average Transactions Per Month" (Q2):** Interpreted as total transactions divided by the number of distinct months in which the customer made at least one transaction.
- **Account Inactivity (Q3):**
  - The query strictly follows the textual requirement ("no transactions in the last 1 year"). The example output for Q3 (showing `inactivity_days=92`) seems to contradict this if `DATE('now')` is recent; this row would not be selected by the query.
  - If a plan has never had a transaction, its inactivity is determined based on its `creation_date`.
  - `DATE('now')` is used for current date. For exact reproduction of example `inactivity_days`, a fixed "current date" (e.g., '2023-11-10') might be needed in the assessment environment.
- **CLV Calculation (Q4):**
  - Tenure is calculated in months, with a minimum of 1 month. The `JULIANDAY` difference divided by 30.4375 (average days in a month) is used for approximation.
  - Amounts are in kobo; conversion to the main currency unit (division by 100) is applied for `total_deposits` (Q1) and the final `estimated_clv` (Q4).
  - The CLV formula was algebraically simplified for direct calculation.
- **Data Integrity:** Assumed `owner_id` and `plan_id` foreign keys are consistent. Assumed boolean-like fields (`is_regular_savings`, `is_a_fund`) use 1 for true.
