# Set up environment variables
echo 'ELASTICSEARCH_USERNAME=elastic' >> /root/.env
#echo -n 'ELASTICSEARCH_PASSWORD=' >> /root/.env
kubectl get secret elasticsearch-es-elastic-user -n default -o go-template='ELASTICSEARCH_PASSWORD={{.data.elastic | base64decode}}' >> /root/.env
echo '' >> /root/.env
echo 'ELASTICSEARCH_URL="http://localhost:30920"' >> /root/.env
echo 'KIBANA_URL="http://localhost:30002"' >> /root/.env
echo 'BUILD_NUMBER="10"' >> /root/.env
echo 'ELASTIC_VERSION="8.18.1"' >> /root/.env
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

echo "Loading Elastic Rules, this will take a moment."
echo
curl -X PUT "http://localhost:30002/api/detection_engine/rules/prepackaged" -u "sdg:changme"  --header "kbn-xsrf: true" -H "Content-Type: application/json"  -d '{}'

echo "Creating Elastic-Agent policy"
echo
curl -X PUT "http://localhost:30002/api/fleet/agent_policies?sys_monitoring=true" -H "Content-Type: application/json" -u "sdg:changeme" -d @- << 'EOF' 
{
  "name": "Host with the Most",
  "description": "A collection of various intergrations for a single host that is running way more than it should",
  "namespace": "default",
  "monitoring_enabled": [
    "logs",
    "metrics",
    "traces"
  ],
  "inactivity_timeout": 1209600,
  "is_protected": false
}
EOF

curl -X PUT "http://localhost:30002/api/fleet/package_policies" -H "Content-Type: application/json" -u "sdg:changeme" -d @- << 'EOF' 
{
  "policy_ids": [
    ""
  ],
  "package": {
    "name": "ti_util",
    "version": "1.7.0"
  },
  "name": "ti_util-1",
  "description": "",
  "namespace": "",
  "inputs": {}
}
EOF

curl -X PUT "http://localhost:30002/api/fleet/package_policies" -H "Content-Type: application/json" -u "sdg:changeme" -d @- << 'EOF' 
{
  "policy_ids": [
    ""
  ],
  "package": {
    "name": "windows",
    "version": "3.1.0"
  },
  "name": "windows-1",
  "description": "",
  "namespace": "",
  "inputs": {
    "windows-winlog": {
      "enabled": true,
      "streams": {
        "windows.applocker_exe_and_dll": {
          "enabled": true,
          "vars": {
            "preserve_original_event": false,
            "event_id": null,
            "ignore_older": "72h",
            "language": 0,
            "tags": [],
            "custom": "# Winlog configuration example\n#batch_read_size: 100"
          }
        },
        "windows.applocker_msi_and_script": {
          "enabled": true,
          "vars": {
            "preserve_original_event": false,
            "event_id": null,
            "ignore_older": "72h",
            "language": 0,
            "tags": [],
            "custom": "# Winlog configuration example\n#batch_read_size: 100"
          }
        },
        "windows.applocker_packaged_app_deployment": {
          "enabled": true,
          "vars": {
            "preserve_original_event": false,
            "event_id": null,
            "ignore_older": "72h",
            "language": 0,
            "tags": [],
            "custom": "# Winlog configuration example\n#batch_read_size: 100"
          }
        },
        "windows.applocker_packaged_app_execution": {
          "enabled": true,
          "vars": {
            "preserve_original_event": false,
            "event_id": null,
            "ignore_older": "72h",
            "language": 0,
            "tags": [],
            "custom": "# Winlog configuration example\n#batch_read_size: 100"
          }
        },
        "windows.forwarded": {
          "enabled": true,
          "vars": {
            "preserve_original_event": false,
            "ignore_older": "72h",
            "language": 0,
            "tags": [
              "forwarded"
            ],
            "custom": "# Winlog configuration example\n#batch_read_size: 100"
          }
        },
        "windows.powershell": {
          "enabled": true,
          "vars": {
            "preserve_original_event": false,
            "event_id": "400, 403, 600, 800",
            "ignore_older": "72h",
            "language": 0,
            "tags": [],
            "custom": "# Winlog configuration example\n#batch_read_size: 100"
          }
        },
        "windows.powershell_operational": {
          "enabled": true,
          "vars": {
            "preserve_original_event": false,
            "event_id": "4103, 4104, 4105, 4106",
            "ignore_older": "72h",
            "language": 0,
            "tags": [],
            "custom": "# Winlog configuration example\n#batch_read_size: 100"
          }
        },
        "windows.sysmon_operational": {
          "enabled": true,
          "vars": {
            "preserve_original_event": false,
            "ignore_older": "72h",
            "language": 0,
            "tags": [],
            "custom": "# Winlog configuration example\n#batch_read_size: 100"
          }
        },
        "windows.windows_defender": {
          "enabled": true,
          "vars": {
            "preserve_original_event": false,
            "event_id": null,
            "ignore_older": "72h",
            "language": 0,
            "tags": [],
            "custom": "# Winlog configuration example\n#batch_read_size: 100"
          }
        }
      }
    },
    "windows-windows/metrics": {
      "enabled": true,
      "streams": {
        "windows.perfmon": {
          "enabled": true,
          "vars": {
            "perfmon.group_measurements_by_instance": false,
            "perfmon.ignore_non_existent_counters": false,
            "perfmon.refresh_wildcard_counters": false,
            "perfmon.queries": "- object: 'Process'\n  instance: [\"*\"]\n  counters:\n   - name: '% Processor Time'\n     field: cpu_perc\n     format: \"float\"\n   - name: \"Working Set\"\n",
            "period": "10s"
          }
        },
        "windows.service": {
          "enabled": true,
          "vars": {
            "period": "60s"
          }
        }
      }
    }
  }
}
EOF

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
bash /opt/workshops/elastic-llm.sh -k false -m anthropic -e true

# Use Security view
bash /opt/workshops/elastic-view.sh -v security
