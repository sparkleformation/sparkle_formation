SparkleFormation.new('load_balancer').overrides do

  dynamic!(:load_balancer, :test) do
    properties do
      listeners array!(
        -> {
          protocol 'HTTP'
          load_balancer_port 80
          instance_port 80
          instance_protocol 'HTTP'
        },
        -> {
          protocol 'HTTPS'
          load_balancer_port 443
          instance_port 80
          instance_protocol 'HTTP'
        }
      )
      health_check do
        healthy_threshold 3
        interval 30
        target 'HTTP:80/status'
        timeout 10
        unhealthy_threshold 3
      end
    end
  end

end
