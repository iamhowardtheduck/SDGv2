# Set up environment variables
echo 'ELASTICSEARCH_USERNAME=elastic' >> /root/.env
#echo -n 'ELASTICSEARCH_PASSWORD=' >> /root/.env
kubectl get secret elasticsearch-es-elastic-user -n default -o go-template='ELASTICSEARCH_PASSWORD={{.data.elastic | base64decode}}' >> /root/.env
echo '' >> /root/.env
echo 'ELASTICSEARCH_URL="http://localhost:30920"' >> /root/.env
echo 'KIBANA_URL="http://localhost:30002"' >> /root/.env
echo 'BUILD_NUMBER="10"' >> /root/.env
echo 'ELASTIC_VERSION="9.1.0"' >> /root/.env
echo 'ELASTIC_APM_SERVER_URL=http://apm.default.svc:8200' >> /root/.env
echo 'ELASTIC_APM_SECRET_TOKEN=pkcQROVMCzYypqXs0b' >> /root/.env

# Set up environment
export $(cat /root/.env | xargs)

BASE64=$(echo -n "elastic:${ELASTICSEARCH_PASSWORD}" | base64)
KIBANA_URL_WITHOUT_PROTOCOL=$(echo $KIBANA_URL | sed -e 's#http[s]\?://##g')

# Add sdg user with superuser role
curl -X POST "http://localhost:30920/_security/user/sdg" -H "Content-Type: application/json" -u "elastic:${ELASTICSEARCH_PASSWORD}" -d '{
  "password" : "changeme",
  "roles" : [ "superuser" ],
  "full_name" : "SDG User",
  "email" : "sdg@elastic-pahlsoft.com"
}'


# Install Git
sudo apt update -y
# Install Java
sudo apt install -y git default-jre

# Verify Java installation
java_version=$(java -version 2>&1 | head -n 1)
echo "Java installed: $java_version"

# Install Gradle
sudo apt install -y gradle

# Verify Gradle installation
gradle_version=$(gradle -v | grep "Gradle " | awk '{print $2}')
echo "Gradle installed: Version $gradle_version"

# Install Simple-Data-Generator
cd /root/SDGv2 && gradle clean; gradle build fatJar

# Install LLM Connector
bash /opt/workshops/elastic-llm.sh -k false -m anthropic

# Use Security view
bash /opt/workshops/elastic-view.sh -v security

# Create Elastic-Agent policies
curl -X POST "http://localhost:30002/api/fleet/agent_policies?sys_monitoring=true" --header "kbn-xsrf: true"  -H "Content-Type: application/json" -u "sdg:changeme" -d @/root/SDGv2/Agent-Policies/Infra.json
curl -X POST "http://localhost:30002/api/fleet/agent_policies?sys_monitoring=true" --header "kbn-xsrf: true"  -H "Content-Type: application/json" -u "sdg:changeme" -d @/root/SDGv2/Agent-Policies/SecOps.json

# Create Entity Asset lists
curl -X POST "http://localhost:30002/api/asset_criticality/bulk" --header "kbn-xsrf: true"  -H "Content-Type: application/json" -u "sdg:changeme" -d @/root/SDGv2/Entity-Asset-List/entities-v1.json
