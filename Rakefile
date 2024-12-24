# -*- mode: ruby; coding: utf-8 -*-
#
# Copyright (C) 2013  Haruka Yoshihara <yoshihara@clear-code.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

task :default => :test

require "rubygems"
require "bundler/gem_helper"
require "packnga"

base_dir = File.join(File.dirname(__FILE__))

helper = Bundler::GemHelper.new(base_dir)
def helper.version_tag
  version
end

helper.install
spec = helper.gemspec

Packnga::DocumentTask.new(spec) do |task|
  task.original_language = "en"
  task.translate_language = "ja"
end

Packnga::ReleaseTask.new(spec) do
end

desc "Run tests"
task :test do
  ruby("test/run-test.rb")
end

release_task = Rake.application["release"]
# We use Trusting Publishing
release_task.prerequisites.delete("build")
release_task.prerequisites.delete("release:rubygem_push")
release_task_comment = release_task.comment
if release_task_comment
  release_task.clear_comments
  release_task.comment = release_task_comment.gsub(/ and build.*$/, "")
end
