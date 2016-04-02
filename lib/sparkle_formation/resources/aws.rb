require 'sparkle_formation'

class SparkleFormation

  # Resources helper
  class Resources

    # AWS specific resources collection
    class Aws < Resources

      # Conditionals for property updates
      PROPERTY_UPDATE_CONDITIONALS = Smash.new(
        'AWS::DynamoDB::Table' => {
          'GlobalSecondaryIndexes' => [
            UpdateCausesConditional.new('none',
              lambda{|final, orig|
              }
            ),
            UpdateCausesConditional.new('replacement', true)
          ]
        },
        'AWS::EC2::EIPAssociation' => {
          'AllocationId' => [
            UpdateCausesConditional.new('replacement',
              lambda{|final, original|
                original.get('Properties', 'InstanceId') != final.get('Properties', 'InstanceId') ||
                  original.get('Properties', 'NetworkInterfaceId') != final.get('Properties', 'NewtorkInterfaceId')
              }
            ),
            UpdateCausesConditional.new('none', true)
          ],
          'EIP' => [
            UpdateCausesConditional.new('replacement',
              lambda{|final, original|
                original.get('Properties', 'InstanceId') != final.get('Properties', 'InstanceId') ||
                  original.get('Properties', 'NetworkInterfaceId') != final.get('Properties', 'NewtorkInterfaceId')
              }
            ),
            UpdateCausesConditional.new('none', true)
          ],
          'InstanceId' => [
            UpdateCausesConditional.new('replacement',
              lambda{|final, original|
                original.get('Properties', 'AllocationId') != final.get('Properties', 'AllocationId') ||
                  original.get('Properties', 'EIP') != final.get('Properties', 'EIP')
              }
            ),
            UpdateCausesConditional.new('none', true)
          ],
          'NetworkInterfaceId' => [
            UpdateCausesConditional.new('replacement',
              lambda{|final, original|
                original.get('Properties', 'AllocationId') != final.get('Properties', 'AllocationId') ||
                  original.get('Properties', 'EIP') != final.get('Properties', 'EIP')
              }
            ),
            UpdateCausesConditional.new('none', true)
          ]
        },
        'AWS::EC2::Instance' => {
          'AdditionalInfo' => [
          ],
          'BlockDeviceMappings' => [
          ],
          'EbsOptimized' => [
          ],
          'InstanceType' => [
          ],
          'KernelId' => [
          ],
          'RamdiskId' => [
          ],
          'SecurityGroupIds' => [
            UpdateCausesConditional.new('none',
              lambda{|final, _orig|
                final.get('Properties', 'SubnetId') ||
                  final.fetch('Properties', 'NetworkInterface', {}).values.include?('SubnetId')
              }
            ),
            UpdateCausesConditional.new('replacement',
              lambda{|*_| 'replacement'}
            )
          ],
          'UserData' => [
          ]
        },
        'AWS::EC2::NetworkInterface' => {
          'PrivateIpAddresses' => [
          ]
        },
        'AWS::ElastiCache::CacheCluster' => {
          'NumCacheNodes' => [
          ],
          'PreferredAvailabilityZones' => [
          ]
        },
        'AWS::ElasticLoadBalancing::LoadBalancer' => {
          'AvailabilityZones' => [
          ],
          'HealthCheck' => [
          ],
          'Subnets' => [
          ]
        },
        'AWS::RDS::DBCluster' => {
          'BackupRetentionPeriod' => [
          ],
          'PreferredMaintenanceWindow' => [
          ]
        },
        'AWS::RDS::DBClusterParameterGroup' => {
          'Parameters' => [
          ]
        },
        'AWS::RDS::DBInstance' => {
          'AutoMinorVersionUpgrade' => [
          ],
          'BackupRetentionPeriod' => [
          ],
          'DBParameterGroupName' => [
          ],
          'PreferredMaintenanceWindow' => [
          ]
        },
        'AWS::RDS::DBParameterGroup' => {
          'Parameters' => [
          ]
        },
        'AWS::RDS::EventSubscription' => {
          'SourceType' => [
          ]
        },
        'AWS::Route53::HostedZone' => {
          'VPCs' => [
          ]
        }
      )

      class << self

        include Bogo::Memoization

        # Load the builtin AWS resources
        #
        # @return [TrueClass]
        def load!
          memoize(:aws_resources, :global) do
            load(
              File.join(
                File.dirname(__FILE__),
                'aws_resources.json'
              )
            )
            true
          end
        end

        # Auto load data when included
        def included(_klass)
          load!
        end

      end
    end

  end

end
