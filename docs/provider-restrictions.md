---
title: "Provider Restrictions"
category: "dsl"
weight: 9
anchors:
  - title: "Provider Restrictions"
    url: "#provider-restrictions"
  - title: "Setting Provider Restrictions"
    url: "#setting-provider-restrictions"
  - title: "Building Block Uniqueness"
    url: "#building-block-uniqueness"
  - title: "Sharing Building Blocks"
    url: "#sharing-building-blocks"
---

## Provider Restrictions

SparkleFormation supports generating templates for multiple
orchestration APIs. By default all building blocks are assigned
`:aws` as a provider. As a template is compiled and building
block items are requested, the provider restriction is enforced
during lookup. This restriction helps to enforce correctly structured
template by only allowing building blocks with like providers to
interact with each other ensuring a properly compiled template.

## Setting Provider Restriction

Provider restrictions are set using a common pattern among all
building blocks:

### Template

~~~ruby
SparkleFormation.new(:my_template, :provider => :azure) do
  ...
~~~

### Component

~~~ruby
SparkleFormation.component(:my_component, :provider => :azure) do
  ...
~~~

### Dynamic

~~~ruby
SparkleFormation.dynamic(:my_dynamic, :provider => :azure) do
  ...
~~~

### Registry

~~~ruby
SfnRegistry.register(:my_item, :provider => :azure) do
  ...
~~~

## Building Block Uniqueness

### Name Collision Failure

The uniqueness of a building block is based on the combination of
the building block's name and defined provider. This allows common
naming schemes to be applied for multiple providers within the same
runtime. For example, given a template named `:network` defined
as:

~~~ruby
SparkleFormation.new(:network) do
  ...
~~~

the uniqueness of this template is defined by `:network` within
the `:aws` provider (because the `:aws` provider is the default). This
means that defining another template with the provider explicitly defined
for `:aws` will fail:

~~~ruby
SparkleFormation.new(:network, :provider => :aws) do
  ...
~~~

The failure is due to the fact that the names of these two templates is
effectively equivalent.

### Common Name Unique Provider

Using the previous example of a `:network` template, we can define our
template and explicitly set the provider for clarity:

~~~ruby
SparkleFormation.new(:network, :provider => :aws) do
  ...
~~~

Now if we want to provide a template for a different provider (OpenStack
for instance) we can use the same template name but specify a different
target provider:

~~~ruby
SparkleFormation.new(:network, :provider => :heat) do
  ...
~~~

Two templates with a common name (`:network`) now exist within our runtime
because while the name is common, the providers are different. This functionality
applies to all the SparkleFormation building blocks and is important for allowing
a common interface for user interactions while allowing provider specific implementations.

## Sharing Building Blocks

Building blocks may not always need to be restricted to a specific provider. The
provider value used for building block lookup can be overridden. Using this
override functionality allows for sharing building blocks between providers. For
example, lets define a pseudo-template for AWS that sets a value using a registry
item:

~~~ruby
SfnRegistry.register(:creator) do
  'spox'
end
~~~

~~~ruby
SparkleFormation.new(:template) do
  owner registry!(:creator)
end
~~~

Now if the same pseudo-template with a provider set to `:azure` is defined:

~~~ruby
SparkleFormation.new(:template, :provider => :azure) do
  owner registry!(:creator)
end
~~~

it will fail. The failure is due to the implicitly set provider (`:aws`) on the registry
item. To allow sharing of the registry item, we _can_ override the lookup to use
`:aws` as the provider:

~~~ruby
SparkleFormation.new(:template, :provider => :azure) do
  owner registry!(:creator, :provider => :aws)
end
~~~

but this doesn't make logical sense within the layout as the registry item itself
isn't restricted to the AWS provider in any way. A better approach would be defining
a shared provider and using that value for the override. Refactoring would provide
a registry item:

~~~ruby
SfnRegistry.register(:creator, :provider => :shared) do
  'spox'
end
~~~

With the provider set, the two templates can now be updated to use the override:

~~~ruby
SparkleFormation.new(:template) do
  owner registry!(:creator, :provider => :shared)
end
~~~

and:

~~~ruby
SparkleFormation.new(:template, :provider => :azure) do
  owner registry!(:creator, :provider => :shared)
end
~~~
