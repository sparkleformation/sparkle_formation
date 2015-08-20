# Overview

SparkleFormation is a Ruby DSL library that assists in programmatically
composing template files commonly used by orchestration APIs. The library
has specific helper methods defined targeting the AWS CloudFormation
API, but the library is _not_ restricted to generating only AWS CloudFormation
templates.

SparkleFormation templates describe the state of infrastructure resources
as code. This allows for provisioning and updating of isolated stacks of
resources in a predictable and repeatable manner. These stacks can be
mangaged as single independent or interdependent collection which allow
for creation, modification, or deletion via a single API call.

SparkleFormation can be used to compose templates for any orchestration
API that accepts serialized documents to describe resources. This includes
AWS, Rackspace, OpenStack, GCE, and other similar services.

## Table of Contents

- [Getting Started](#getting-started)
- [Building Blocks](building-blocks.md)
  - [SparkleFormation DSL](building-blocks.md#the-dsl)
  - [Components](building-blocks.md#components)
  - [Dynamics](building-blocks.md#dynamics)
  - [Registries](building-blocks.md#registries)
  - [Templates](building-blocks.md#templates)
- [Template Anatomy](anatomy.md)
  - [Base Attributes](anatomy.md#base-attributes)
  - [Parameters](anatomy.md#parameters)
  - [Mappings](anatomy.md#mappings)
  - [Conditions](anatomy.md#conditions)
  - [Resources](anatomy.md#resources)
  - [Outputs](anatomy.md#outputs)
- [Library Features]
  - [Helper Methods](helper_methods.md)
  - [Nested Stacks](nested_stacks.md)
    - [Shallow Nesting](nested_stacks.md#shallow-nesting)
    - [Deep Nesting](nested_stacks.md#deep-nesting)

## Getting Started

SparkleFormation on its own is simply a library used to generate serialized
templates. This documentation is focused mainly on the library specific
features and functionality. For user documentation focused on building and
generating infrastructure with SparkleFormation, please refer to the
sfn documentation.

[cloudformation]: http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-guide.html
[heat]: http://docs.openstack.org/developer/heat/template_guide/index.html
