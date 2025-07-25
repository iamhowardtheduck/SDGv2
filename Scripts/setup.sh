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
gradle clean; gradle build fatJar

source /opt/workshops/elastic-retry.sh

model=gpt-4o
connector=true
knowledgebase=false
prompt=false
while getopts "m:k:c:p:" opt
do
   case "$opt" in
      c ) connector="$OPTARG" ;;
      m ) model="$OPTARG" ;;
      k ) knowledgebase="$OPTARG" ;;
      p ) prompt="$OPTARG" ;;
   esac
done
echo "model=$model"
echo "knowledgebase=$knowledgebase"
echo "prompt=$prompt"

####################################################################### ENV

ENV_FILE_PARENT_DIR=/home/kubernetes-vm
ENV_FILE=$ENV_FILE_PARENT_DIR/env
export $(cat $ENV_FILE | xargs)

####################################################################### OPENAI
# Install LLM in ES

if [ "$connector" = true ] ; then
echo "Adding LLM connector"
add_connector() {
    local http_status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$KIBANA_URL_LOCAL/api/actions/connector" \
    -H 'Content-Type: application/json' \
    --header "kbn-xsrf: true" --header "Authorization: Basic $ELASTICSEARCH_AUTH_BASE64" -d'
    {
    "name":"openai-connector",
    "config": {
        "apiProvider":"OpenAI",
        "apiUrl":"https://'"$LLM_PROXY_URL"'/v1/chat/completions",
        "defaultModel": "'"$model"'"
    },
    "secrets": {
        "apiKey": "'"$LLM_APIKEY"'"
    },
    "connector_type_id":".gen-ai"
    }')

    if echo $http_status | grep -q '^2'; then
        echo "Connector added successfully with HTTP status: $http_status"
        return 0
    else
        echo "Failed to add connector. HTTP status: $http_status"
        return 1
    fi
}
retry_command_lin add_connector
fi

if [ "$knowledgebase" = true ] ; then
# init knowledgebase
echo "Initializing knowledgebase"
init_kb() {
    local http_status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$KIBANA_URL_LOCAL/internal/observability_ai_assistant/kb/setup" \
    -H 'Content-Type: application/json' \
    --header "kbn-xsrf: true" --header "Authorization: Basic $ELASTICSEARCH_AUTH_BASE64")

    if echo $http_status | grep -q '^2'; then
        echo "Elastic knowledgebase successfully initialized: $http_status"
        return 0
    else
        echo "Failed to initialize Elastic knowledgebase. HTTP status: $http_status"
        return 1
    fi
}
retry_command_lin init_kb

wait_kb() {
    output=$(curl -X GET -s "$KIBANA_URL_LOCAL/internal/observability_ai_assistant/kb/status" \
    -H "Authorization: Basic $ELASTICSEARCH_AUTH_BASE64" \
    -H "Content-Type: application/json" \
    -H "kbn-xsrf: true")
    #echo $output
    READY=$(echo $output | jq -r '.ready')
    ENABLED=$(echo $output | jq -r '.enabled')
    MODEL_DEPLOYMENT_STATE=$(echo $output | jq -r '.model_stats.deployment_state')
    MODEL_ALLOCATION_STATE=$(echo $output | jq -r '.model_stats.allocation_state')

    echo $READY
    echo $ENABLED
    echo $MODEL_DEPLOYMENT_STATE
    echo $MODEL_ALLOCATION_STATE

    if [[ $ENABLED = true && $READY = true && $MODEL_DEPLOYMENT_STATE = "started" && $MODEL_ALLOCATION_STATE = "fully_allocated" ]]; then
        echo "o11y kb is ready on $attempt"
        return 0
    else
        echo "o11y kb is not ready on attempt $attempt: $output"
        return 1
    fi
}
retry_command_lin wait_kb

if [ "$prompt" = true ] ; then
curl -X PUT "$KIBANA_URL_LOCAL/internal/observability_ai_assistant/kb/user_instructions" \
  --header 'Content-Type: application/json' \
  --header "kbn-xsrf: true" \
  --header "Authorization: Basic $ELASTICSEARCH_AUTH_BASE64" \
  -d @/opt/workshops/elastic-llm-prompt.json
fi

fi
