export KUBECONFIG=/etc/kubernetes/admin.conf
alias k='kubectl'
alias kp='kubectl get pods --all-namespaces'
alias ks='kubectl get services --all-namespaces'
alias kn='kubectl get nodes'
alias kt='kubectl top pods --containers'
alias wkp='watch kubectl get pods -A'
alias lgc='google-chrome --no-sandbox --disable-gpu'
alias kl='kubectl logs'
alias ke='kubectl exec -it'
alias kd='kubectl delete pod'
alias kds='kubectl describe pod'
source <(kubectl completion bash)
complete -F __start_kubectl k
echo "export GOPATH=$HOME/go" >> ~/.bashrc
echo "export GOROOT=/usr/local/go" >> ~/.bashrc
echo "export GO111MODULE=auto" >> ~/.bashrc