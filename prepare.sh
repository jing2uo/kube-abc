source ./workflow/1-function.sh
sed "s/CHANGEME/${OWNIP}:8989/g" ./workflow/origin/join.sh >./workflow/join.sh
sed "s/CHANGEME/${OWNIP}:8989/g" ./workflow/origin/onenode.sh >./workflow/onenode.sh
sed "s/CHANGEME/${OWNIP}:8989/g" ./workflow/origin/index.html >./workflow/index.html
cd ./workflow && python3 -m http.server 8989
