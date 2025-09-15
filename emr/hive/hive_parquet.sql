SET parquet.compression='GZIP';
DROP TABLE IF EXISTS ny_taxi_test_s3;

CREATE EXTERNAL TABLE ny_taxi_test_s3(
  vendor_id int,
  lpep_pickup_datetime timestamp,
  lpep_dropoff_datetime timestamp,
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
STORED AS PARQUET
LOCATION "${INPUT}";

INSERT OVERWRITE DIRECTORY "${OUTPUT}"
STORED AS PARQUET
SELECT * FROM ny_taxi_test_s3 WHERE rate_code_id = 1;
