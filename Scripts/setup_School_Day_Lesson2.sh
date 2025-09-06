# DELETE Pre-Configured templates
curl -X DELETE "http://localhost:30920/_index_template/logs-windows.sysmon_operational" -H "Content-Type: application/json" -u "sdg:changeme"
curl -X DELETE "http://localhost:30920/_component_template/logs-windows.sysmon_operational@package" -H "Content-Type: application/json" -u "sdg:changeme"
curl -X DELETE "http://localhost:30920/_index_template/logs-network_traffic.dns" -H "Content-Type: application/json" -u "sdg:changeme"
curl -X DELETE "http://localhost:30920/_component_template/logs-network_traffic.dns@package" -H "Content-Type: application/json" -u "sdg:changeme"
curl -X DELETE "http://localhost:30920/_index_template/logs-proxysg.log" -H "Content-Type: application/json" -u "sdg:changeme"
curl -X DELETE "http://localhost:30920/_component_template/logs-proxysg.log@package" -H "Content-Type: application/json" -u "sdg:changeme"
curl -X DELETE "http://localhost:30920/_index_template/logs-ti_abusech.malware" -H "Content-Type: application/json" -u "sdg:changeme"
curl -X DELETE "http://localhost:30920/_index_template/logs-ti_abusech.malwarebazaar" -H "Content-Type: application/json" -u "sdg:changeme"
curl -X DELETE "http://localhost:30920/_component_template/logs-ti_abusech.malware@package" -H "Content-Type: application/json" -u "sdg:changeme"
curl -X DELETE "http://localhost:30920/_component_template/logs-ti_abusech.malwarebazaar@package" -H "Content-Type: application/json" -u "sdg:changeme"
curl -X DELETE "http://localhost:30920/_index_template/logs-netflow.log" -H "Content-Type: application/json" -u "sdg:changeme"
curl -X DELETE "http://localhost:30920/_component_template/logs-netflow.log@package" -H "Content-Type: application/json" -u "sdg:changeme"


# Create an updated ingest pipeline for the custom logs
curl -X PUT "http://localhost:30920/_ingest/pipeline/logs@custom" -H "Content-Type: application/x-ndjson" -u "sdg:changeme" -d @/root/SDGv2/Ingest-Pipelines/logs@custom.json

# Recreate them in your image
curl -X PUT "http://localhost:30920/_component_template/logs@settings" -H "Content-Type: application/json" -u "sdg:changeme" -d @/root/SDGv2/Component-Templates/logs@settings.json
curl -X PUT "http://localhost:30920/_index_template/logs" -H "Content-Type: application/json" -u "sdg:changeme" -d @/root/SDGv2/Index-Templates/logs.json
curl -X PUT "http://localhost:30920/_component_template/logs-network_traffic.dns@package" -H "Content-Type: application/json" -u "sdg:changeme" -d @/root/SDGv2/Component-Templates/logs-network_traffic.dns.json
curl -X PUT "http://localhost:30920/_index_template/logs-network_traffic.dns" -H "Content-Type: application/json" -u "sdg:changeme" -d @/root/SDGv2/Index-Templates/logs-network_traffic.dns.json
curl -X PUT "http://localhost:30920/_component_template/logs-proxysg.log@package" -H "Content-Type: application/json" -u "sdg:changeme" -d @/root/SDGv2/Component-Templates/logs-proxysg.log.json
curl -X PUT "http://localhost:30920/_index_template/logs-proxysg.log" -H "Content-Type: application/json" -u "sdg:changeme" -d @/root/SDGv2/Index-Templates/logs-proxysg.log.json
curl -X PUT "http://localhost:30920/_component_template/logs-ti_abusech.malware@package" -H "Content-Type: application/json" -u "sdg:changeme" -d @/root/SDGv2/Component-Templates/logs-ti_abusech.malware.json
curl -X PUT "http://localhost:30920/_index_template/logs-ti_abusech.malware" -H "Content-Type: application/json" -u "sdg:changeme" -d @/root/SDGv2/Index-Templates/logs-ti_abusech.malware.json
curl -X PUT "http://localhost:30920/_index_template/logs-email.filter" -H "Content-Type: application/json" -u "sdg:changeme" -d @/root/SDGv2/Index-Templates/logs-email.filter.json
curl -X PUT "http://localhost:30920/_component_template/logs-netflow.log@package" -H "Content-Type: application/json" -u "sdg:changeme" -d @/root/SDGv2/Component-Templates/logs-netflow.log.json
curl -X PUT "http://localhost:30920/_index_template/logs-netflow.log" -H "Content-Type: application/json" -u "sdg:changeme" -d @/root/SDGv2/Index-Templates/logs-netflow.log.json
curl -X PUT "http://localhost:30920/_component_template/logs-windows.sysmon_operational@package" -H "Content-Type: application/json" -u "sdg:changeme" -d @/root/SDGv2/Component-Templates/logs-windows.sysmon-operational.json
curl -X PUT "http://localhost:30920/_index_template/logs-windows.sysmon_operational" -H "Content-Type: application/json" -u "sdg:changeme" -d @/root/SDGv2/Index-Templates/logs-windows.sysmon_operational.json


# Begin data generation
java -jar /root/SDGv2/build/libs/SDGv2-1.0.0-SNAPSHOT.jar /root/SDGv2/Tracks/schoolday_all_lesson2.yml
