# bootup.py is part of Aviatrix Controller Active / Passive Cluster scripts
# This python script is scheduled to run during start up
# This python script will read /etc/bootstrap/nodes_info.json and get all nodes' name, assuming node_names=['node1','node2','node3']
# This python script will delete probe.html, node1.html, node2.html and node3.html under /var/www/html
# This will make sure the node is always start up as passive node


# Setup logging environment
import logging
from logging.handlers import TimedRotatingFileHandler
import datetime


# Create a filename with the current date
current_date = datetime.datetime.now().strftime("%Y-%m-%d")
log_filename = f"/var/log/bootstrap/bootup_{current_date}.log"

# Configure logging to send messages to both console and log file, and keep only last 30 copies
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.StreamHandler(),  # Sends logs to console
        TimedRotatingFileHandler(log_filename, when="D", backupCount=30)  # Sends logs to a rotating file
    ]
)


# Read from nodes_info.json to obtain cluster node names
import json
from collections import OrderedDict
import os

script_name = os.path.basename(__file__)  # Obtain current python script file name

node_names_read_success=False
try:
    # Read the JSON file
    with open('/etc/bootstrap/nodes_info.json', 'r') as file:
        nodes_info_json_data = json.load(file)
    
    # Convert to ordered list
    ordered_nodes_info = list(OrderedDict(nodes_info_json_data).items())

    # Get the list of node names
    node_names = [node[0] for node in ordered_nodes_info]

    # Print the list of node names
    logging.info("%s Read list of nodes in cluster: %s", script_name,node_names)
    node_names_read_success=True
except Exception as e:
    logging.error("%s failed to read nodes_info.json. Error: %s", script_name, str(e))


# Delete probe.html, node1.html, node2.html and node3.html under /var/www/html

if os.path.exists("/var/www/html/probe.html"):
    os.remove("/var/www/html/probe.html")
    logging.info("%s Deleted probe.html", script_name)
else:
    logging.info("%s probe.html does not exist", script_name)

html_directory = '/var/www/html/'
if node_names_read_success:
    for node_name in node_names:
        html_file_path = os.path.join(html_directory, f'{node_name}.html')
        
        if os.path.exists(html_file_path):
            os.remove(html_file_path)
            logging.info("%s Deleted %s", script_name,html_file_path)
        else:
            logging.error("%s %s does not exist", script_name,html_file_path)