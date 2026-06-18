apiVersion: v1
kind: ConfigMap
metadata:
  name: balancer-config
  namespace: my-app-prod
data:
  balancer_ip: "${lb_ip}"
