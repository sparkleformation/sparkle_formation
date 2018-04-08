SparkleFormation.new("load_balancer").overrides do
  dynamic!(:elastic_loadbalancing_load_balancer, :test, :resource_name_suffix => :load_balancer) do
    properties do
      listeners array!(
        -> {
          protocol "HTTP"
          load_balancer_port 80
          instance_port 80
          instance_protocol "HTTP"
        },
        -> {
          protocol "HTTPS"
          load_balancer_port 443
          instance_port 80
          instance_protocol "HTTP"
        }
      )
      health_check do
        healthy_threshold 3
        interval 30
        target "HTTP:80/status"
        timeout 10
        unhealthy_threshold 3
      end
      subnets ["private-subnet"]
    end
  end
end
