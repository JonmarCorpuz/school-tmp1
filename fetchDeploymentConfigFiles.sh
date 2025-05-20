# Download the MySQL deployment configuration file
curl -LO https://k8s.io/examples/application/wordpress/mysql-deployment.yaml

# Download the WordPress configuration file
curl -LO https://k8s.io/examples/application/wordpress/wordpress-deployment.yaml

#
kubectl apply -k ./
