import sys
import argparse
from datetime import datetime
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.functions import to_date, col

parser = argparse.ArgumentParser()
parser.add_argument("--input")
parser.add_argument("--output")
args = parser.parse_args()

with SparkSession.builder.appName("Example").getOrCreate() as spark:
  df = (spark.read.format('csv')
    .option('header', 'True')
    .option("inferSchema", "true")
    .load(args.input))

  df_final = df.filter(df['total_amount'] > 15)
  df_final.write.partitionBy("RatecodeID").parquet(args.output)
