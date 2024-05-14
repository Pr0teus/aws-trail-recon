# aws-trail-recon
AWS Trail Recon is an idea that came up during gohacking's offensive AWS security training. The idea is to use Cloudtrail:lookupevents to analyze what permissions the user of the leaked key has.

# How to collaborate:
1. Fork this project
2. Create an issue 
3. Code/Fix/Solve the issue in your repository.
4. Make a pull request to this Project.


# How to use -- Python version (fast)
1. Create a virtual environment
2. Install the requirements
3. Find any AWS Credential
4. If the credential has the CloudTrail:LookUpEvents action you will get the results.


# How to use -- Bash version (slow)
1. chmod +x trail-recon.sh
2. ./trail-recon.sh -k $AWS_ACCESS_KEY_ID -s $AWS_SECRET_ACCESS_KEY -t $AWS_SESSION_TOKEN -d 1
or
2. ./trail-recon.sh -p teste -d 1s

