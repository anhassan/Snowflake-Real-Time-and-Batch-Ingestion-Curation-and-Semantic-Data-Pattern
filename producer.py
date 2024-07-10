from faker import Faker
import json
import boto3
import uuid
import time

# Utility function to generate a batch of defined number of records
def generate_batch(batch_size,fake):
    records = []
    for index in range(batch_size):
        records += [json.dumps({
                "name":    fake.name(),
                "url":     fake.url(),
                "email":   fake.email(),
                "country": fake.country()
            })]
    
    records_str = "\n".join(records)
    return records_str
    

# Utility function to write a batch of users to defined s3 folder location
def write_batch_to_s3(s3_client,s3_bucket,s3_folder_loc,data):
    
    file_id = uuid.uuid4()
    s3_file_loc = f"{s3_folder_loc}/user-{file_id}.json"
    s3_client.put_object(
        Body = data,
        Bucket = s3_bucket,
        Key = s3_file_loc
        )
        

# Defining the main function call 
if __name__ == '__main__':
    
    
    # Deciding the number of records to be sent as a batch
    BATCH_SIZE = 100
    # Defining the name of the S3 bucket
    S3_BUCKET_NAME = "aws-snowflake-external-stage-ejqdwxm"
    # Defining the name of the S3 folder name
    S3_FOLDER_LOC = "input"
    
    # Instantiating the required objects
    fake_client = Faker()
    s3_client = boto3.client('s3')
    
    
    # Dispatching batchs of records to S3 bucket location
    while True:
        batch_data = generate_batch(BATCH_SIZE,fake_client)
        write_batch_to_s3(s3_client,S3_BUCKET_NAME,S3_FOLDER_LOC,batch_data)
        time.sleep(80)
        

