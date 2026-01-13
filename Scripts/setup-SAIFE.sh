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

echo
echo "Simple Data Generator installed"
echo

# Install LLM Connector
bash /opt/workshops/elastic-llm.sh -k false -m gpt-4.1 -d true

echo
echo "AWS Bedrock AI Assistant Connector configured as OpenAI"
echo

# Use Security view
bash /opt/workshops/elastic-view.sh -v security

echo
echo "Security centric Kibana view applied"
echo

# Create Elastic-Agent policies
curl -X POST "http://localhost:30002/api/fleet/agent_policies?sys_monitoring=true" --header "kbn-xsrf: true"  -H "Content-Type: application/json" -u "sdg:changeme" -d @/root/SDGv2/Agent-Policies/Infra.json
curl -X POST "http://localhost:30002/api/fleet/agent_policies?sys_monitoring=true" --header "kbn-xsrf: true"  -H "Content-Type: application/json" -u "sdg:changeme" -d @/root/SDGv2/Agent-Policies/SecOps.json

echo
echo "Elastic-Agent policies Infrastructure & SecOps created"
echo

# Create Entity Asset lists
curl -X POST "http://localhost:30002/api/asset_criticality/bulk" --header "kbn-xsrf: true"  -H "Content-Type: application/json" -u "sdg:changeme" -d @/root/SDGv2/Entity-Asset-List/entities-v1.json

echo
echo "Entity Asset list loaded"
echo

# Load index templates for enrichment data
curl -X POST "http://localhost:30920/_index_template/enrich-bluecoat" -H "Content-Type: application/json" -u "sdg:changeme" -d @/root/SDGv2/Index-Templates/Enrichment-Index-Templates/enrich-bluecoat.json
curl -X POST "http://localhost:30920/_index_template/enrich-nginx" -H "Content-Type: application/json" -u "sdg:changeme" -d @/root/SDGv2/Index-Templates/Enrichment-Index-Templates/enrich-nginx.json
curl -X POST "http://localhost:30920/_index_template/enrich-rip" -H "Content-Type: application/json" -u "sdg:changeme" -d @/root/SDGv2/Index-Templates/Enrichment-Index-Templates/enrich-rip.json
curl -X POST "http://localhost:30920/_index_template/enrich-user_agents" -H "Content-Type: application/json" -u "sdg:changeme" -d @/root/SDGv2/Index-Templates/Enrichment-Index-Templates/enrich-user_agents.json
curl -X POST "http://localhost:30920/_index_template/enrich-windows.sysmon_operational" -H "Content-Type: application/json" -u "sdg:changeme" -d @/root/SDGv2/Index-Templates/Enrichment-Index-Templates/enrich-windows.sysmon_operational.json

echo
echo "Enrichment index templates loaded"
echo

# Load enrichment data sources
curl -X POST "http://localhost:30920/enrich-windows.sysmon_operational/_bulk" -H "Content-Type: application/x-ndjson" -u "sdg:changeme" --data-binary @/root/SDGv2/Enrichment-Data/enrich-windows.sysmon_operational.ndjson
curl -X POST "http://localhost:30920/enrich-rip/_bulk" -H "Content-Type: application/x-ndjson" -u "sdg:changeme" --data-binary @/root/SDGv2/Enrichment-Data/enrich-rip.ndjson
curl -X POST "http://localhost:30920/enrich-bluecoat/_bulk" -H "Content-Type: application/x-ndjson" -u "sdg:changeme" --data-binary @/root/SDGv2/Enrichment-Data/enrich-bluecoat.ndjson
curl -X POST "http://localhost:30920/enrich-nginxv2/_bulk" -H "Content-Type: application/x-ndjson" -u "sdg:changeme" --data-binary @/root/SDGv2/Enrichment-Data/enrich-nginxv2.ndjson
curl -X POST "http://localhost:30920/enrich-user_agents/_bulk" -H "Content-Type: application/x-ndjson" -u "sdg:changeme" --data-binary @/root/SDGv2/Enrichment-Data/enrich-user_agents.ndjson

echo
echo "Enrichment data loaded"
echo

# Create enrichment policies
curl -X PUT "http://localhost:30920/_enrich/policy/enrich-bluecoat" -H "Content-Type: application/x-ndjson" -u "sdg:changeme" --data-binary @/root/SDGv2/Enrichment-Policies/enrich-bluecoat.json
curl -X PUT "http://localhost:30920/_enrich/policy/enrich-nginx" -H "Content-Type: application/x-ndjson" -u "sdg:changeme" --data-binary @/root/SDGv2/Enrichment-Policies/enrich-nginx.json
curl -X PUT "http://localhost:30920/_enrich/policy/enrich-windows.sysmon_operational" -H "Content-Type: application/x-ndjson" -u "sdg:changeme" --data-binary @/root/SDGv2/Enrichment-Policies/enrich-windows.sysmon_operational.json
curl -X PUT "http://localhost:30920/_enrich/policy/remote-ips" -H "Content-Type: application/x-ndjson" -u "sdg:changeme" --data-binary @/root/SDGv2/Enrichment-Policies/remote-ips.json
curl -X PUT "http://localhost:30920/_enrich/policy/user-agents" -H "Content-Type: application/x-ndjson" -u "sdg:changeme" --data-binary @/root/SDGv2/Enrichment-Policies/user-agents.json

