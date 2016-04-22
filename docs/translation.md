---
title: "Translation"
category: "dsl"
weight: 9
anchors:
  - title: "Supported Translations"
    url: "#supported-translations"
  - title: "Usage"
    url: "#usage"
---

_WARNING: Translations of templates between providers is no longer
being actively developed._

## Translation

SparkleFormation has alpha support for template translation from
AWS CFN to target orchestration API template formats.

> NOTE: Translations do not currently support stack nesting functionality

### Supported Translations

Basic support implementations:

* OpenStack
* Rackspace

### Usage

Translations are based around AWS CFN and then target some
remote orchestration API (currently Heat and Rackspace). First
the template must be compiled, then it is passed to the translator
which converts the CFN specific template to the expected format
of the target API:

~~~ruby
sfn = SparkleFormation.new(:my_stack) do
  ...
end

cfn_template = sfn.compile.dump!
translator = SparkleFormation::Translation::Heat.new(cfn_template)

heat_template = translator.translate!
~~~

In general applications of translators, the implementation will
first collect optional template parameters prior to translation
allowing the translator access to parameters that may be required
in places where the resultant template may not have support for
dynamic references. These can then be passed to the translator:

~~~ruby
sfn = SparkleFormation.new(:my_stack) do
  ...
end

cfn_template = sfn.compile.dump!
custom_params = collect_parameters(cfn_template)
translator = SparkleFormation::Translation::Heat.new(
  cfn_template,
  :parameters => custom_params
)

heat_template = translator.translate!
~~~
