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
  - [Installation](#installation)
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

### Installation

SparkleFormation is available from [Ruby Gems](https://rubygems.org/gems/sparkle_formation). To install, simply execute:

~~~sh
$ gem install sparkle_formation
~~~

or, if you use [Bundler](http://bundler.io/), add the following to your Gemfile:

~~~sh
gem 'sparkle_formation', '~> 1.0.4'
~~~

This will install the SparkleFormation library. To install the `sfn`
CLI tool, please [refer to its documentation](../sfn/README.html#installation).
