#!/usr/bin/env bash

# Setup custom root certificate for istio
# https://istio.io/latest/docs/tasks/security/cert-management/plugin-ca-cert/

NAMESPACE=open5gs
if [[ $# -eq 1 ]] ; then
    istio_enabled=$1
elif [[ $# -eq 2 ]] ; then
    istio_enabled=$1
    NAMESPACE=$2
else
    istio_enabled=0
    NAMESPACE=open5gs
fi

istio_ver=1.24.1
kubectl --kubeconfig=/etc/kubernetes/admin.conf config set-context --current --namespace=$NAMESPACE
/opt/istio-${istio_ver}/bin/istioctl uninstall -c /etc/kubernetes/admin.conf -y --purge
kubectl --kubeconfig=/etc/kubernetes/admin.conf delete namespace istio-system
kubectl --kubeconfig=/etc/kubernetes/admin.conf label namespace $NAMESPACE istio-injection=disabled --overwrite

kubectl --kubeconfig=/etc/kubernetes/admin.conf delete namespace $NAMESPACE
sleep 30
kubectl --kubeconfig=/etc/kubernetes/admin.conf delete pv mongodb-pv-volume-$NAMESPACE
sleep 30
kubectl --kubeconfig=/etc/kubernetes/admin.conf create namespace $NAMESPACE

if [[ $istio_enabled -eq 1 ]] ; then
    #/opt/istio-${istio_ver}/bin/istioctl install -c /etc/kubernetes/admin.conf --set profile=default -y --set meshConfig.accessLogFile=/dev/stdout --set meshConfig.accessLogFormat="{\"protocol\":\"%PROTOCOL%\",\"upstream_service_time\":\"%REQ(x-envoy-upstream-service-time)%\",\"upstream_local_address\":\"%UPSTREAM_LOCAL_ADDRESS%\",\"upstream_remote_address\":\"%UPSTREAM_REMOTE_ADDRESS%\",\"duration\":\"%DURATION%\",\"request_duration\":\"%REQUEST_DURATION%\",\"request_tx_duration\":\"%REQUEST_TX_DURATION%\",\"response_tx_duration\":\"%RESPONSE_TX_DURATION%\",\"response_duration\":\"%RESPONSE_DURATION%\",\"roundtrip_duration\":\"%ROUNDTRIP_DURATION%\",\"upstream_transport_failure_reason\":\"%UPSTREAM_TRANSPORT_FAILURE_REASON%\",\"route_name\":\"%ROUTE_NAME%\",\"downstream_local_address\":\"%DOWNSTREAM_LOCAL_ADDRESS%\",\"user_agent\":\"%REQ(USER-AGENT)%\",\"response_code\":\"%RESPONSE_CODE%\",\"response_flags\":\"%RESPONSE_FLAGS%\",\"start_time\":\"%START_TIME%\",\"method\":\"%REQ(:METHOD)%\",\"request_id\":\"%REQ(X-REQUEST-ID)%\",\"upstream_host\":\"%UPSTREAM_HOST%\",\"x_forwarded_for\":\"%REQ(X-FORWARDED-FOR)%\",\"client_ip\":\"%REQ(True-Client-Ip)%\",\"requested_server_name\":\"%REQUESTED_SERVER_NAME%\",\"bytes_received\":\"%BYTES_RECEIVED%\",\"bytes_sent\":\"%BYTES_SENT%\",\"upstream_cluster\":\"%UPSTREAM_CLUSTER%\",\"downstream_remote_address\":\"%DOWNSTREAM_REMOTE_ADDRESS%\",\"authority\":\"%REQ(:AUTHORITY)%\",\"path\":\"%REQ(X-ENVOY-ORIGINAL-PATH?:PATH)%\",\"response_code_details\":\"%RESPONSE_CODE_DETAILS%\"}" --set meshConfig.enableEnvoyAccessLogService=true --set meshConfig.accessLogEncoding=JSON --set values.global.proxy.enableCoreDump=true
    /opt/istio-${istio_ver}/bin/istioctl install -c /etc/kubernetes/admin.conf --set profile=default -y
    kubectl --kubeconfig=/etc/kubernetes/admin.conf label namespace $NAMESPACE istio-injection=enabled --overwrite
fi

cd /opt/opensource-5g-core/helm-chart/
cp /etc/kubernetes/admin.conf ~/.kube/config
export KUBECONFIG=/etc/kubernetes/admin.conf
helm dependency build
helm -n $NAMESPACE install -f values.yaml 5gcore ./
sleep 10
kubectl --kubeconfig=/etc/kubernetes/admin.conf config set-context --current --namespace=$NAMESPACE

if [[ $istio_enabled -eq 1 ]] ; then
    # Enable mTLS strict mode - STRICT, PERMISSIVE
    # https://istio.io/latest/docs/tasks/security/authentication/mtls-migration/#lock-down-to-mutual-tls-by-namespace
    # In case we want to enable it globally - https://istio.io/latest/docs/tasks/security/authentication/authn-policy/#globally-enabling-istio-mutual-tls-in-strict-mode
kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -n $NAMESPACE -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: "default"
spec:
  mtls:
    mode: STRICT
EOF
fi
