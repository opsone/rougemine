module Rougemine
  module Hooks

    class << self
      # render_on :view_layouts_base_body_bottom,
      #           :partial => 'hooks/rougemine/view_layouts_base_body_bottom'
    end

    class ViewLayoutsBaseHtmlHeadHook < Redmine::Hook::ViewListener
      def view_layouts_base_html_head(context={})
        @context = context;

        context[:rougemine_meta_app_url] = ""
        params                          = context[:controller].params

        if params[:controller].to_sym == :issues && !params[:id].nil?
          Rails.logger.debug 'Condition is true '
          context[:rougemine_meta_app_url] = "rougemine://#{Setting.host_name}/issue?id=#{params[:id]}"
        elsif !project.nil?
          context[:rougemine_meta_app_url] = "rougemine://#{Setting.host_name}/project?id=#{project.try(:id)}"
        end

        context[:controller].send(:render_to_string, {
          :partial => "hooks/rougemine/view_layouts_base_html_head",
          :locals => context
        })
      end

    private
      def project
        return @context[:project] unless @context[:project].nil?
      end
    end
  end
end