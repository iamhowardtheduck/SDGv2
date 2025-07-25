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
cd /workspace/workshop/SDGv2 && gradle clean; gradle build fatJar

echo "[1/4] Running osquery-setup.sh..."
bash Scripts/osquery-setup.sh
echo "[1/4] Completed osquery-setup.sh."

echo "[2/4] Running mysql-docker-deploy.sh..."
bash Scripts/mysql-docker-deploy.sh
echo "[2/4] Completed mysql-docker-deploy.sh."

echo "[3/4] Running install-fim-chaos.sh..."
bash Scripts/install-fim-chaos.sh
echo "[3/4] Completed install-fim-chaos.sh."

echo "[4/4] Running update /etc/hosts"
bash Scripts/update-etc_hosts.sh
echo "[4/4] Completed install update-etc_hosts.sh"

echo "✅ All scripts completed successfully."
