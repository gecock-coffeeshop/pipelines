# export PASSWORD=""

# Create a private key
openssl genrsa -out dashboard/tekton-key.pem -passout pass:${PASSWORD} 2048
# Generate the root CA
openssl req -x509 -new -key dashboard/tekton-key.pem -out dashboard/tekton-cert.pem -passin pass:${PASSWORD} -subj //CN=root
# Extract public key
openssl rsa -in dashboard/tekton-key.pem -out dashboard/tekton-key.pem -passin pass:${PASSWORD}
