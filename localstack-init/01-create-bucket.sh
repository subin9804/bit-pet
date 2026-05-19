#!/bin/bash
# LocalStack 기동 시 자동 실행 — bitpet-dev 버킷 생성
awslocal s3 mb s3://bitpet-dev --region ap-northeast-2
awslocal s3api put-bucket-cors --bucket bitpet-dev --cors-configuration '{
  "CORSRules": [{
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["GET", "PUT", "HEAD"],
    "AllowedOrigins": ["*"],
    "MaxAgeSeconds": 3000
  }]
}'
echo "bucket bitpet-dev created"
