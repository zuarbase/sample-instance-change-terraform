import json
import os
from datetime import datetime, timedelta
from dateutil import tz, parser
import boto3
import requests

"""
pending, running, stopping, stopped
instance_id=<instance-id>, time=<time>, region=<region>, state=<state>
"""

ACCESSKEY = os.environ['ACCESS_ID']
SECRETKEY = os.environ['ACCESS_KEY']
REGION = os.environ['REGION']
SLACK_HOOK = 'https://hooks.slack.com/services/T3HG8SDET/B0987FGhg5gH/dAPkjshdfkjJHGAy33CALdj0' # not a real hook link

def get_instance_name(fid):
    """When given an instance ID as str e.g. 'i-1234567', return the instance 'Name' from the name tag."""
    ec2 = boto3.resource('ec2', aws_access_key_id=ACCESSKEY, aws_secret_access_key=SECRETKEY, region_name=REGION)
    ec2instance = ec2.Instance(fid)
    instancename = ''
    for tags in ec2instance.tags:
        if tags["Key"] == 'Name':
            instancename = tags["Value"]
    return instancename

def message_to_dict(message):
    """convert message to dict"""
    message = message.replace("\"", "")
    mdict = {}
    for word in message.split(", "):
        key, value = word.split("=")
        mdict[key] = value
    return mdict

def handler(event, context):
    message = False
    try:
        message = event["Records"][0]["Sns"]["Message"]
    except Exception as e:
        print(e)
        exit()
    if "pending" not in message and "stopping" not in message:
        url = SLACK_HOOK
        mdict = message_to_dict(message)
        d = parser.parse(mdict["time"])
        d = d - timedelta(hours=5)
        human_time = d.strftime('%m/%d/%Y %H:%M:%S')
        instance_name = get_instance_name(mdict["instance_id"])
        message = f'*Instance State Change:* - {human_time} - on {mdict["region"]} Instance {mdict["instance_id"]} was changed to *{mdict["state"]}*.\nInstance Tag Name: *{instance_name}*'
        myobj = {'text': message}
        try:
            x = requests.post(url, json=myobj)
        except Exception as e:
            print(e)
            exit()
        return {
            'statusCode': 200,
            'body': json.dumps({'response':x.text}),
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
        }
    else:
        return {
            'statusCode': 200,
            'body': json.dumps({'response':'pass'}),
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
        }
