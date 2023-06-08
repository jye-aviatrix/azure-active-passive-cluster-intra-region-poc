import hashlib
import logging

# Configure logging to send messages to both console and file
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.StreamHandler(),  # Sends logs to console
        logging.FileHandler("/var/log/bootstrap/logfile.log")  # Sends logs to file
    ]
)


# Get lastest version of the loader
import urllib.request
url = "${bootstrap_url}loader.py"
destination = "/etc/bootstrap/loader.tmp.py"
download_success = False

try:
    urllib.request.urlretrieve(url, destination)
    logging.info("File loader.tmp.py downloaded successfully.")
    download_success = True
except Exception as e:    
    logging.error("Failed to download loader.tmp.py file. Error: %s", str(e))

# Define functions to compare hashing

def compute_file_hash(file_path):
    """Compute the hash of a file."""
    hash_object = hashlib.sha256()

    with open(file_path, "rb") as file:
        chunk = file.read(4096)
        while len(chunk) > 0:
            hash_object.update(chunk)
            chunk = file.read(4096)

    return hash_object.hexdigest()

def compare_file_hashes(file1_path, file2_path):
    """Compare the hashes of two files."""
    hash1 = compute_file_hash(file1_path)
    hash2 = compute_file_hash(file2_path)

    if hash1 == hash2:
        return True
    else:
        return False


# Check if local loader and downloaded load is different
hash_compare_success = False
hash_is_different = False
try:
    if compare_file_hashes("/etc/bootstrap/loader.py", "/etc/bootstrap/loader.tmp.py"):           
        logging.info("File loader.py and loader.tmp.py is identical, no need to overwrite.")
        hash_compare_success = True
    else:
        logging.info("File loader.py and loader.tmp.py is different.")
        hash_compare_success = True
        hash_is_different = True        
except Exception as e:
    logging.error("Failed to compare hasing of loader.py and loader.temp.py file. Error: %s", str(e))


# Overwite loader.py with loader.tmp.py
import shutil

if download_success and hash_compare_success and hash_is_different:
    try:
        logging.info("Try to overwite loader.py with loader.tmp.py")
        shutil.copy2("/etc/bootstrap/loader.tmp.py", "/etc/bootstrap/loader.py")
        logging.info("loader.py successfully overwriten with loader.tmp.py")
    except Exception as e:
        logging.error("Failed to overwite loader.py with loader.tmp.py. Error: %s", str(e))



# Read Azure Instance Metadata Service for node information
# https://learn.microsoft.com/en-us/azure/virtual-machines/instance-metadata-service
# Ideally controller itself should track the cluster memember information, rather than depend on metadata as the format will be CSP dependant.
import requests
url = "http://169.254.169.254/metadata/instance?api-version=2021-02-01"
headers = {"Metadata": "true"}
try: 
    logging.info("Reading instance metadata service")
    response = requests.get(url, headers=headers)
except Exception as e:
    logging.error("Failed to read instance metadata service. Error: %s", str(e))
if response.status_code == 200:
    metadata = response.json()
    node_name = metadata['compute']['name']
    node_private_ip = metadata['network']['interface'][0]['ipv4']['ipAddress'][0]['privateIpAddress']
    node_public_ip = metadata['network']['interface'][0]['ipv4']['ipAddress'][0]['publicIpAddress']
    logging.info("Node name: %s", node_name)
    logging.info("Node private IP: %s", node_private_ip)
    logging.info("Node public IP: %s", node_public_ip)
else:
    logging.error("Failed to retrieve instance metadata. Status code:", response.status_code)


# Read nodes_info.json to get other cluster members' information
import json
from collections import OrderedDict

try:
    # Read the JSON file
    with open('/etc/bootstrap/nodes_info.json', 'r') as file:
        nodes_info_json_data = json.load(file)
    
    # Convert to ordered list
    ordered_nodes_info = list(OrderedDict(nodes_info_json_data).items())

    # Get the list of node names
    node_names = [node[0] for node in ordered_nodes_info]

    # Print the list of node names
    logging.info("List of nodes in cluster: %s", node_names)
except Exception as e:
    logging.error("Failed to read nodes_info.json. Error: %s", str(e))


# Connectivity test
def check_http(public_ip):
    url = f"http://{public_ip}"

    try:
        response = requests.get(url,timeout=10)
        if response.status_code == 200:
            logging.info("HTTP Connectivity is successful to %s", public_ip)
            return True
        else:
            logging.error("HTTP Connectivity to %s failed with status code: %s", public_ip, response.status_code)
            return False
    except requests.exceptions.RequestException as e:
        logging.error("An error occurred while connecting to %s, error: %s", public_ip, str(e))
        return False

total_nodes = len(node_names)
logging.info("There are total: %s nodes in the cluster", total_nodes)

majority_nodes = (total_nodes + 1) // 2
logging.info("Require minimum %s majority nodes to vote who's the active node", majority_nodes)


reachable_nodes_public_ips=[]
for remote_node_name, remote_node_info in ordered_nodes_info:
    remote_public_ip = remote_node_info['public_ip']
    if remote_public_ip == node_public_ip:
        logging.info("Node Name: %s with public IP: %s is local, skip", remote_node_name,remote_public_ip)

        reachable_nodes_public_ips.append(remote_public_ip)
    else:
        logging.info("Node Name: %s with public IP: %s is remote, perform connectivity test", remote_node_name,remote_public_ip)
        if check_http(remote_public_ip):            

            reachable_nodes_public_ips.append(remote_public_ip)

logging.info("All reachable nodes (including local node): %s", reachable_nodes_public_ips)

if len(reachable_nodes_public_ips) >= majority_nodes:
    logging.info("Total reachable nodes %s is more than or equal to majority nodes %s", len(reachable_nodes_public_ips),majority_nodes)
else:
    logging.info("Total reachable nodes %s is less than majority nodes %s", len(reachable_nodes_public_ips),majority_nodes)