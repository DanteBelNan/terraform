// This script validates that a credential with a specific ID exists.
// It is used by Terraform as a data source to ensure the credential is in place before creating a job.

import com.cloudbees.plugins.credentials.CredentialsProvider
import com.cloudbees.plugins.credentials.common.StandardUsernameCredentials

// The ID of the credential we want to find. Terraform will inject this value.
def credentialId = "${credential_id}"

def credentials = CredentialsProvider.lookupCredentials(
  com.cloudbees.plugins.credentials.Credentials.class,
  jenkins.model.Jenkins.get()
)

def foundCredential = credentials.find { it.id == credentialId }

if (foundCredential) {
  // If found, print the ID. Terraform will read this as the result.
  println(foundCredential.id)
} else {
  // If not found, throw an error. This will cause the Terraform plan/apply to fail.
  throw new Exception("FATAL: Jenkins credential with ID '${credentialId}' not found.")
}