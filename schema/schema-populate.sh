#!/bin/bash
#
# populate cassandra schema.

sleep 60

/ready-probe.sh

while [ $? -eq 1 ]
do
sleep 15
/ready-probe.sh
done

cqlsh -f /dbschema/validation.cql 2>&1 | tee /validation.log
grep -q "not found." /validation.log
if [ $? -eq 0 ] ; then
echo "Running schema.cql" | tee /schema.log
cqlsh -f /dbschema/schema.cql  >>/schema.log
fi
