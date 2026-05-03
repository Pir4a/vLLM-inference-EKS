aws s3api create-bucket \ 
--bucket "$ACCOUNT_ID-tfstate-llm-inference-sre" \ 
--region us-east-1

aws s3api put-bucket-versioning \ 
--bucket "$ACCOUNT_ID-tfstate-llm-inference-sre" \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \ 
--bucket "$ACCOUNT_ID-tfstate-llm-inference-sre" \ 
--server-side-encryption-configuration '{                                                           
      "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
    }'

aws s3api put-public-access-block \ 
--bucket "$ACCOUNT_ID-tfstate-llm-inference-sre" \
  --public-access-block-configuration \ 
"BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
