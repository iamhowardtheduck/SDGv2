# DELETE Pre-Configured Windows templates
curl -X DELETE "http://localhost:30920/_index_template/logs-network_traffic.dns" -H "Content-Type: application/json" -u "sdg:changeme"
curl -X DELETE "http://localhost:30920/_component_template/logs-network_traffic.dns@package" -H "Content-Type: application/json" -u "sdg:changeme"

# Recreate them in your image
curl -X PUT "http://localhost:30920/_component_template/logs-network_traffic.dns@package" -H "Content-Type: application/json" -u "sdg:changeme" -d @/root/SDGv2/Component-Templates/logs-network_traffic.dns.json
curl -X PUT "http://localhost:30920/_index_template/logs-network_traffic.dns" -H "Content-Type: application/json" -u "sdg:changeme" -d @/root/SDGv2/Index-Templates/logs-network_traffic.dns.json

# Rollover existing index in order to inherit new settings without any garbage data
#curl -X POST "http://localhost:30920/logs-windows.sysmon_operation-default/_rollover" -u "sdg:changeme"

java -jar /root/SDGv2/build/libs/SDGv2-1.0.0-SNAPSHOT.jar /root/SDGv2/Tracks/saife-dns.yml
