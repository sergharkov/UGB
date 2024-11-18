#!/bin/bash
echo "starting......"
#####################################################
# cat /root/trivy-dbupdatescript/validateupdatedb.sh
# this script need to run inside containers with trivy
# validate laste db update and update db utill all ok
# for run have to go to docker-compose folder and run command
#
# docker-compose -f docker-compose.yml stop trivy-adapter-sheduler \
# && docker-compose -f docker-compose.yml up -d trivy-adapter-sheduler \
# && docker exec -it trivy-adapter-sheduler /tmp/validateupdatedb.sh
#####################################################

function jumpto
{
    label=$1
    cmd=$(sed -n "/$label:/{:a;n;p;ba};" $0 | grep -v ':$')
    eval "$cmd"
    exit
}

start=${1:-"start"}

jumpto $start
start:

DeltaHours="4"
testingimg="docker-registry.cp.ukrgasbank.com/hub.docker.com/library/alpine"
testjavaimmg="bitnami/java"
trivy_path="/home/scanner/.cache/trivy"
JAVADBTMP="/tmp/java-db"
DBTMP="/tmp/db"
mkdir -p $trivy_path/logs
mkdir -p $JAVADBTMP
mkdir -p $DBTMP

trivy_update_log="$trivy_path/logs/trivy_update.log"

trivy_metadata_db="$trivy_path/db/metadata.json"
trivy_metadata_java="$trivy_path/java-db/metadata.json"

CurrentDate=$(date --utc +%FT%T.%3NZ)

trivy_metadata_db_backup="$trivy_path/logs/metadata-$CurrentDate.json"
trivy_metadata_java_backup="$trivy_path/logs/metadata-JAVA-$CurrentDate.json"


NextUpdate_db=$(cat $trivy_metadata_db | sed 's/.*NextUpdate":"//; s/","UpdatedAt.*//')
NextUpdate_java=$(cat $trivy_metadata_java | sed 's/.*NextUpdate":"//; s/","UpdatedAt.*//')

DiffTimeInHours_db=$(( ($(date -d $NextUpdate_db +%s) - $(date -d $CurrentDate +%s)) /60 /60 ))
DiffTimeInHours_java=$(( ($(date -d $NextUpdate_java +%s) - $(date -d $CurrentDate +%s)) /60 /60 ))



echo "+++++++++++++++++++++++++++++++++++++++++++++++++"
echo "NextUpdate_db  ------   $NextUpdate_db"
echo "NextUpdate_java------   $NextUpdate_java"
echo "CurrentDate    ------   $CurrentDate"

echo "Diff Time for DB in Hours       ---   $DiffTimeInHours_db hours"
echo "Diff Time for JAVA-DB in Hours  ---   $DiffTimeInHours_java hours"
echo "DeltaHours in Hours             ---   $DeltaHours hours"

