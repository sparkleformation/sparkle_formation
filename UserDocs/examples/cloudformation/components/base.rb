<!DOCTYPE html><html><title>SparkleFormation User Documentation</title><xmp theme="simplex" style="display:none;">
SparkleFormation.build do
  set!('AWSTemplateFormatVersion', '2010-09-09')

  resources.cfn_user do
    type 'AWS::IAM::User'
    properties.path '/'
    properties.policies _array(
      -> {
        policy_name 'cfn_access'
        policy_document.statement _array(
          -> {
            effect 'Allow'
            action 'cloudformation:DescribeStackResource'
            resource '*' 
          }
        )
      }
    )
  end

  resources.cfn_keys do
    type 'AWS::IAM::AccessKey'
    properties.user_name ref!(:cfn_user)
  end
end
</xmp><script src="http://strapdownjs.com/v/0.2/strapdown.js"></script></html>
