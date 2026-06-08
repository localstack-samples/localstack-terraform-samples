TEST_CMD = @$(LSTK) aws acm list-certificates | jq '.CertificateSummaryList[] | select(.CertificateArn != null and .DomainName != null)' >/dev/null && echo "Certificates found with CertificateArn and DomainName" || (echo "No certificates found with CertificateArn and DomainName" && exit 1)

include ../common.mk
