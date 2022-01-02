var assert = require("assert");
var util = require("util");
var {} = require("@foo-dog/utils");
var _ = require("lodash");
var debugFunc = require('debug')
const parseAttrs = require('./attrs.cjs')
const parseInline = require('./inline.cjs')
const AttrResolver = require("@foo-dog/attrs").AttrResolver