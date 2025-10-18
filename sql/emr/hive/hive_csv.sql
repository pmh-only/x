DROP TABLE IF EXISTS ny_taxi_test_s3;
DROP TABLE IF EXISTS ny_taxi_test_hdfs;

CREATE EXTERNAL TABLE ny_taxi_test_s3 (
  vendor_id int,
  lpep_pickup_datetime string,
  lpep_dropoff_datetime string,
  store_and_fwd_flag string,
  rate_code_id smallint,
  pu_location_id int,
  do_location_id int,
  passenger_count int,
  trip_distance double,
  fare_amount double,
  mta_tax double,
  tip_amount double,
  tolls_amount double,
  ehail_fee double,
  improvement_surcharge double,
  total_amount double,
  payment_type smallint,
  trip_type smallint
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
STORED AS TEXTFILE
LOCATION "${INPUT}"
TBLPROPERTIES ("skip.header.line.count"="1");
       
CREATE TABLE ny_taxi_test_hdfs
STORED AS PARQUET
AS
SELECT 
  vendor_id,
  CAST(lpep_pickup_datetime AS DATE),
  CAST(lpep_dropoff_datetime AS DATE),
  store_and_fwd_flag,
  rate_code_id,
  pu_location_id,
  do_location_id,
  passenger_count,
  trip_distance,
  fare_amount,
  mta_tax,
  tip_amount,
  tolls_amount,
  ehail_fee,
  improvement_surcharge,
  total_amount,
  payment_type,
  trip_type
FROM ny_taxi_test_s3;

INSERT OVERWRITE DIRECTORY "${OUTPUT}"
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
SELECT * FROM ny_taxi_test_hdfs WHERE rate_code_id = 1;
