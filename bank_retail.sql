create database retail_bank;
use retail_bank;
create table branches(
    branch_id varchar(5) primary key,
    branch_name varchar(50) not null,
    city varchar(50) not null,
    state varchar(2) not null,
    region varchar(20) not null,
    opening_date date not null,
    employee_count int not null);
create table customers(
    customer_id varchar(7) primary key,
    first_name varchar(50) not null,
    last_name varchar(50) not null,
    date_of_birth date not null,
    gender varchar(20) not null,
    city varchar(50) not null,
    state varchar(2) not null,
    customer_since date not null,
    kyc_status varchar(20) not null,
    segment varchar(20) not null,
    annual_income decimal(12,2) not null,
    credit_score int not null,
    is_active varchar(3) not null);
create table accounts(
    account_id varchar(10) primary key,
    customer_id varchar(7) not null,
    branch_id varchar(5) not null,
    account_type varchar(30) not null,
    open_date date not null,
    close_date date null,
    current_balance decimal(15,2) not null,
    interest_rate decimal(5,2) not null,
    overdraft_limit decimal(15,2) not null,
    status varchar(10) not null,
    foreign key (customer_id)references customers(customer_id),
    foreign key (branch_id)references branches(branch_id));
create table cards(
    card_id varchar(10) primary key,
    account_id varchar(10) not null,
    card_type varchar(10) not null,
    issue_date date not null,
    expiry_date date not null,
    credit_limit decimal(15,2) not null,
    outstanding_balance decimal(15,2) not null,
    reward_points int not null,
    is_active varchar(3) not null,
    network varchar(20) not null,
    foreign key (account_id)references accounts(account_id));
create table loans(
    loan_id varchar(7) primary key,
    customer_id varchar(7) not null,
    branch_id varchar(5) not null,
    loan_type varchar(30) not null,
    principal_amount decimal(15,2) not null,
    interest_rate decimal(5,2) not null,
    tenure_months int not null,
    disbursement_date date not null,
    maturity_date date not null,
    emi_amount decimal(15,2) not null,
    outstanding_balance decimal(15,2) not null,
    loan_status varchar(20) not null,
    purpose varchar(30) not null,
    foreign key (customer_id)references customers(customer_id),
    foreign key (branch_id)references branches(branch_id));
create table loan_payments(
    payment_id varchar(9) primary key,
    loan_id varchar(7) not null,
    payment_date date not null,
    scheduled_amount decimal(15,2) not null,
    paid_amount decimal(15,2) not null,
    principal_paid decimal(15,2) not null,
    interest_paid decimal(15,2) not null,
    penalty decimal(15,2) not null,
    days_late int not null,
    payment_method varchar(20) not null,
    status varchar(10) not null,
    foreign key (loan_id)references loans(loan_id));
create table transactions(
    transaction_id varchar(11) primary key,
    account_id varchar(10) not null,
    transaction_date date not null,
    transaction_time time not null,
    transaction_type varchar(20) not null,
    amount decimal(15,2) not null,
    channel varchar(20) not null,
    description varchar(50) not null,
    balance_after decimal(15,2) not null,
    status varchar(15) not null,
    foreign key (account_id) references accounts(account_id));   
 -- What is the total number of customers?
 -- What is the total number of accounts?
 -- What is the total number of loans?
 
select count(*)as total_accounts from accounts;
select count(*) as total_customers from customers;
select count(*) from branches;
select count(*) from loans;
select count(*) from loan_payments;
select count(*) from transactions;
select count(*) from cards;
alter table accounts
modify close_date varchar(20) null;
update accounts
set close_date = null
where close_date = '';
alter table accounts
modify close_date date null;
select count(*) from accounts;
describe accounts;
-- What are the different account types available?
select * from accounts;
select distinct account_type from accounts;

-- How many customers are currently active?
select * from customers;
select * from customers where is_active='Yes';

-- What are the different transaction types available?
select * from transactions;
select distinct transaction_type from transactions;

-- What is the total amount of completed transactions?
select sum(amount) as total_amount from transactions where status='Completed';

-- What are the different loan types available?
select * from loans;
select distinct loan_type from loans;

-- What is the total number of loans?
select count(*) from loans;

-- What are the different card types available?
select * from cards;
select distinct card_type from cards;

-- What is the total outstanding loan balance?
select sum(outstanding_balance) as total_outstanding_loan from loans;


