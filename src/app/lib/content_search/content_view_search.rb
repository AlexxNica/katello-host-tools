#
# Copyright 2013 Red Hat, Inc.
#
# This software is licensed to you under the GNU General Public
# License as published by the Free Software Foundation; either version
# 2 of the License (GPLv2) or (at your option) any later version.
# There is NO WARRANTY for this software, express or implied,
# including the implied warranties of MERCHANTABILITY,
# NON-INFRINGEMENT, or FITNESS FOR A PARTICULAR PURPOSE. You should
# have received a copy of GPLv2 along with this software; if not, see
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.

module ContentSearch

  class ContentViewSearch < ContainerSearch
    attr_accessor :view_ids

    def initialize(options)
      super
      self.rows = build_rows
    end

    def build_rows
      filtered_views.collect do |view|
        cols = {}
        view.environments.collect do |env|
          if readable_env_ids.include?(env.id)
            version = view.version(env).try(:version)
            display = version ? (_("version %s") % version) : ""
            cols[env.id] = Cell.new(:hover => container_hover_html(view, env), :display => display)
          end
        end

        Row.new(:id         => "view_#{view.id}",
                :name       => view.name,
                :cells      => cols,
                :data_type  => "view",
                :value      => view.name,
                :comparable => true
               )
      end
    end

    def views
      @views ||= if self.view_ids
        views = ContentView.readable(current_organization).non_default.where(:id => view_ids)
      else
        views = ContentView.readable(current_organization).non_default
      end
    end

    def view_versions
      @view_versions ||= begin
        versions = views.map{|v| v.versions.in_environment(search_envs)}.flatten
        if search_mode == :unique
          versions = versions.select {|v| !(search_envs - v.environments).empty?}
        elsif search_mode == :shared
          versions = versions.select {|v| (search_envs - v.environments).empty?}
        end

        versions
      end
    end

    # views that have been filtered by search_mode
    def filtered_views
      @filtered_views ||= views.select {|v| view_versions.map(&:content_view_id).include?(v.id)}
    end

  end

end
