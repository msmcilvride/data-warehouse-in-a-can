CREATE TABLE Person (
  id                  INT64 NOT NULL,
  name                STRING(MAX)
) PRIMARY KEY (id);

CREATE TABLE Account (
  id                  INT64 NOT NULL,
  create_time         TIMESTAMP,
  is_blocked          BOOL,
  type                STRING(MAX)
) PRIMARY KEY (id);

CREATE TABLE Loan (
  id                  INT64 NOT NULL,
  loan_amount         FLOAT64,
  balance             FLOAT64,
  create_time         TIMESTAMP,
  interest_rate       FLOAT64
) PRIMARY KEY (id);

CREATE TABLE AccountTransferAccount (
  id                  INT64 NOT NULL,
  to_id               INT64 NOT NULL,
  amount              FLOAT64,
  create_time         TIMESTAMP NOT NULL
) PRIMARY KEY (id, to_id, create_time),
  INTERLEAVE IN PARENT Account ON DELETE CASCADE;

CREATE TABLE AccountRepayLoan (
  id                  INT64 NOT NULL,
  loan_id             INT64 NOT NULL,
  amount              FLOAT64,
  create_time         TIMESTAMP NOT NULL
) PRIMARY KEY (id, loan_id, create_time),
  INTERLEAVE IN PARENT Account ON DELETE CASCADE;

CREATE TABLE PersonOwnAccount (
  id                  INT64 NOT NULL,
  account_id          INT64 NOT NULL,
  create_time         TIMESTAMP
) PRIMARY KEY (id, account_id),
  INTERLEAVE IN PARENT Person ON DELETE CASCADE;

CREATE TABLE AccountAudits (
  id                  INT64 NOT NULL,
  audit_timestamp     TIMESTAMP,
  audit_details       STRING(MAX)
) PRIMARY KEY (id, audit_timestamp),
  INTERLEAVE IN PARENT Account ON DELETE CASCADE;

CREATE PROPERTY GRAPH FinGraph
  NODE TABLES (
    Person,
    Account,
    Loan
  )
  EDGE TABLES (
    AccountTransferAccount
      SOURCE KEY (id) REFERENCES Account
      DESTINATION KEY (to_id) REFERENCES Account
      LABEL Transfers,
    AccountRepayLoan
      SOURCE KEY (id) REFERENCES Account
      DESTINATION KEY (loan_id) REFERENCES Loan
      LABEL Repays,
    PersonOwnAccount
      SOURCE KEY (id) REFERENCES Person
      DESTINATION KEY (account_id) REFERENCES Account
      LABEL Owns
  )
