#!/bin/bash
# During each reboot, remove probe.php, this file should only be created by loader.py after evaulated connectivity with other nodes
rm /var/www/html/probe.php