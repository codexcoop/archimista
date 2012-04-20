# coding: utf-8

require 'archimate/module_utils'
require 'archimate/core_ext/array'
require 'archimate/core_ext/hash'
require 'archimate/core_ext/object'
require 'archimate/core_ext/string'

::Array.class_eval{ include Archimate::CoreExt::Array }
::Hash.class_eval{ include Archimate::CoreExt::Hash }
::Object.class_eval{ include Archimate::CoreExt::Object }
::String.class_eval{ include Archimate::CoreExt::String }

