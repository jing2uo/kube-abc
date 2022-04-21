source ./workflow/1-function.sh
sed "s/CHANGEME/${OWNIP}:8989/g" ./workflow/origin-files/join.sh >./workflow/join.sh
sed "s/CHANGEME/${OWNIP}:8989/g" ./workflow/origin-files/onenode.sh >./workflow/onenode.sh
sed "s/CHANGEME/${OWNIP}:8989/g" ./workflow/origin-files/index.html >./workflow/index.html
sed "s/CHANGEME/${OWNIP}:8989/g" ./workflow/origin-files/cmd >./workflow/cmd

cd ./workflow && python2 -m SimpleHTTPServer 8989
