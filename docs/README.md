---
title: "Overview"
category: "dsl"
weight: 1
next:
  label: "SparkleFormation DSL"
  url: "sparkleformation-dsl"
---

# Overview

SparkleFormation is a Ruby DSL library that assists in programmatically
composing template files commonly used by orchestration APIs. The library
has specific helper methods defined targeting the [AWS CloudFormation][cfn]
API, but the library is _not_ restricted to generating only
[AWS CloudFormation][cfn] templates.

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
- [The DSL](sparkleformation-dsl)
  - [Behavior](sparkleformation-dsl#behavior)
  - [Features](sparkleformation-dsl#features)
- [Building Blocks](building-blocks)
  - [Components](building-blocks#components)
  - [Dynamics](building-blocks#dynamics)
  - [Registry](building-blocks#registry)
  - [Templates](building-blocks#templates)
- [Template Anatomy](anatomy)
  - [Base Attributes](anatomy#base-attributes)
  - [Parameters](anatomy#parameters)
  - [Mappings](anatomy#mappings)
  - [Conditions](anatomy#conditions)
  - [Resources](anatomy#resources)
  - [Outputs](anatomy#outputs)
- Library Features
  - [Helper Methods](helper-methods)
  - [Nested Stacks](nested-stacks)
    - [Shallow Nesting](nested-stacks#shallow-nesting)
    - [Deep Nesting](nested-stacks#deep-nesting)
  - [Sparkle Packs](sparkle-packs)
  - [Stack Policies](stack-policies)
  - [Translation](translation)

## Getting Started

SparkleFormation on its own is simply a library used to generate serialized
templates. This documentation is focused mainly on the library specific
features and functionality. For user documentation focused on building and
generating infrastructure with SparkleFormation, please refer to the
[sfn][sfn] documentation.

[cfn]: https://aws.amazon.com/cloudformation/
[sfn]: ../../sfn/
