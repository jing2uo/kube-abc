source ./workflow/1-function.sh
sed "s/CHANGEME/${OWNIP}:8989/g" ./workflow/origin-files/join.sh >./workflow/join.sh
sed "s/CHANGEME/${OWNIP}:8989/g" ./workflow/origin-files/onenode.sh >./workflow/onenode.sh
sed "s/CHANGEME/${OWNIP}:8989/g" ./workflow/origin-files/index.html >./workflow/index.html
sed "s/CHANGEME/${OWNIP}:8989/g" ./workflow/origin-files/cmd >./workflow/cmd

cd ./workflow && python2 -m SimpleHTTPServer 8989

#cd ./workflow && python3 -m http.server 8989

#docker run --restart=always --name kubeabc -p 8989:80 -v ${PWD}/workflow:/usr/share/nginx/html:ro -d nginx
