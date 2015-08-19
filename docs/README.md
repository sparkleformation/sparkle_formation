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
  - [Components](building-blocks.md#components)
  - [Dynamics](building-blocks.md#dynamics)
  - [Registries](building-blocks.md#registries)
- [Template Anatomy](anatomy.md)
  - [Parameters](anatomy.md#parameters)
  - [Resources](anatomy.md#resources)
  - [Mappings](anatomy.md#mappings)
  - [Outputs](anatomy.md#outputs)
  - [Nested Stacks](nested_stacks.md)
- [Intrinsic Functions](functions.md)
  - [Ref](functions.md#ref)
  - [Attr](functions.md#attr)
  - [Join](functions.md#join)
- [Universal Properties](properties.md)
 - [Tags](properties.md#tags)
- [Provisioning](provisioning.md)

## Getting Started

SparkleFormation on its own is simply a library used to generate serialized
templates. This documentation is focused mainly on the library specific
features and functionality. For user documentation focused on building and
generating infrastructure with SparkleFormation, please refer to the
sfn documentation.

[cloudformation]: http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-guide.html
[heat]: http://docs.openstack.org/developer/heat/template_guide/index.html
