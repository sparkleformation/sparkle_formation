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
            UpdateCausesConditional.new('unknown', true) # EBS AMI dependent
          ],
          'BlockDeviceMappings' => [
            UpdateCausesConditional.new('replacement',
              lambda{|final, original|
                f_maps = final.fetch('Properties', 'BlockDeviceMappings', [])
                o_maps = original.fetch('Properties', 'BlockDeviceMappings', [])
                f_maps.map! do |m|
                  m.delete('DeleteOnTermination')
                  m.to_smash(:sorted)
                end
                o_maps.map! do |m|
                  m.delete('DeleteOnTermination')
                  m.to_smash(:sorted)
                end
                f_maps.size != o_maps.size ||
                  !f_maps.all?{|m| o_maps.include?(m)}
              }
            )
            UpdateCausesConditional.new('none', true)
          ],
          'EbsOptimized' => [
            UpdateCausesConditional.new('unknown', true) # EBS AMI dependent
          ],
          'InstanceType' => [
            UpdateCausesConditional.new('unknown', true) # EBS AMI dependent
          ],
          'KernelId' => [
            UpdateCausesConditional.new('unknown', true) # EBS AMI dependent
          ],
          'RamdiskId' => [
            UpdateCausesConditional.new('unknown', true) # EBS AMI dependent
          ],
          'SecurityGroupIds' => [
            UpdateCausesConditional.new('none',
              lambda{|final, _orig|
                final.get('Properties', 'SubnetId') ||
                  final.fetch('Properties', 'NetworkInterface', {}).values.include?('SubnetId')
              }
            ),
            UpdateCausesConditional.new('replacement', true)
          ],
          'UserData' => [
            UpdateCausesConditional.new('unknown', true) # EBS AMI dependent
          ]
        },
        'AWS::EC2::NetworkInterface' => {
          'PrivateIpAddresses' => [
            UpdateCausesConditional.new('replacement',
              lambda{|final, original|
                f_primary = final.fetch('Properties', 'PrivateIpAddresses', []).detect do |addr|
                  addr['Primary']
                end || Smash.new
                o_primary = original.fetch('Properties', 'PrivateIpAddresses', []).detect do |addr|
                  addr['Primary']
                end || Smash.new
                f_primary.to_smash(:sorted) != o_primary.to_smash(:sorted)
              }
            ),
            UpdateCausesConditional.new('none', true)
          ]
        },
        'AWS::ElastiCache::CacheCluster' => {
          'NumCacheNodes' => [
            UpdateCausesConditional.new('replacement',
              lambda{|final, original|
                [
                  final.get('Properties', 'PreferredAvailabilityZone'),
                  final.get('Properties', 'PreferredAvailabilityZones'),
                  original.get('Properties', 'PreferredAvailabilityZone'),
                  original.get('Properties', 'PreferredAvailabilityZones')
                ].all?{|i| i.nil? || i.empty? }
              }
            ),
            UpdateCausesConditional.new('none', true)
          ],
          'PreferredAvailabilityZones' => [
            UpdateCausesConditional.new('interrupt',
              lambda{|final, original|
                original.get('Properties', 'PreferredAvailabilityZones') ||
                  final.fetch('Properties', 'PreferredAvailabilityZones', []).include?(
                  original.get('Properties', 'PreferredAvailabilityZone')
                )
              }
            ),
            UpdateCausesConditional.new('replacement', true)
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
