import json, boto3

def lambda_handler(event, context):
    # TODO implement
    # ec2 = boto3.client('ec2')
    # results = [i['Instances'][0]['InstanceId'] for i in ec2.describe_instances()['Reservations']]
    
    return {
        'statusCode': 200,
        'body': json.dumps("Ohhh That's a Bingo!")
    }
