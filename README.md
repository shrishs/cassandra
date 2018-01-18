# cassandra
--Create a new Project

oc new-project cassandra

--Create a new Docker build  "https://hub.docker.com/_/cassandra" 
by changing the cassandara version accordinglay in Dockerfile (FROM docker.io/cassandra:3.11)

-oc new-build https://github.com/shrishs/cassandra.git --context-dir=image --name=cassandraprod  --strategy=docker

-oc start-build cassandraprod --wait --follow

--Once the docker build is completed ,make sure that new corresponding imagestream has been created.

oc get is

NAME            DOCKER REPO                                                TAGS      UPDATED

cassandra       docker-registry.default.svc:5000/cassandra/cassandra       3.0.15    9 minutes ago

cassandraprod   docker-registry.default.svc:5000/cassandra/cassandraprod   latest    2 minutes ago


--Label the node ,where cassandra pods are suppse to reside.

oc label node node1.internal region=cassandra

oc label node node2.internal region=cassandra

oc label node node3.internal region=cassandra


--Create the headless service

oc create -f cassandra-service.yaml

--If one does not have the storage class defined ,can use the following definition for creating statefulset

oc create -f cassandra-statefulset-nostorage.yaml

--In case of production load ,please use the following definition to create the stateful set. Storageclass with the name "fast"is prerequisite for it.

oc create -f cassandra-statefulset-withstorage.yaml

--Wait for all the pods to come up.They will come up one after one.

oc get pods -o wide -w |grep cassandra-

cassandra-0   1/1       Running   7          1h        10.1.4.26   node2.3577.internal

cassandra-1   1/1       Running   2         1h        10.1.2.34   node1.3577.internal

cassandra-2   1/1       Running   4         1h        10.1.4.27   node2.3577.internal

--oc get statefulset 

NAME        DESIRED   CURRENT   AGE

cassandra   3         3         2h


oc exec cassandra-0 -- nodetool status

Datacenter: DC1-K8Demo
======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving

--  Address    Load       Tokens       Owns (effective)  Host ID                               Racka

UN  10.1.2.34  197.88 KB  256          67.3%             e36cca58-1a0e-452f-9491-14e32e4e7cc4  Rack1-K8Demo

UN  10.1.4.27  197.69 KB  256          66.1%             d878fe73-9b35-4440-a354-ae744d828dcf  Rack1-K8Demo

UN  10.1.4.26  182.24 KB  256          66.6%             482cf226-8129-4444-97b1-68e27b5645bc  Rack1-K8Demo



---Increase/Decrease number of replica

oc edit statefulset cassandra

-increase the numer of replica to 4

oc get pods -o wide -w |grep cassandra-

cassandra-0   1/1       Running   7          2h        10.1.4.26   node2.3577.internal

cassandra-1   1/1       Running   2         2h        10.1.2.34   node1.3577.internal

cassandra-2   1/1       Running   4         2h        10.1.4.27   node2.3577.internal

cassandra-3   0/1       Running   0         1m        10.1.2.35   node1.3577.internal



oc get pvc

NAME                         STATUS    VOLUME      CAPACITY   ACCESSMODES   STORAGECLASS   AGE

cassandra-data-cassandra-0   Bound     mylocal-0   4Gi        RWO                          2h

cassandra-data-cassandra-1   Bound     mylocal-1   4Gi        RWO                          2h

cassandra-data-cassandra-2   Bound     mylocal-2   4Gi        RWO                          2h

cassandra-data-cassandra-3   Bound     mylocal-3   4Gi        RWO                          7m



 oc exec cassandra-0 -- nodetool status

Datacenter: DC1-K8Demo
======================

Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving

--  Address    Load       Tokens       Owns (effective)  Host ID                               Rack

UN  10.1.2.35  102.61 KB  256          49.5%             5db5a370-f962-4847-9a68-c4e5a760a1ff  Rack1-K8Demo

UN  10.1.2.34  246.62 KB  256          51.2%             e36cca58-1a0e-452f-9491-14e32e4e7cc4  Rack1-K8Demo

UN  10.1.4.27  241.48 KB  256          48.2%             d878fe73-9b35-4440-a354-ae744d828dcf  Rack1-K8Demo

UN  10.1.4.26  231.38 KB  256          51.1%             482cf226-8129-4444-97b1-68e27b5645bc  Rack1-K8Demo




-decrease  the numer of replica to 3

oc get pods -o wide -w |grep cassandra-

cassandra-0   1/1       Running   7          2h        10.1.4.26   node2.3577.internal

cassandra-1   1/1       Running   2         2h        10.1.2.34   node1.3577.internal

cassandra-2   1/1       Running   4         2h        10.1.4.27   node2.3577.internal



oc exec cassandra-0 -- nodetool status

Datacenter: DC1-K8Demo
======================

Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving

--  Address    Load       Tokens       Owns (effective)  Host ID                               Rack

UN  10.1.2.34  251.75 KB  256          67.3%             e36cca58-1a0e-452f-9491-14e32e4e7cc4  Rack1-K8Demo

UN  10.1.4.27  246.61 KB  256          66.1%             d878fe73-9b35-4440-a354-ae744d828dcf  Rack1-K8Demo

UN  10.1.4.26  236.5 KB   256          66.6%             482cf226-8129-4444-97b1-68e27b5645bc  Rack1-K8Demo


---increase the numer of replica to 4 again

--As we are decommissioning the node on  stopping a pod.We need to clean up the underlying storage which was used for this node.otherwise one will get the following exception.

"org.apache.cassandra.exceptions.ConfigurationException: This node was decommissioned and will not rejoin the ring unless cassandra.override_decommission=true has been set, or all existing data is removed and the node is bootstrapped again"


After the storage cleanup ,pod will come up and will keep on running with restricted scc as before

--cassandra.override_decommission=true is at the moment permamnently set but this can be parametrerized.
due to above parameter  ,pod will come up and will run as anuid scc 

Make sure to execute the following command.

oadm policy add-scc-to-user anyuid -z default

---Loading Initial Schema

Initial Schema is uploaded using the configMap.It consist of two kind of file.

schema.cql:Contains all the definition to be loaded.
validation.cql:Contains query so that it can determine if the definition from schema.cql has already been uploaded.
schema-populate.sh: Execute the above two cql and provide logic so that schema.cql is run only once.



--Creating configMap
oc create configmap dboperation --from-file=schema.cql --from-file=validation.cql --from-file=schema-populate.sh 

--updating configmap
oc create configmap dboperation --from-file=schema.cql --from-file=validation.cql --from-file=schema-populate.sh --dry-run -o yaml |oc replace -f -
-updation takes around 45 secs to reflect changes in pod.

--One can check the log as follows.
oc exec cassandra-0 -- cat /schema.log
oc exec cassandra-0 -- cat /validation.log

