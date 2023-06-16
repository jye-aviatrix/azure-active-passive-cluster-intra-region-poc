# azure-active-passive-cluster-intra-region-poc

Content of this repo shows proof of concept of three VM active/passive/passive cluster in three availability zone in a single region. Odd number of VM is required to be able to get majority quorum. This means out of three nodes, you need two health nodes to have one active node. If two nodes become unhealthy, the remaining node won't become active and will remain passive.

Each VM/node is bootstrapped to install Apache and have a default /index.html page. Network security group of each node opens incoming HTTP to internet. Each node has been assigned public IP.

A public load balancer is created, using these three nodes as backend, a HTTP probe has been created to check each node's /probe.html.

An ordered list (file name: nodes_info.json) of all nodes and their name /private IP/ public IP is also bootstrap to each node. 

A bootup.service is scheduled to run each time when the nodes boot up, it will delete /var/www/html/probe.html and <node>.html to make sure each node always start as passive node.

A loader.py is scheduled to run every 20 seconds on each nodes using timer service. Timer service is used to ensure that all nodes will be executing the script at the same time at 0, 20, 40 seconds of each minute, as long as their clock is in sync.

This python script does the following:

- Download loader.py from storage account static web to make sure it's always up to date
- Read Azure Instance Metadata service for node name and private IP
- Read Azure Load Balancer Metadata service for public IP assigned to each node
- Read nodes_info.json for each nodes information
    - Calculate total number of nodes
    - Calculate what number is required to get majority quorum 
    - From each node, perform connectivity test against rest of the nodes
        - The test is done using public IP, but very easy to change to use private IP
        - Public IP would be helpful for cross region or even cross CSP
        - When local node, eg node1, can see remote node eg: node3, it will create /var/www/html/node3.html to let node3 know that local can see node3. Otherwise, it will make sure node3.html doesn't exist.
        - Similarly, when node3 can reach node1, it will also create /var/www/html/node1.html to let node1 know that node3 can see it
        - This is to ensure there are bi-directional visibility, without bi-directional validation, following scenario could happen:
            - node1 would have a security group block node2 incoming connection, but node1 can still talk to node2 and node3, so it will think it's the active node
            - node2 cannot talk to node1, but it can see node3, so it also think itself is the active node
        - Only when confirmed both nodes can see each other, the remote node IP will be added to reachable nodes list
    - Local node will compose a new ordered list including itself, as well as all other reachable nodes
    - Local node will check, if the count of the new ordered list is greater than or equal to required majority quorum.
        - If no, than local node will delete /var/www/html/probe.html to make sure it self is a passive node
        - If yes
            - Local node will check if itself is the first element of the new ordered list
                - If yes, the local node will create /var/www/html/probe.html, which will make itself an Active node
                - If no, the local node will delete /var/www/html/probe.html to make sure it self is a passive node


## Testing
- All three nodes are up and reachable to each other
    - Node1 will become active, and rest two will become passive
    ![All three nodes are up](images/Active%20Passive%20Cluster%20-%20All%20three%20nodes%20reachable.png)

- Turn off node1, and leaving node2, and node 3
    - Node2 will become active and node3 stays as passive
    ![Node1 down](images/Active%20Passive%20Cluster%20-%20Node1%20down.png)

- Turn on node1, node2 and node3 continue running
    - Node1 will become active again, and rest two will become passive
    ![All three nodes are up](images/Active%20Passive%20Cluster%20-%20All%20three%20nodes%20reachable.png)

- Turn off node2, leave node1 and node3 running
    - Node1 still remain active, and node3 will remain passive
    ![Node2 down](images/Active%20Passive%20Cluster%20-%20Node2%20down.png)

- Turn off node 2 and node3, only node1 is running
    - Node1 loses quorum and will become passive
    ![Both Node2 and Node3 down](images/Active%20Passive%20Cluster%20-%20Both%20Node2%20and%20Node3%20down.png)

- Turn on node2, leave node3 down and node1 running
    - Node1 become active, and node2 will become passive
    ![Node3 down](images/Active%20Passive%20Cluster%20-%20Node3%20down.png)


## Logging and troubleshooting
- From a test machine, you may use a loop to curl probe.html of each nodes to get http status
    ```
    while true; do
        curl -i http://<node_public_ip>/probe.html | grep HTTP/1.1
        sleep 5
    done
    ```
