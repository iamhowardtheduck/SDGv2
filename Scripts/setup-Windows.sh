curl -X PUT "http://localhost:30920/_component_template/logs-windows.sysmon_operational@package" -H "Content-Type: application/json" -u "sdg:changeme" -d @/root/SDGv2/Component-Templates/logs-windows.sysmon_operational.json

java -jar /root/SDGv2/build/libs/SDGv2-1.0.0-SNAPSHOT.jar /root/SDGv2/Tracks/saife-windows.yml
