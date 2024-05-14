import boto3
from botocore.exceptions import ClientError

import os
import threading
import datetime
from queue import Queue


class CloudTrailLookupThread(threading.Thread):
    def __init__(self, region, start_time, end_time, queue):
        super().__init__()
        self.region = region
        self.start_time = start_time
        self.end_time = end_time
        self.queue = queue
        self.events = []

    def run(self):
        cloudtrail = boto3.client('cloudtrail', region_name=self.region)
        paginator = cloudtrail.get_paginator('lookup_events')
        page_iterator = paginator.paginate(LookupAttributes=[], StartTime=self.start_time, EndTime=self.end_time)
        try:
            for page in page_iterator:
                for event in page['Events']:
                    self.events.append(event)
        except ClientError as e:
            print(f"Error in region {self.region}: {e}")
        self.queue.put((self.region, self.events))


def main():
    # Replace with your credentials (or use environment variables)
    profile_name = "default"
    access_key_id = os.getenv("AWS_ACCESS_KEY_ID")
    secret_access_key = os.getenv("AWS_SECRET_ACCESS_KEY")
    session_token = os.getenv("AWS_SESSION_TOKEN")

    import argparse
    parser = argparse.ArgumentParser(description="CloudTrail event lookup")
    parser.add_argument("-p", "--profile", help="AWS profile name (default: default)")
    parser.add_argument("-k", "--access_key_id", help="AWS access key ID")
    parser.add_argument("-s", "--secret_access_key", help="AWS secret access key")
    parser.add_argument("-t", "--session_token", help="AWS session token")
    parser.add_argument("-d", "--days", type=int, help="Number of days ago (default: 30)")
    args = parser.parse_args()

    profile_name = args.profile or profile_name
    access_key_id = args.access_key_id or access_key_id
    secret_access_key = args.secret_access_key or secret_access_key
    session_token = args.session_token or session_token
    days = args.days or 30

    # Set credentials (use session if all credentials provided)
    session = boto3.Session(
        profile_name=profile_name,
        aws_access_key_id=access_key_id,
        aws_secret_access_key=secret_access_key,
        aws_session_token=session_token
    )
    client = session.client('ec2')

    # Get all regions
    regions = [region['RegionName'] for region in client.describe_regions(AllRegions=True)['Regions']]

    # Calculate start and end time
    start_time = (datetime.datetime.utcnow() - datetime.timedelta(days=days)).isoformat() + 'Z'
    end_time = datetime.datetime.utcnow().isoformat() + 'Z'

    # Create a queue to store results
    results_queue = Queue()

    # Create threads for each region
    threads = []
    for region in regions:
        thread = CloudTrailLookupThread(region, start_time, end_time, results_queue)
        thread.start()
        threads.append(thread)

    # Wait for all threads to finish
    for thread in threads:
        thread.join()
    # Process results
    while not results_queue.empty():
        region, events = results_queue.get()
        print(f"Região: {region}")
        if events:
            print("  Events:")
            for event in events:
                if 'Username' in event:
                    print(f"    {event['Username']}: {event['EventName']}")
        else:
            print("  No events found in region.")
    print(f"CloudTrail event lookup completed for the past {days} days.")


if __name__ == "__main__":
    main()