-- 4.1 Understand Customer Profile and Segmentation
select * from customers;
-- Compare customers across different segments.
select segment,count(*) as total_customer from customers group by(segment) order by total_customer desc;
-- Look at customer demographics.
select gender,count(*) as total_customers from customers group by(gender) order by total_customers desc; 
-- Compare customers across cities and states.
select city,count(state) as total_state from customers group by city;
-- Examine income and credit-score differences.
select (sum(annual_income)-sum(credit_score))as total_difference from customers;
-- Look at customer activity and KYC status.
select count(*)as active_customers from customers where is_active='Yes';
select * from customers where is_active ='No';
-- Understand customer tenure with the bank.
select round(avg(datediff((
select max(transaction_date) 
from transactions),customer_since) / 365.25), 2) as avg_tenure_years from customers;

-- 4.2 Understand Account Usage and Branch Activity
-- Compare different account types.
select account_type,count(*) as account_count,round(avg(current_balance), 2) as avg_balance from accounts group by account_type order by account_count desc;
-- Compare account activity across customers.
select
    c.customer_id,
    concat(c.first_name, ' ', c.last_name) as customer_name,
    count(t.transaction_id) as transaction_count,
    round(sum(t.amount), 2) as total_txn_amount
from customers c
join accounts a
    on a.customer_id = c.customer_id
join transactions t
    on t.account_id = a.account_id
where t.status = 'completed'
group by c.customer_id, c.first_name, c.last_name
order by transaction_count desc, total_txn_amount desc limit 5;
-- Examine account balances.
select account_type,round(sum(current_balance), 2) as total_balance,
round(avg(current_balance), 2) as avg_balance,
round(max(current_balance), 2) as max_balance from accounts
group by account_type
order by total_balance desc;
-- Compare account activity across branches.
select
    b.branch_id,
    b.branch_name,
    count(a.account_id) as account_count,
    round(avg(a.current_balance), 2) as avg_balance
from branches b
join accounts a
    on a.branch_id = b.branch_id
group by b.branch_id, b.branch_name
order by account_count desc
limit 10;
-- Look at interest rates across account types.
select
    account_type,
    round(avg(interest_rate), 2) as avg_interest_rate,
    round(min(interest_rate), 2) as min_rate,
    round(max(interest_rate), 2) as max_rate
from accounts
group by account_type
order by avg_interest_rate desc;
-- Identify differences between active and closed accounts.
select
    status,
    count(*) as account_count,
    round(avg(current_balance), 2) as avg_balance,
    round(sum(current_balance), 2) as total_balance
from accounts
group by status
order by account_count desc;

-- 4.3 Analyze Transaction Patterns

-- Compare different transaction types.
select
    transaction_type,
    count(*) as transaction_count,
    round(sum(amount), 2) as total_amount,
    round(avg(amount), 2) as avg_amount
from transactions
where status = 'completed'
group by transaction_type
order by transaction_count desc;
-- Compare transactions across different channels.
select
    channel,
    count(*) as transaction_count,
    round(sum(amount), 2) as total_amount
from transactions
where status = 'completed'
group by channel
order by transaction_count desc;
-- Examine transaction amounts.
select
    round(min(amount), 2) as min_amount,
    round(avg(amount), 2) as avg_amount,
    round(max(amount), 2) as max_amount,
    round(sum(amount), 2) as total_amount
from transactions
where status = 'completed';
-- Look at common transaction descriptions.
select
    description,
    count(*) as transaction_count,
    round(sum(amount), 2) as total_amount
from transactions
where status = 'completed'
group by description
order by transaction_count desc
limit 10;
-- Examine transaction activity over time.
select
    date_format(transaction_date, '%Y-%m') as month,
    count(*) as completed_transactions,
    round(sum(amount), 2) as total_amount
from transactions
where status = 'completed'
group by date_format(transaction_date, '%Y-%m')
order by month desc
limit 12;
-- Compare transaction activity across accounts or customer groups.
select
    a.account_id,
    count(t.transaction_id) as transaction_count,
    round(sum(t.amount), 2) as total_amount
from accounts a
join transactions t
    on t.account_id = a.account_id
where t.status = 'completed'
group by a.account_id
order by transaction_count desc, total_amount desc
limit 10;
-- Look at how transaction activity affects account balances.
select
    transaction_type,
    round(avg(balance_after), 2) as avg_balance_after,
    round(min(balance_after), 2) as min_balance_after,
    round(max(balance_after), 2) as max_balance_after
from transactions
where status = 'completed'
group by transaction_type
order by avg_balance_after desc;

-- 4.4 Evaluate Loan Performance and Repayment Behaviour

-- Compare different loan types.
select
    loan_type,
    count(*) as loan_count,
    round(sum(principal_amount), 2) as total_principal,
    round(sum(outstanding_balance), 2) as outstanding_balance
