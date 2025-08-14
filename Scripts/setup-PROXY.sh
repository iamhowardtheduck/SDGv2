# Create logs-proxy templates
curl -X PUT "http://localhost:30920/_index_template/logs-bluecoat.proxy" -H "Content-Type: application/json" -u "sdg:changeme" -d @/root/SDGv2/Index-Templates/logs-bluecoat.proxy.json

# Begin data generation
java -jar /root/SDGv2/build/libs/SDGv2-1.0.0-SNAPSHOT.jar /root/SDGv2/Tracks/saife-proxy.yml
