module Actions
  module Foreman
    module Host
      class ImportFacts < Actions::EntryAction
        def resource_locks
          :import_facts
        end

        def plan(_host_type, host_name, facts, certname, proxy_id)
          facts['domain'].try(:downcase!)
          host = if SETTINGS[:version].short > '1.16'
                   ::Host::Base.import_host(host_name, certname, proxy_id)
                 else
                   # backwards compatibility
                   ::Host::Managed.import_host(host_name, facts['_type'], certname, proxy_id)
                 end
          host.save(:validate => false) if host.new_record?
          action_subject(host, :facts => facts)
          if host.build?
            ::Foreman::Logging.logger('foreman-tasks').info "Skipping importing of facts for #{host.name} because it's in build mode"
          else
            plan_self
          end
        end

        def run
          ::User.as :admin do
            # output contents of 'input' variable in debug log.
            ::Foreman::Logging.logger('foreman-tasks').debug "'input' value: #{input}"
            # input[:facts] gets converted to an escaped String, fix by "eval":ing back to hash
            input[:facts] = eval(input[:facts])
            # input contains key-name "managed" if host is managed, or "host"
            # if unmanaged by foreman.
            host           = ::Host.find(input[:managed][:id]) if input.has_key?(:managed)
            host           = ::Host.find(input[:host][:id]) if input.has_key?(:host)
            state          = host.import_facts(input[:facts])
            output[:state] = state
          end
        rescue ::Foreman::Exception => e
          # This error is what is thrown by Host#ImportHostAndFacts when
          # the Host is in the build state. This can be refactored once
          # issue #3959 is fixed.
          raise e unless e.code == 'ERF51-9911'
        end

        def rescue_strategy
          ::Dynflow::Action::Rescue::Skip
        end

        def humanized_name
          _('Import facts')
        end

        def humanized_input
          input[:host] && input[:host][:name]
        end

        # default value for cleaning up the tasks, it can be overriden by settings
        def self.cleanup_after
          '30d'
        end
      end
    end
  end
end
