#JAVA_OPTS="-Xms256m -Xmx512m -XX:MaxPermSize=256m $JAVA_OPTS -Djava.awt.headless=true "
JAVA_OPTS="-Xms256m -Xmx512m -XX:MaxPermSize=256m $JAVA_OPTS -Djava.awt.headless=true -Djavax.net.ssl.keyStore=/app/confluence/data/.keystore -Djavax.net.ssl.keyStorePassword=changeit -Djavax.net.ssl.trustStore=/app/confluence/data/.keystore -Djavax.net.ssl.trustStorePassword=changeit -Dconfluence.disable.peopledirectory.all=true "
export JAVA_OPTS

echo "If you encounter issues starting up Confluence Standalone, please see the Installation guide at http://confluence.atlassian.com/display/DOC/Confluence+Installation+Guide"
