#!/bin/bash
PROFILE="default"  # Optional profile name for AWS configuration
AWS_ACCESS_KEY_ID=""  # Replace with your access key ID
AWS_SECRET_ACCESS_KEY=""  # Replace with your secret access key
AWS_SESSION_TOKEN=""  # Replace with your session token (if any)

# Get parameters from command line arguments (optional)
while getopts ":hp:k:s:t:d:" opt; do
  case $opt in
    h) 
      echo "Usage:  usage $0 -k AWS_ACCESS_KEY_ID -s AWS_SECRET_ACCESS_KEY -t AWS_SESSION_TOKEN -d # of days"
      exit 0
      ;;
    p) PROFILE="$OPTARG" ;;
    k) AWS_ACCESS_KEY_ID="$OPTARG" ;;
    s) AWS_SECRET_ACCESS_KEY="$OPTARG" ;;
    t) AWS_SESSION_TOKEN="$OPTARG" ;;
    d) DAYS="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG"
    >&2; exit 1 ;;
  esac
done

if [[ ! -z "$AWS_ACCESS_KEY_ID" && ! -z "$AWS_SECRET_ACCESS_KEY" ]]; then
  export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
  export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
  if [[ ! -z "$AWS_SESSION_TOKEN" ]]; then
    export AWS_SESSION_TOKEN="$AWS_SESSION_TOKEN"
  fi
elif [[ -z "$PROFILE" ]]; then
  echo "Error: Either provide AWS credentials as arguments or set a default profile name (PROFILE)."
  exit 1
fi

if ! [[ $DAYS =~ ^[0-9]+$ ]]; then
echo   $DAYS
  echo $days_ago
  echo "Invalid argument: -days must be a positive integer."
fi

# Check operating system using `uname`
if [[ $(uname -s) == "Darwin" ]]; then
  # macOS detected, use `date -j -v`
  start_time=$(date -j -v "-${DAYS}d" +"%Y-%m-%dT%H:%M:%SZ")
  end_time=$(date -j +"%Y-%m-%dT%H:%M:%SZ")
else
  # Linux detected, use `date -d`
  start_time=$(date -d "-${DAYS} days" +"%Y-%m-%dT%H:%M:%SZ")
  end_time=$(date +"%Y-%m-%dT%H:%M:%SZ")
fi

# Get all regions
regions=$(aws ec2 describe-regions --all-regions --query "Regions[].{Name:RegionName}" --output text)


for region in $regions; do
  echo "Região: $region"
  # Lookup CloudTrail events for the specified number of days ago
  events=$(aws cloudtrail lookup-events \
    --start-time $start_time \
    --end-time $end_time \
    --region "$region" \
    --output json | jq -r '.Events[] | "\(.Username): \(.EventName)"')

  # Print the retrieved events (if any)
  if [[ ! -z "$events" ]]; then
    echo "  Events:"
    echo "  $events"
  else
    echo "  No events found in region $region."
  fi

  echo ""  # Add an empty line between regions
done

echo "CloudTrail event lookup completed for the past $days_ago days."