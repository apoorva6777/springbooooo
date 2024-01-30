REPO_NAME_PING="springboot-ping-service"
REPO_NAME_STATUS="springboot-status-service"
STORAGE_NAMESPACE="idmaqhrbiuyo"

cd ..
cd infra
cd registry
terraform init
terraform apply --auto-approve
cd ..
cd ..
cd springapp

cd ping
cd javaapp
mvn package
# Build the Docker image and capture the image ID
IMAGE_ID=$(docker build -q -t springapp:v0.1 .)

# Tag the image with the desired repository and version
docker tag $IMAGE_ID iad.ocir.io/$STORAGE_NAMESPACE/$REPO_NAME_PING:v0.1

# Push the tagged image to the repository
docker push iad.ocir.io/$STORAGE_NAMESPACE/$REPO_NAME_PING:v0.1

echo "docker image spring pushed"


cd ..
cd ..

cd status
cd javaapp
mvn package

# Build the Docker image and capture the image ID
IMAGE_ID=$(docker build -q -t springapp2:v0.1 .)

# Tag the image with the desired repository and version
docker tag $IMAGE_ID iad.ocir.io/$STORAGE_NAMESPACE/$REPO_NAME_STATUS:v0.1

# Push the tagged image to the repository
docker push iad.ocir.io/$STORAGE_NAMESPACE/$REPO_NAME_STATUS:v0.1

echo "docker image nest pushed"
cd ..
cd ..
cd ..

cd infra
cd kubernetes
terraform init 
terraform apply --auto-approve

# CLUSTER CONNECT
CLUSTER_ID=$(terraform output -raw k8s-cluster-id)
TF_OUTPUT=$(terraform output k8s-node-pool-id)
TF_OUTPUT="${TF_OUTPUT%\"}"
TF_OUTPUT="${TF_OUTPUT#\"}"
oci ce cluster create-kubeconfig --cluster-id $CLUSTER_ID --file $HOME/.kube/config --region us-ashburn-1 --token-version 2.0.0 --kube-endpoint PUBLIC_ENDPOINT
export KUBECONFIG=$HOME/.kube/config
kubectl get service

cd ..
cd ..
cd scripts


kubectl get service
kubectl apply -f nginx1.yaml
sleep 30
kubectl apply -f namespace-ping.yaml
sleep 10
kubectl create secret docker-registry ocirsecret --docker-server=iad.ocir.io  --docker-username='idmaqhrbiuyo/apoorva.alshi@impetus.com' --docker-password='3(OQmu[P0g}2::CtP#Z9'  --docker-email='apoorva.alshi@impetus.com' -n app2
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=nginxsvc/O=nginxsvc"
kubectl create secret tls tls-secret --key tls.key --cert tls.crt -n app2
kubectl apply -f deployment-ping.yaml
sleep 200
kubectl apply -f service-ping.yaml
sleep 10
kubectl apply -f ingress-ping.yaml
sleep 30
kubectl get svc --all-namespaces
kubectl apply -f metric-server.yaml
sleep 30
kubectl -n kube-system get deployment/metrics-server
kubectl apply -f horizontal-pod-autoscaler-ping.yaml
sleep 60
kubectl get hpa -n app2
kubectl apply -f horizontal-pod-autoscaler-nginx.yaml
sleep 30
kubectl get hpa -n ingress-nginx
sed -E "s|<REPLACE_WITH_DYNAMIC_VALUE>|$TF_OUTPUT|g" autoscaler.yaml > cluster-autoscaler.yaml

kubectl apply -f cluster-autoscaler.yaml
sleep 30
kubectl -n kube-system get cm cluster-autoscaler-status -oyaml    
sleep 10
kubectl apply -f nginx2.yaml
sleep 30
kubectl apply -f namespace-status.yaml
sleep 10
kubectl create secret docker-registry ocirsecret --docker-server=iad.ocir.io  --docker-username='idmaqhrbiuyo/apoorva.alshi@impetus.com' --docker-password='3(OQmu[P0g}2::CtP#Z9'  --docker-email='apoorva.alshi@impetus.com' -n app1
kubectl create secret tls tls-secret --key tls.key --cert tls.crt -n app1
kubectl apply -f deployment-status.yaml
sleep 200
kubectl apply -f service-status.yaml
sleep 10
kubectl apply -f ingress-status.yaml
sleep 30
kubectl get svc --all-namespaces
kubectl -n kube-system get deployment/metrics-server
kubectl apply -f horizontal-pod-autoscaler-status.yaml
sleep 60
kubectl get hpa -n app1
kubectl apply -f horizontal-pod-autoscaler-nginx2.yaml
sleep 30
kubectl get hpa -n ingress-nginx-2

kubectl get svc --all-namespaces





echo "final checks"
kubectl get svc --all-namespaces
kubectl -n kube-system get deployment/metrics-server
kubectl get hpa -n app2
kubectl get hpa -n ingress-nginx
kubectl get hpa -n app1
kubectl get hpa -n ingress-nginx-2

echo "checks done"

NS1=ingress-nginx
SVC1=ingress-nginx-controller
ADDRESS1=$(kubectl -n $NS1 get svc $SVC1 -o json | jq -r '"http://" + .status.loadBalancer.ingress[0].ip + "/api/ping"')
echo $ADDRESS1
 
 
NS2=ingress-nginx-2
SVC2=ingress-nginx-controller
ADDRESS2=$(kubectl -n $NS2 get svc $SVC2 -o json | jq -r '"http://" + .status.loadBalancer.ingress[0].ip + "/api/status"')
echo $ADDRESS2

echo "all done....."




