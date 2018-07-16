#!/bin/bash
kubeadm join 192.168.122.19:6443 --token gqtgnc.ky9fkh82vb7ba3hh --discovery-token-ca-cert-hash sha256:e9b28e7725e359a07e7cf1d906503f16ef6694dbdff51edb2cd156b4c89b7e84 --ignore-preflight-errors=cri
