FROM couchbase:community-6.0.0

COPY configure-node.sh /opt/couchbase

CMD ["/opt/couchbase/configure-node.sh"]