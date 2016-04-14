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
            # Updates not really supported here. Set as unknown to
            # prompt user to investigate
            UpdateCausesConditional.new('unknown', true)
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
            UpdateCausesConditional.new('replacement',
              lambda{|final, original|
                original.fetch('Properties', 'AvailabilityZones', []).empty? ||
                  final.fetch('Properties', 'AvailabilityZones', []).empty?
              }
            ),
            UpdateCausesConditional.new('none', true)
          ],
          'HealthCheck' => [
            UpdateCausesConditional.new('replacement',
              lambda{|final, original|
                original.fetch('Properties', 'HealthCheck', {}).empty? ||
                  final.fetch('Properties', 'HealthCheck', {}).empty?
              }
            ),
            UpdateCausesConditional.new('none', true)
          ],
          'Subnets' => [
            UpdateCausesConditional.new('replacement',
              lambda{|final, original|
                original.fetch('Properties', 'Subnets', []).empty? ||
                  final.fetch('Properties', 'Subnets', []).empty?
              }
            ),
            UpdateCausesConditional.new('none', true)
          ]
        },
        'AWS::RDS::DBCluster' => {
          'BackupRetentionPeriod' => [
            UpdateCausesConditional.new('interrupt',
              lambda{|final, original|
                fp = final.get('Properties', 'BackupRetentionPeriod').to_i
                op = original.get('Properties', 'BackupRetentionPeriod').to_i
                (fp == 0 && op != 0) ||
                  (op == 0 && fp != 0)
              }
            ),
            UpdateCausesConditional.new('none', true)
          ],
          'PreferredMaintenanceWindow' => [
            # can interrupt if apply immediately is set on api call but
            # no way to know
            UpdateCausesConditional.new('unknown', true)
          ]
        },
        'AWS::RDS::DBClusterParameterGroup' => {
          'Parameters' => [
            # dependent on what parameters have been changed. doesn't
            # look like parameter modifications are applied immediately?
            # set as unknown for safety
            UpdateCausesConditional.new('unknown', true)
          ]
        },
        'AWS::RDS::DBInstance' => {
          'AutoMinorVersionUpgrade' => [
            # can cause interrupts based on future actions (enables
            # auto patching) so leave as unknown for safety
            UpdateCausesConditional.new('unknown', true)
          ],
          'BackupRetentionPeriod' => [
            UpdateCausesConditional.new('interrupt',
              lambda{|final, original|
                fp = final.get('Properties', 'BackupRetentionPeriod').to_i
                op = original.get('Properties', 'BackupRetentionPeriod').to_i
                (fp == 0 && op != 0) ||
                  (op == 0 && fp != 0)
              }
            ),
            UpdateCausesConditional.new('none', true)
          ],
          'DBParameterGroupName' => [
            # changes are not applied until reboot, but it could
            # still be considered an interrupt? setting as unknown
            # for safety
            UpdateCausesConditional.new('unknown', true)
          ],
          'PreferredMaintenanceWindow' => [
            # can interrupt if apply immediately is set on api call but
            # no way to know
            UpdateCausesConditional.new('unknown', true)
          ]
        },
        'AWS::RDS::DBParameterGroup' => {
          'Parameters' => [
            # dependent on what parameters have been changed. doesn't
            # look like parameter modifications are applied immediately?
            # set as unknown for safety
            UpdateCausesConditional.new('unknown', true)
          ]
        },
        'AWS::RDS::EventSubscription' => {
          'SourceType' => [
            UpdateCausesConditional.new('replacement',
              lambda{|final, original|
                !final.get('Properties', 'SourceType')
              }
            ),
            UpdateCausesConditional.new('none', true)
          ]
        },
        'AWS::Route53::HostedZone' => {
          'VPCs' => [
            UpdateCausesConditional.new('replacement',
              lambda{|final, original|
                !final.get('Properties', 'VPCs') ||
                  !original.get('Properties', 'VPCs')
              }
            ),
            UpdateCausesConditional.new('none', true)
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