# For JAVA db updateting
echo "start check for JAVA-DBs-------------------------"
if [[ $DiffTimeInHours_java -lt $DeltaHours ]]
   then
        echo "$CurrentDate >>JAVA DB !!!--IS need--!!! for updates. Left $DiffTimeInHours_java hours"
        echo "$CurrentDate >>JAVA DB !!!--IS need--!!! for updates. Left $DiffTimeInHours_java hours" >> $trivy_update_log
        rm -rf $JAVADBTMP/*
        echo "JAVA DB updating........."
gototrivyrunupdatedbjava:
        STDOUTupdainingjava=$( eval "trivy image --cache-dir $JAVADBTMP --download-java-db-only" 2>&1 )
        if [ $? -eq 0 ]
        then
            echo "replace JAVA-db from TMP........................................................"
            rm -rf $trivy_path/java-db/*
            mv $JAVADBTMP/java-db/*  $trivy_path/java-db/
           #STDOUTupdainingjava_after=$( eval "trivy image ---cache-dir $JAVADBTMP -download-java-db-only" 2>&1 )
            echo "$CurrentDate >> Trivy DB JAVA  updaiting finished successfully" >> $trivy_update_log
            jumpto gototrivyrunupdatingdb
        else
            echo "$CurrentDate >> Trivy DB JAVA updating finished Failed"
            echo "$CurrentDate >> Trivy DB JAVA updating finished Failed" >> $trivy_update_log
            if [[ "$STDOUTupdainingjava" == *"TOOMANYREQUESTS"* ]]
             then
               CurrentDate=$(date --utc +%FT%T.%3NZ)
               echo "$CurrentDate >> TOOMANYREQUESTS  TOOMANYREQUESTS  TOOMANYREQUESTS -- so rerun againe"
               echo "$CurrentDate >> TOOMANYREQUESTS  TOOMANYREQUESTS  TOOMANYREQUESTS -- so rerun againe" >> $trivy_update_log
               sleep 5
               echo "+++++++++++++++++++++++++++++++++++++++++++++++++"
               echo "resultresultresult  ---  $STDOUTupdainingjava"
               jumpto gototrivyrunupdatedbjava
            else
              echo "$CurrentDate >> Trivy updating finished Failed with undefined error"
              echo "$CurrentDate >> Trivy updating finished Failed with undefined error" >> $trivy_update_log
              echo "-------------------------"
              echo "resultresultresult  ---  $STDOUTupdainingjava"
            fi
        fi
else
        echo "$CurrentDate >>JAVA DB DON'T needed for updates and next update will be needed in $DiffTimeInHours_java hours"
        echo "$CurrentDate >>JAVA DB DON'T needed for updates and next update will be needed in $DiffTimeInHours_java hours" >> $trivy_update_log
fi

############################################################################################################
# For DBs updating
gototrivyrunupdatingdb:

echo "start check DB-DB ----------------"
if [[ $DiffTimeInHours_db -lt $DeltaHours ]]
   then
        echo "$CurrentDate >>DB     !!!--IS need--!!! for updates. Left $DiffTimeInHours_db hours"
        echo "$CurrentDate >>DB     !!!--IS need--!!! for updates. Left $DiffTimeInHours_db hours" >> $trivy_update_log
        rm -rf $DBTMP/*
        echo " DB updating........."
#       mv $trivy_metadata_db $trivy_metadata_db_backup
gototrivyrunupdatedbs:
        STDOUTupdainingdb=$( eval "trivy --cache-dir $DBTMP -d image $testingimg " 2>&1 )
        if [ $? -eq 0 ]
         then
            echo "replace DB-DB  from TMP........................................................"
            rm -rf $trivy_path/db/*
            mv $DBTMP/db/*  $trivy_path/db/
            echo "$CurrentDate >> Trivy DB DB  updaiting finished successfully"
            echo "$CurrentDate >> Trivy DB DB  updaiting finished successfully" >> $trivy_update_log
            jumpto gotoexit
        else
            echo "$CurrentDate >> Trivy updating finished Failed"
            echo "$CurrentDate >> Trivy updating finished Failed" >> $trivy_update_log
            if [[ "$STDOUTupdainingdb" == *"TOOMANYREQUESTS"* ]]
             then
               CurrentDate=$(date --utc +%FT%T.%3NZ)
               echo "$CurrentDate >> TOOMANYREQUESTS  TOOMANYREQUESTS  TOOMANYREQUESTS -- so rerun againe"
               echo "$CurrentDate >> TOOMANYREQUESTS  TOOMANYREQUESTS  TOOMANYREQUESTS -- so rerun againe" >> $trivy_update_log
               sleep 5
               echo "+++++++++++++++++++++++++++++++++++++++++++++++++"
               echo "resultresultresult  ---  $STDOUTupdainingdb"
               jumpto gototrivyrunupdatedbs
            else
              echo "$CurrentDate >> Trivy updating finished Failed with undefined error"
              echo "$CurrentDate >> Trivy updating finished Failed with undefined error" >> $trivy_update_log
              echo "-------------------------"
              echo $STDOUTupdatingdb
            fi
        fi
else
        echo "$CurrentDate >>DB      DON'T needed for updates and next update will be needed in $DiffTimeInHours_db hours"
        echo "$CurrentDate >>DB      DON'T needed for updates and next update will be needed in $DiffTimeInHours_db hours" >> $trivy_update_log
fi

gotoexit:
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

echo "NextUpdate_db  ------   $NextUpdate_db"
echo "NextUpdate_java------   $NextUpdate_java"
echo "CurrentDate    ------   $CurrentDate"

echo "Diff Time for DB in Hours       ---   $DiffTimeInHours_db hours"
echo "Diff Time for JAVA-DB in Hours  ---   $DiffTimeInHours_java hours"
echo "DeltaHours in Hours             ---   $DeltaHours hours"

echo "//////////////////////////////////-- DB JAVA --///////////////////////////////////////////////////////"
echo "resultresultresult JAVA  ---  $STDOUTupdainingjava"
echo "////////////////////////////////----- DB DB -----/////////////////////////////////////////////////////"
echo "resultresultresult DB  ---  $STDOUTupdainingdb"
echo "//////////////////////////////// END OF SCRIPT-OK /////////////////////////////////////////////////////"
