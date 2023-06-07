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
        logging.info("File loader.py and loader.tmp.py is identical")
        hash_compare_success = True
    else:
        logging.info("File loader.py and loader.tmp.py is different")
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
    except Exception as e:
        logging.error("Failed to overwite loader.py with loader.tmp.py. Error: %s", str(e))