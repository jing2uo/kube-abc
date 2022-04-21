source ./workflow/1-function.sh
sed "s/CHANGEME/${OWNIP}:8989/g" ./workflow/origin/join.sh >./workflow/join.sh
sed "s/CHANGEME/${OWNIP}:8989/g" ./workflow/origin/onenode.sh >./workflow/onenode.sh
sed "s/CHANGEME/${OWNIP}:8989/g" ./workflow/origin/index.html >./workflow/index.html
sed "s/CHANGEME/${OWNIP}:8989/g" ./workflow/origin/cmd >./workflow/cmd

cd ./workflow && python2 -m SimpleHTTPServer 8989