- loader.py stores log in: /var/log/bootstrap/logfile.log
    
    Example of active node

    ```
    ubuntu@node1:~$ tail -f /var/log/bootstrap/logfile.log
    2023-06-16 20:17:40,261 - INFO - File loader.tmp.py downloaded successfully.
    2023-06-16 20:17:40,262 - INFO - File loader.py and loader.tmp.py is identical, no need to overwrite.
    2023-06-16 20:17:40,361 - INFO - Reading instance metadata service
    2023-06-16 20:17:40,379 - INFO - Local node name: node1
    2023-06-16 20:17:40,380 - INFO - Local node private IP: 10.0.0.4
    2023-06-16 20:17:40,380 - INFO - Reading load balancer metadata service
    2023-06-16 20:17:40,392 - INFO - Local node public IP: 52.170.214.132
    2023-06-16 20:17:40,394 - INFO - List of nodes in cluster: ['node1', 'node2', 'node3']
    2023-06-16 20:17:40,394 - INFO - There are total: 3 nodes in the cluster
    2023-06-16 20:17:40,395 - INFO - Require minimum 2 majority nodes to vote who's the active node
    2023-06-16 20:17:40,395 - INFO - Node Name: node1 with public IP: 52.170.214.132 is local, skip
    2023-06-16 20:17:40,396 - INFO - Node Name: node2 with public IP: 52.170.214.141 is remote, perform connectivity test
    2023-06-16 20:17:40,402 - INFO - HTTP Connectivity is successful to 52.170.214.141
    2023-06-16 20:17:40,403 - INFO - Able to reach node2, creating /var/www/html/node2.html to let remote know connection from local to remote works
    2023-06-16 20:17:40,404 - INFO - Now check if remote can see local by lookup node2.html on node1
    2023-06-16 20:17:40,410 - INFO - Confirmed 52.170.214.141 can see node1
    2023-06-16 20:17:40,410 - INFO - Both node1 and node2 can see each other, add remote public IP to reachable list
    2023-06-16 20:17:40,411 - INFO - Node Name: node3 with public IP: 40.121.66.148 is remote, perform connectivity test
    2023-06-16 20:17:40,415 - INFO - HTTP Connectivity is successful to 40.121.66.148
    2023-06-16 20:17:40,415 - INFO - Able to reach node3, creating /var/www/html/node3.html to let remote know connection from local to remote works
    2023-06-16 20:17:40,416 - INFO - Now check if remote can see local by lookup node3.html on node1
    2023-06-16 20:17:40,421 - INFO - Confirmed 40.121.66.148 can see node1
    2023-06-16 20:17:40,422 - INFO - Both node1 and node3 can see each other, add remote public IP to reachable list
    2023-06-16 20:17:40,422 - INFO - All reachable nodes (including local node): ['52.170.214.132', '52.170.214.141', '40.121.66.148']
    2023-06-16 20:17:40,423 - INFO - Total reachable nodes 3 is more than or equal to majority nodes 2
    2023-06-16 20:17:40,423 - INFO - Filtered reachable ordered nodes [('node1', {'ip_configuration_name': 'default', 'network_interface_id': '/subscriptions/7a7e6878-73b9-4432-9e54-6cf31c0aa6f5/resourceGroups/active-passive-cluster/providers/Microsoft.Network/networkInterfaces/node1-nic', 'private_ip': '10.0.0.4', 'public_ip': '52.170.214.132'}), ('node2', {'ip_configuration_name': 'default', 'network_interface_id': '/subscriptions/7a7e6878-73b9-4432-9e54-6cf31c0aa6f5/resourceGroups/active-passive-cluster/providers/Microsoft.Network/networkInterfaces/node2-nic', 'private_ip': '10.0.0.5', 'public_ip': '52.170.214.141'}), ('node3', {'ip_configuration_name': 'default', 'network_interface_id': '/subscriptions/7a7e6878-73b9-4432-9e54-6cf31c0aa6f5/resourceGroups/active-passive-cluster/providers/Microsoft.Network/networkInterfaces/node3-nic', 'private_ip': '10.0.0.6', 'public_ip': '40.121.66.148'})]
    2023-06-16 20:17:40,423 - INFO - Node node1 reachability reach quorum and is preferred, set as active
    ```

    Example of passive node

    ```
    ubuntu@node2:~$ tail -f /var/log/bootstrap/logfile.log
    2023-06-16 20:17:41,037 - INFO - File loader.tmp.py downloaded successfully.
    2023-06-16 20:17:41,038 - INFO - File loader.py and loader.tmp.py is identical, no need to overwrite.
    2023-06-16 20:17:41,128 - INFO - Reading instance metadata service
    2023-06-16 20:17:41,144 - INFO - Local node name: node2
    2023-06-16 20:17:41,145 - INFO - Local node private IP: 10.0.0.5
    2023-06-16 20:17:41,145 - INFO - Reading load balancer metadata service
    2023-06-16 20:17:41,153 - INFO - Local node public IP: 52.170.214.141
    2023-06-16 20:17:41,155 - INFO - List of nodes in cluster: ['node1', 'node2', 'node3']
    2023-06-16 20:17:41,156 - INFO - There are total: 3 nodes in the cluster
    2023-06-16 20:17:41,156 - INFO - Require minimum 2 majority nodes to vote who's the active node
    2023-06-16 20:17:41,156 - INFO - Node Name: node1 with public IP: 52.170.214.132 is remote, perform connectivity test
    2023-06-16 20:17:41,162 - INFO - HTTP Connectivity is successful to 52.170.214.132
    2023-06-16 20:17:41,163 - INFO - Able to reach node1, creating /var/www/html/node1.html to let remote know connection from local to remote works
    2023-06-16 20:17:41,163 - INFO - Now check if remote can see local by lookup node1.html on node2
    2023-06-16 20:17:41,168 - INFO - Confirmed 52.170.214.132 can see node2
    2023-06-16 20:17:41,169 - INFO - Both node2 and node1 can see each other, add remote public IP to reachable list
    2023-06-16 20:17:41,169 - INFO - Node Name: node2 with public IP: 52.170.214.141 is local, skip
    2023-06-16 20:17:41,170 - INFO - Node Name: node3 with public IP: 40.121.66.148 is remote, perform connectivity test
    2023-06-16 20:17:41,175 - INFO - HTTP Connectivity is successful to 40.121.66.148
    2023-06-16 20:17:41,176 - INFO - Able to reach node3, creating /var/www/html/node3.html to let remote know connection from local to remote works
    2023-06-16 20:17:41,176 - INFO - Now check if remote can see local by lookup node3.html on node2
    2023-06-16 20:17:41,181 - INFO - Confirmed 40.121.66.148 can see node2
    2023-06-16 20:17:41,182 - INFO - Both node2 and node3 can see each other, add remote public IP to reachable list
    2023-06-16 20:17:41,182 - INFO - All reachable nodes (including local node): ['52.170.214.132', '52.170.214.141', '40.121.66.148']
    2023-06-16 20:17:41,182 - INFO - Total reachable nodes 3 is more than or equal to majority nodes 2
    2023-06-16 20:17:41,183 - INFO - Filtered reachable ordered nodes [('node1', {'ip_configuration_name': 'default', 'network_interface_id': '/subscriptions/7a7e6878-73b9-4432-9e54-6cf31c0aa6f5/resourceGroups/active-passive-cluster/providers/Microsoft.Network/networkInterfaces/node1-nic', 'private_ip': '10.0.0.4', 'public_ip': '52.170.214.132'}), ('node2', {'ip_configuration_name': 'default', 'network_interface_id': '/subscriptions/7a7e6878-73b9-4432-9e54-6cf31c0aa6f5/resourceGroups/active-passive-cluster/providers/Microsoft.Network/networkInterfaces/node2-nic', 'private_ip': '10.0.0.5', 'public_ip': '52.170.214.141'}), ('node3', {'ip_configuration_name': 'default', 'network_interface_id': '/subscriptions/7a7e6878-73b9-4432-9e54-6cf31c0aa6f5/resourceGroups/active-passive-cluster/providers/Microsoft.Network/networkInterfaces/node3-nic', 'private_ip': '10.0.0.6', 'public_ip': '40.121.66.148'})]
    2023-06-16 20:17:41,183 - INFO - Node node2 reachability reach quorum but not preferred, set as passive
    2023-06-16 20:17:41,184 - INFO - probe.html already does not exist
    ```

- To run the loader.py locally to debug
    ```
    sudo python3

    exec(open('/etc/bootstrap/loader.py').read())
    ```
## Room for improvement
- We are using a static ordered list where it always goes ['node1','node2','node3'], node3 is always at the bottom of the list so even when reaches quorum, it will never become active. If a new ordered list, such as ['node3','node1','node2'] is required, an mechanism of updating the list order on the active node, make sure it gets properly synced to the remaining nodes, before the new order take effect will be necessary.
- On the flip side, since the last node in the ordered list will never become active, we can use a very small instance size for the last node, and doesn't need to run any services.