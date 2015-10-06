---
title: "Overview"
category: "dsl"
weight: 1
next:
  label: "SparkleFormation DSL"
  url: "sparkleformation-dsl.html"
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

## Getting Started

SparkleFormation on its own is simply a library used to generate serialized
templates. This documentation is focused mainly on the library specific
features and functionality. For user documentation focused on building and
generating infrastructure with SparkleFormation, please refer to the
[sfn][sfn] documentation.

[cfn]: https://aws.amazon.com/cloudformation/
[sfn]: /docs/sfn/
