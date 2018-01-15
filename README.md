# cassandra
oc new-project cassandra
oc new-build https://github.com/shrishs/cassandra.git --context-dir=image --name=cassandraprod  --strategy=docker
oc start-build cassandraprod --wait --follow

[ec2-user@master1 cassandra]$ oc get is
NAME            DOCKER REPO                                                TAGS      UPDATED
cassandra       docker-registry.default.svc:5000/cassandra/cassandra       3.0.15    9 minutes ago
cassandraprod   docker-registry.default.svc:5000/cassandra/cassandraprod   latest    2 minutes ago



oc label node node1.internal region=cassandra
oc label node node2.internal region=cassandra
oc label node node3.internal region=cassandra


oc create -f cassandra-service.yaml
oc create -f cassandra-statefulset-nostorage.yaml


[ec2-user@master1 cassandra]$ oc exec cassandra-0 -- nodetool status
Datacenter: datacenter1
=======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address   Load       Tokens       Owns (effective)  Host ID                               Rack
UN  10.1.2.7  102.5 KB   256          65.1%             d891e1d0-0b9e-4122-96d9-cc4522a164ec  rack1
UN  10.1.4.6  102.42 KB  256          70.0%             908f2c51-603d-4ebd-aee7-285f24c7deca  rack1
UN  10.1.2.6  108.03 KB  256          64.9%             6eb66c67-a8f2-4731-994f-ee03cc7f5b8d  rack1

