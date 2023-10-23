# Realtime data warehousing with Snowflake
A simple illustration of implementing data streaming and analytics using snowflake. 
I've created this repository as I haven't found enough resources online, implementing the workflow using Snowflake's new UI, Snowsight.
* * *
### What's Snowflake?
In simple terms, snowflake is a cloud solution to data warehousing, which provides compute resources to run SQL commands on databases and query storage solutions.
### Why Snowflake over other Warehouses:
* Option to choose the cloud provider, instead of tightly binding to one of them (AWS/GCP/Azure)
* Provides an efficient serverless architecture
* Queries are stored in the cache for 24hrs saving compute time and resources 
* Time-travel feature to revert back to query IDs (starts 24hrs for standard account  upto 90 days with Enterprise version)
* Decouples Compute and Storage and uses columnar compression and other techniques to save costs. 
* Scales efficiently unlike other solutions like Redshift, which scales by compute nodes, charging per hour. 
* Doesn't charge for data ingress and metadata storage.
* Provides in-house visualization tools to understand the results while querying.

### Steps to follow while working with Snowflake:
* #### Preprocess the data:
   Standard Data Extraction and Cleansing should be performed for building efficient results. 
   Link to the [Data Preparation Considerations](https://docs.snowflake.com/en/user-guide/data-load-considerations-prepare) documentation to follow before proceeding to the next step.
* #### Stage the data:
    An intermediate space to upload the files either from local storage or cloud. Helps to successfully store the data and perform load operation when needed. 
* #### Load the data:
    The data is ingested into the database using the COPY command which the help of several file format attributes.
* #### Manage Regular Workload:
    Create a warehouse compute to query the results. Snowflake offers 3 serverless compute options depending upon the data load and can be scaled anytime. 
* * *
### Goal:
Load Tesla Sales Data from cloud storage and perform analytics using the queries generated on Snowflake's warehouse 

### Tech Stack:
* **AWS S3:** To store processed data
* **Snowflake:** Data warehouse
* **Snowpipe:** To automate data loading
* **AWS Quicksight:** For Data Analytics 
### Prerequisites:
* Basic knowledge on SQL
* AWS account and basic knowledge cloud concepts
### Implementation: 
#### 1. [Signup](https://signup.snowflake.com/) for a snowflake account. 
   Choose your cloud provider (AWS in this project).
   Here is a [quick youtube video](https://www.youtube.com/watch?v=9PBvVeCQi0w&t=236s) to understand Snowflake's features.
#### 2. Create a data wareshouse: 
   Create a simple data warehousing using:
   **Snowflake Web Interface:** Nativate to `Admin` -> `Warehouses`, and create a warehouse using default settings. 
   **SnowSQL**: 
   ```
    CREATE WAREHOUSE IF NOT EXISTS my_warehouse
    WAREHOUSE_SIZE = 'X-SMALL'
    WAREHOUSE_TYPE = 'STANDARD'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE;

    use warehouse my_warehouse;
   ```   
#### 3. Create a database to storage data:
   ```
    create database test_db;

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
   ```

#### 4. External Stage data from AWS S3:
Store the provided `TSLA.csv` in a S3 bucket.
* **Stage the files using the command replacing `AWS_KEY_ID` and `AWS_SECRET_KEY`:**
 ```
CREATE OR REPLACE STAGE BULK_COPY_TESLA_STAGE URL='s3://<bucketname>/TSLA.csv'
CREDENTIALS=(AWS_KEY_ID='awskeyid' AWS_SECRET_KEY='awssecretkey');
```
* **Staging using Integration:**
It is always recommended to create an IAM role with S3 policies and connect it with Snowflake using Storage Integrations using ARNs to hide sensitive AWS account information `(AWS_KEY_ID,AWS_SECRET_KEY)`
```
CREATE or replace STORAGE INTEGRATION S3_INTEGRATION
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = S3
STORAGE_AWS_ROLE_ARN = '<AWS-ROLE-ARN>'
ENABLED = TRUE
STORAGE_ALLOWED_LOCATIONS = ('s3://<bucketname>/');
 ```
Run the command `DESC INTEGRATION S3_INTEGRATION;` to find `STORAGE_AWS_IAM_USER_ARN` and add it to trusted relationships of your AWS Role. 
Now stage the data using the command:
```
CREATE or REPLACE STAGE TESLA_DATA_STAGE
URL='s3://<bucketname>/TSLA.csv'
STORAGE_INTEGRATION = S3_INTEGRATION
FILE_FORMAT = (TYPE = CSV FIELD_DELIMITER = ',' SKIP_HEADER = 1);
```
#### 5.  Loading the stages data to the database:
Now that the data is staged to `TESLA_DATA_STAGE`, use the below command to copy the command and query the data:
```
COPY INTO test_db
FROM @TESLA_DATA_STAGE
PATTERN='.*.csv'; 

select * from data
```
#### 6. Create a pipe to autoload the data at S3:
Add pipe command before the COPY command to create a pipe:
```
create or replace pipe tesla_pipe auto_ingest=true as 
COPY INTO test_db
FROM @TESLA_DATA_STAGE
PATTERN='.*.csv'; 

show pipes;
```
* Copy the `STORAGE_AWS_IAM_USER_ARN` from above to your bucket's event notification. You can do this using the AWS UI by navigating to 
`S3`->`<bucket_name>`->`Properties`->`Event Notification`->`SQS queue ARN under DESTINATIon section`. 
* Make sure to select the required event types while selection. 

#### 7. Export the Query results to  AWS Quicksight.
* Navigate to your AWS dashboard. Click on `new dataset`->`Snowflake`
* Enter your account URL in the `database server` section. 
  You can find it by clicking on account name present on bottom left on the Snowflake's Web Interface.
* Enter the database details on the remaining prompts and you should have the data ready for analytics on Quicksight. 

* * * 

**Other Insightful Information:**
* You use snowSQL from terminal without the hazzle of logging in everytime using the credentials, you can add account parameters to the config file inside .snowsql.
Change the `username` to `account identifier` found on the bottom right section of the snowflake Web Interface. You'll have to replace '.' with '-', to seperate the organization and account number. modify and enter the  `username` and `password` parameters as well. 
*  File format can be created seperately in SnowSQL to enchance modular code and decrease code duplication. It can be created as follow:
```
create or replace file format CSV_FORMAT 
--- Add parameters such as:
TYPE = CSV 
FIELD_DELIMITER = ',' 
SKIP_HEADER = 1;
```

