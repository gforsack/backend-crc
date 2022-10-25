import json
import boto3
import logging
from custom_encoder import CustomerEncoder

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodbTableName = 'visitorCountDB'
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(dynamodbTableName)

get = 'GET'
default_path = '/count'

def lambda_handler(event, context):
    logger.info(event)
    httpMethod = event['httpMethod']
    path = event['path']

    if httpMethod == get and path == '/health':
        response = apiResponse(200)
    elif httpMethod == get and path == default_path:
        response = updateCount(event['queryStringParameters']['site'])
    else:
        response = apiResponse(404, 'Not Found')

    return response


def updateCount(site):
    try:
        response = table.update_item(
            Key={
                'site': site
            },
            UpdateExpression='SET visitor_count = visitor_count + :value',
            ExpressionAttributeValues={
                ':value': 1
            },
            ReturnValues='UPDATED_NEW'
        )
        return apiResponse(200, response['Attributes'])
    except:
        logger.exception('Update operation failed')


def apiResponse(statusCode, body=None):
    response = {
        'statusCode': statusCode,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        }
    }

    if body is not None:
        response['body'] = json.dumps(body, cls=CustomerEncoder)
    return response