echo
echo "Enrichment policies loaded"
echo

# Execute enrichment policies
curl -X POST "http://localhost:30920/_enrich/policy/enrich-windows.sysmon_operational/_execute" -u "sdg:changeme"
curl -X POST "http://localhost:30920/_enrich/policy/remote-ips/_execute" -u "sdg:changeme"
curl -X POST "http://localhost:30920/_enrich/policy/enrich-bluecoat/_execute" -u "sdg:changeme"
curl -X POST "http://localhost:30920/_enrich/policy/enrich-nginx/_execute" -u "sdg:changeme"
curl -X POST "http://localhost:30920/_enrich/policy/user-agents/_execute" -u "sdg:changeme"

echo
echo "Enrichment policies executed"
echo

# Creat ingest pipelines
curl -X PUT "http://localhost:30920/_ingest/pipeline/logs-windows.sysmon_operational" -H "Content-Type: application/x-ndjson" -u "sdg:changeme" -d @/root/SDGv2/Ingest-Pipelines/logs-windows.sysmon_operational.json
curl -X PUT "http://localhost:30920/_ingest/pipeline/logs-ti_abusech.malware@custom" -H "Content-Type: application/x-ndjson" -u "sdg:changeme" -d @/root/SDGv2/Ingest-Pipelines/logs-ti_abusech.malware@custom.json
curl -X PUT "http://localhost:30920/_ingest/pipeline/email-filter-rules" -H "Content-Type: application/x-ndjson" -u "sdg:changeme" -d @/root/SDGv2/Ingest-Pipelines/email-filter-rules.json
curl -X PUT "http://localhost:30920/_ingest/pipeline/enrich-bluecoat" -H "Content-Type: application/x-ndjson" -u "sdg:changeme" -d @/root/SDGv2/Ingest-Pipelines/enrich-bluecoat.json
curl -X PUT "http://localhost:30920/_ingest/pipeline/enrich-email" -H "Content-Type: application/x-ndjson" -u "sdg:changeme" -d @/root/SDGv2/Ingest-Pipelines/enrich-email.json
curl -X PUT "http://localhost:30920/_ingest/pipeline/enrich-logs-network_traffic-dns" -H "Content-Type: application/x-ndjson" -u "sdg:changeme" -d @/root/SDGv2/Ingest-Pipelines/enrich-logs-network_traffic-dns.json
curl -X PUT "http://localhost:30920/_ingest/pipeline/enrich-logs-network_traffic" -H "Content-Type: application/x-ndjson" -u "sdg:changeme" -d @/root/SDGv2/Ingest-Pipelines/enrich-logs-network_traffic.json
curl -X PUT "http://localhost:30920/_ingest/pipeline/enrich-nginx" -H "Content-Type: application/x-ndjson" -u "sdg:changeme" -d @/root/SDGv2/Ingest-Pipelines/enrich-nginx.json
curl -X PUT "http://localhost:30920/_ingest/pipeline/logs-network_traffic-cleanup" -H "Content-Type: application/x-ndjson" -u "sdg:changeme" -d @/root/SDGv2/Ingest-Pipelines/logs-network_traffic-cleanup.json
curl -X PUT "http://localhost:30920/_ingest/pipeline/nginx-cleanup" -H "Content-Type: application/x-ndjson" -u "sdg:changeme" -d @/root/SDGv2/Ingest-Pipelines/nginx-cleanup.json
curl -X PUT "http://localhost:30920/_ingest/pipeline/timestamp-cleanup" -H "Content-Type: application/x-ndjson" -u "sdg:changeme" -d @/root/SDGv2/Ingest-Pipelines/timestamp-cleanup.json
curl -X PUT "http://localhost:30920/_ingest/pipeline/logs-proxysg.log" -H "Content-Type: application/x-ndjson" -u "sdg:changeme" -d @/root/SDGv2/Ingest-Pipelines/logs-proxysg.log.json

echo
echo "Custom Ingest Pipelines loaded"
echo

# Enable beta integrations
curl -u "sdg:changeme" -X PUT http://localhost:30002/api/fleet/settings -H "kbn-xsrf: true" -H "Content-Type: application/json" -d '{"prerelease_integrations_enabled": true}'

# Load pre-built Elastic Security rules
curl -X PUT "http://localhost:30001/api/detection_engine/rules/prepackaged" -u "sdg:changme"  --header "kbn-xsrf: true" -H "Content-Type: application/json"  -d '{}'

echo
echo "Elastic pre-built Security rules loaded, but not activated."
echo
echo "You are now ready to begin the assignment."
