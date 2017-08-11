#!/bin/bash

# real time graphing information
if [[ "$1" == "soga" ]] || [[ "$1" == "soga_surr" ]];then

webdir=$(echo $PWD | sed 's|/core||g')

path=$4
jid=$5

echo PATH $path
echo JID $jid

pwpath="/export/galaxy-central/database/job_working_directory"
if [[ "$path" == *"$pwpath"* ]];then

url="http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/$webdir/plot.html"
echo $url > ip.txt

# else upload to job directory
cat > upload.py<<END
import requests
apiurl="https://go.parallel.works/api"
jid="$jid"
print "uploading ip address to job",jid
file = {'file': open('ip.txt','rb')}
req = requests.post(apiurl + "/jobs/"+jid+"/upload?key=simple",files=file)
req.raise_for_status()
print req.text
print "complete"
END
python upload.py

else

url="http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080/preview/$webdir/plot.html"
echo '<html style="overflow-y:hidden"><body style="margin:0px"><a style="font-family:sans-serif;z-index:1000;position:absolute;top:20px;right:0px;margin-right:20px;font-style:italic;font-size:10px" href="" target="_blank">Open in New Window</a><iframe width="100%" height="100%" src="'$url'" frameborder="0"></iframe></body></html>' > realtime.html

    cp realtime.html $path
fi
   
fi

# run locally to see dakota swiftwork directories
#/bin/bash templatedir/runDakota.sh "$@"

sed -i 's|${env.PWD}"/swiftwork"|"'$PWD/swiftwork'"|g' templatedir/swift.conf

# otherwise run in docker container for portability
docker run -i --rm -v $PWD:/scratch -w /scratch parallelworks/dakota /bin/bash templatedir/runDakota.sh "$@"

