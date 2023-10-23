--Create Tesla_Data table
CREATE DATABASE TEST_DB;

Use test_db;

CREATE TABLE TESLA_DATA (
  Date date,
  Open_value double,
  High_value double,
  Low_value double,
  Close_value  double,
  Adj_Close double,
  volume bigint
  );
  
select * from TESLA_DATA;

--Create External S3 Stage
CREATE OR REPLACE STAGE BULK_COPY_TESLA_STAGE URL='s3://<bucket_name>/TSLA.csv'
CREDENTIALS=(AWS_KEY_ID='AWS_KEY_ID' AWS_SECRET_KEY='qE45j8k0G1+AWS_SECRET_KEY');
  
--List content of stage

LIST @BULK_COPY_TESLA_STAGE;

--Copy data from stage into table
  
COPY INTO TESLA_DATA
FROM @BULK_COPY_TESLA_STAGE
FILE_FORMAT = (TYPE = CSV FIELD_DELIMITER = ',' SKIP_HEADER = 1);
  
--Read data from table  
SELECT * FROM TESLA_DATA;  


--Grant Prev to another role apart from Account Admin
use role accountadmin;

GRANT CREATE INTEGRATION on account to role sysadmin;

use role sysadmin;
--Create Storage Integration
drop storage integration S3_INTEGRATION;

CREATE or replace STORAGE INTEGRATION S3_INTEGRATION
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = S3
  STORAGE_AWS_ROLE_ARN = 'STORAGE_AWS_ROLE_ARN'
  ENABLED = TRUE
  STORAGE_ALLOWED_LOCATIONS = ('s3://<bucket_name>/');
  
--Describe Integration to fetch ARN and External ID

DESC INTEGRATION S3_INTEGRATION;

--Create a Stage with Storage INTEGRATION
create or replace file format CSV_FORMAT 
TYPE = CSV 
FIELD_DELIMITER = ',' 
SKIP_HEADER = 1;

drop stage tesla_data_stage; 

CREATE or REPLACE STAGE TESLA_DATA_STAGE
  URL='s3://<bucket_name>/TSLA.csv'
  STORAGE_INTEGRATION = S3_INTEGRATION
  FILE_FORMAT = (TYPE = CSV FIELD_DELIMITER = ',' SKIP_HEADER = 1);

list  @TESLA_DATA_STAGE;

desc stage TESLA_DATA_STAGE;
--Load data into the table from Stage
COPY INTO TESLA_DATA
  FROM @TESLA_DATA_STAGE
  PATTERN='.*.csv'; 


create or replace pipe tesla_pipe auto_ingest=true as 
<Copy Command>
show pipes;
--Copy the ARN to Event_notificaition SQS ARN


  
  

  