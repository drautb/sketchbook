#include <iostream>

#include <aws/core/Aws.h>
#include <aws/cloudformation/CloudFormationClient.h>

using namespace std;

using namespace Aws::CloudFormation;

int main()
{
  Aws::SDKOptions options;
  Aws::InitAPI(options);

  cout << "Attempting to create CloudFormationClient..." << endl;

  CloudFormationClient client;

  cout << "Created client!" << endl;

  Aws::ShutdownAPI(options);
}