from loans
group by loan_type
order by loan_count desc;
-- Compare loans based on their purpose.
select
    purpose,
    count(*) as loan_count,
    round(avg(principal_amount), 2) as avg_principal,
    round(sum(outstanding_balance), 2) as outstanding_balance
from loans
group by purpose
order by loan_count desc;
-- Examine loan amounts and outstanding balances.
select
    round(min(principal_amount), 2) as min_principal,
    round(avg(principal_amount), 2) as avg_principal,
    round(max(principal_amount), 2) as max_principal,
    round(sum(outstanding_balance), 2) as total_outstanding
from loans;
-- Compare loan statuses.
select
    loan_status,
    count(*) as loan_count,
    round(sum(outstanding_balance), 2) as outstanding_balance
from loans
group by loan_status
order by loan_count desc;
-- Identify loans with repayment delays.
select
    l.loan_id,
    l.customer_id,
    count(p.payment_id) as late_payment_count,
    round(avg(p.days_late), 2) as avg_days_late,
    round(sum(p.penalty), 2) as total_penalty
from loans l
join loan_payments p
    on p.loan_id = l.loan_id
where p.days_late > 0
group by l.loan_id, l.customer_id
order by late_payment_count desc, avg_days_late desc
limit 10;
-- Examine penalties and late payments.
select
    round(sum(penalty), 2) as total_penalty,
    round(avg(penalty), 2) as avg_penalty,
    round(max(penalty), 2) as max_penalty,
    sum(case when days_late > 0 then 1 else 0 end) as late_payments
from loan_payments;
-- Compare repayment behaviour across loan types or branches.
select
    l.loan_type,
    count(p.payment_id) as payments,
    sum(case when p.days_late > 0 then 1 else 0 end) as late_payments,
    round(avg(p.days_late), 2) as avg_days_late,
    round(sum(p.penalty), 2) as total_penalty
from loans l
join loan_payments p
    on p.loan_id = l.loan_id
group by l.loan_type
order by late_payments desc;
-- Look at payment methods used by customers.
select
    payment_method,
    count(*) as payment_count,
    sum(case when days_late > 0 then 1 else 0 end) as late_payment_count,
    round(avg(days_late), 2) as avg_days_late
from loan_payments
group by payment_method
order by late_payment_count desc;
-- 	4.5 Understand Card Usage and Product Engagement

-- Compare different card types.
select
    card_type,
    count(*) as card_count,
    round(avg(credit_limit), 2) as avg_credit_limit,
    round(avg(outstanding_balance), 2) as avg_outstanding
from cards
group by card_type
order by card_count desc;
-- Examine credit limits and outstanding balances.
select
    card_type,
    round(sum(credit_limit), 2) as total_credit_limit,
    round(sum(outstanding_balance), 2) as total_outstanding_balance,
    round(
        100 * sum(outstanding_balance) /
        nullif(sum(credit_limit), 0), 2
    ) as utilization_pct
from cards
where credit_limit > 0
group by card_type;
-- Compare active and inactive cards.
select
    is_active,
    count(*) as card_count,
    round(avg(reward_points), 2) as avg_reward_points
from cards
group by is_active
order by card_count desc;
-- Examine reward points.
select
    card_type,
    round(avg(reward_points), 2) as avg_reward_points,
    min(reward_points) as min_reward_points,
    max(reward_points) as max_reward_points
from cards
group by card_type
order by avg_reward_points desc;
-- Compare card usage across accounts and networks.
select
    a.account_type,
    c.network,
    count(*) as card_count,
    round(avg(c.outstanding_balance), 2) as avg_outstanding
from cards c
join accounts a
    on a.account_id = c.account_id
group by a.account_type, c.network
order by card_count desc
limit 10;
-- Identify customers using multiple banking products.
select count(*) as multi_product_customers
from (
    select c.customer_id
    from customers c
    left join accounts a
        on a.customer_id = c.customer_id
    left join loans l
        on l.customer_id = c.customer_id
    left join cards ca
        on ca.account_id = a.account_id
    group by c.customer_id
    having count(distinct a.account_id) > 0
       and count(distinct l.loan_id) > 0
       and count(distinct ca.card_id) > 0
) x;
-- Look at relationships between cards, accounts, and loans.
select count(distinct a.customer_id) as customers_with_cards_and_loans
from cards c
join accounts a
    on a.account_id = c.account_id
join loans l
    on l.customer_id = a.customer_id;


alter table accounts
modify column close_date varchar(20);
update accounts
set close_date = 'N/A'
where close_date is null
   or close_date = '';
alter table accounts
modify column close_date varchar(20) not null;