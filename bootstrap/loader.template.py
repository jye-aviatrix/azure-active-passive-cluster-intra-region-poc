# Get lastest version of the loader
import urllib.request
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

url = "${bootstrap_url}loader.py"
destination = "/etc/bootstrap/loader.py"

try:
    urllib.request.urlretrieve(url, destination)
    logging.info("File downloaded successfully.")
except Exception as e:
    logging.error("Failed to download file. Error: %s", str(e))


# Log some messages
logging.debug("This is a debug message.")
logging.info("This is an info message.")
logging.warning("This is a warning message.")
logging.error("This is an error message.")