import os
import argparse
import time
import json
import requests, zipfile, io




parser = argparse.ArgumentParser()


parser.add_argument(
    '--metadata',
    type=str,
    default="/home/input/deployment-metadata.json",
    help="""\
    The Metadata from Edge Impulse project
    """)
parser.add_argument(
    "--out_directory",
    type=str,
    required=False,
    help="""\
    Output directory.
    """,
)


args, unparsed = parser.parse_known_args()

if not os.path.exists(args.out_directory):
    os.makedirs(args.out_directory)

# Retrieve deployment metadata
with open(args.metadata, 'r') as f:
    deployment_metadata_json = json.loads(f.read())

# Start ndp120 library build
url = f"https://studio.edgeimpulse.com/v1/api/{deployment_metadata_json['project']['id']}/jobs/build-ondevice-model?type=syntiant-ndp120-lib"

payload = {
    # engine should be syntiant but this fails for some reason, so falling back to tflite-eon
    "engine": "tflite-eon",
    "modelType": deployment_metadata_json['tfliteModels'][0]['details']['modelType']
}
headers = {
    "accept": "application/json",
    "content-type": "application/json",
    "x-api-key": deployment_metadata_json['project']['apiKey']
}

response = requests.post(url, json=payload, headers=headers)

ndp120_job = response.json()


# Monitor job status until complete
job_log_counter = 0
while True:
    url = f"https://studio.edgeimpulse.com/v1/api/{deployment_metadata_json['project']['id']}/jobs/{ndp120_job['id']}/status"

    headers = {
        "accept": "application/json",
        "x-api-key": deployment_metadata_json['project']['apiKey']
    }

    response = requests.get(url, headers=headers)
    job_status = response.json()
    if job_status['job'].get('finishedSuccessful'):
        break
    else:
        # Print job logs
        url = f"https://studio.edgeimpulse.com/v1/api/{deployment_metadata_json['project']['id']}/jobs/{ndp120_job['id']}/stdout?limit=1"

        headers = {
            "accept": "application/json",
            "x-api-key": deployment_metadata_json['project']['apiKey']
        }

        response = requests.get(url, headers=headers)

        job_log = response.json()
        if job_log["totalCount"] > job_log_counter:
            job_log_counter = job_log["totalCount"]
            print(f"{job_log['stdout'][0]['created']}: {job_log['stdout'][0]['data']}")
        time.sleep(0.1)



# Download the posterior parameters
url = f"https://studio.edgeimpulse.com/v1/api/{deployment_metadata_json['project']['id']}/deployment/syntiant/posterior"

headers = {
    "accept": "application/json",
    "x-api-key": deployment_metadata_json['project']['apiKey']
}

response = requests.get(url, headers=headers)

if response.status_code != 200:
    raise Exception("Posterior Parameters not generated for this project, please generate them for the NDP120 official library")
with open(f'{args.out_directory}/ph_params.json', 'wb') as outf:
    outf.write(response.content)

url = f"https://studio.edgeimpulse.com/v1/api/{deployment_metadata_json['project']['id']}/deployment/download?type=syntiant-ndp120-lib&modelType={deployment_metadata_json['tfliteModels'][0]['details']['modelType']}&engine=syntiant"

headers = {
    "accept": "application/zip",
    "x-api-key": deployment_metadata_json['project']['apiKey']
}
r = requests.get(url, headers=headers)
z = zipfile.ZipFile(io.BytesIO(r.content))
z.extractall(args.out_directory)

print(f"NDP120 library downloaded to {args.out_directory}")