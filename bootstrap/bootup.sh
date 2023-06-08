#!/bin/bash
# During each reboot, remove probe.html, this file should only be created by loader.py after evaulated connectivity with other nodes
rm /var/www/html/probe.html