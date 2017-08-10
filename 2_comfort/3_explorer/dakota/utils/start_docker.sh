#!/bin/bash

# real time graphing information
# real time graphing information
if [[ "$1" == "soga" ]] || [[ "$1" == "soga_surr" ]];then
    # move the plot to a run accessible location
    webdir=$(echo $PWD | sed 's|/core||g')
    url="http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)$webdir/plot.html"
    echo '<html style="overflow-y:hidden"><body style="margin:0px"><a style="font-family:sans-serif;z-index:1000;position:absolute;top:20px;right:0px;margin-right:20px;font-style:italic;font-size:10px" href="" target="_blank">Open in New Window</a><iframe width="100%" height="100%" src="'$url'" frameborder="0"></iframe></body></html>' > ip.html
    
    path="$4"
    jid="$5"

if [[ "$path" == *"/export/galaxy-central/database/job_working_directory"* ]];then
# else upload to job directory
cat > upload.py<<END
import requests
apiurl="https://go.parallel.works/api"
jid="$jid"
print "uploading ip address to job",jid
file = {'file': open('ip.html','rb')}
req = requests.post(apiurl + "/jobs/"+jid+"/upload?key=simple",files=file)
req.raise_for_status()
print req.text
print "complete"
END
python upload.py
else
    cp ip.html $path
fi

fi

# run locally to see dakota swiftwork directories
# /bin/bash templatedir/runDakota.sh "$@"

# otherwise run in docker container for portability
docker run -i --rm -v $PWD:/scratch -w /scratch parallelworks/dakota /bin/bash templatedir/runDakota.sh "$@"

