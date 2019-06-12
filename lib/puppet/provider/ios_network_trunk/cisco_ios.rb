require 'puppet/util/network_device/cisco_ios/device'
require 'puppet/resource_api'
require 'puppet/resource_api/simple_provider'
require_relative '../../../puppet_x/puppetlabs/cisco_ios/utility'

# Network Trunk Puppet Provider for Cisco IOS devices
class Puppet::Provider::IosNetworkTrunk::CiscoIos < Puppet::ResourceApi::SimpleProvider
    def self.commands_hash
        @commands_hash = PuppetX::CiscoIOS::Utility.load_yaml(File.expand_path(__dir__) + '/command.yaml')
    end

    def self.interface_names_from_cli(name_output)
        interface_names = []
        name_output.scan(%r{#{commands_hash['get_interfaces_get_value']['default']}}).each do |interface_name|
            interface_names << interface_name.first
        end
        interface_names
    end

    def self.instance_from_cli(output, interface_name)
        new_instance = PuppetX::CiscoIOS::Utility.parse_resource(output, commands_hash)
        new_instance[:name] = interface_name
        new_instance[:mode] = PuppetX::CiscoIOS::Utility.convert_network_trunk_mode_cli(new_instance[:mode])
        new_instance.delete_if { |_k, v| v.nil? }
        new_instance[:ensure] = if new_instance[:ensure] || new_instance.size > 1
                                    'present'
                                else
                                    'absent'
                                end
        new_instance
    end

    def self.commands_from_instance(property_hash)
        commands_array = []
        ensure_command = if PuppetX::CiscoIOS::Utility.attribute_safe_to_run(commands_hash, 'ensure')
                            PuppetX::CiscoIOS::Utility.attribute_value_foraged_from_command_hash(commands_hash, 'ensure', 'set_value')
                         else
                            ''
                         end
        if property_hash[:ensure] == 'absent'
            # delete with a 'no'
            ensure_command = PuppetX::CiscoIOS::Utility.insert_attribute_into_command_line(ensure_command, 'state', 'no', false)
            commands_array.push(ensure_command) if ensure_command != ''
        else
            ensure_command = PuppetX::CiscoIOS::Utility.insert_attribute_into_command_line(ensure_command, 'state', '', false)
            commands_array.push(ensure_command.strip) if ensure_command != ''
            if property_hash[:mode]
                property_hash[:mode] = PuppetX::CiscoIOS::Utility.convert_network_trunk_mode_modelled(property_hash[:mode])
            end
            commands_array += PuppetX::CiscoIOS::Utility.build_commmands_from_attribute_set_values(property_hash, commands_hash)
        end
        commands_array
    end

    def commands_hash
        Puppet::Provider::IosNetworkTrunk::CiscoIos.commands_hash
    end

    def get(context, _names = nil)
        name_output = context.transport.run_command_enable_mode(PuppetX::CiscoIOS::Utility.get_interface_names(commands_hash))
        interface_names = Puppet::Provider::IosNetworkTrunk::CiscoIos.interface_names_from_cli(name_output)

        return_instances = []
        [*interface_names].each do |interface_name|
            get_value_cmd = PuppetX::CiscoIOS::Utility.get_values(commands_hash).to_s.gsub(%r{<name>}, interface_name)
            output = context.transport.run_command_enable_mode(get_value_cmd)
            # If this interface is not a switchable port ignore
            if !output.nil? && (!output.include? ' is not a switchable port')
                return_instances << Puppet::Provider::IosNetworkTrunk::CiscoIos.instance_from_cli(output, interface_name)
            end
        end
        PuppetX::CiscoIOS::Utility.enforce_simple_types(context, return_instances)
    end

    def create(context, name, should)
        context.transport.run_command_interface_mode(name, Puppet::Provider::IosNetworkTrunk::CiscoIos.commands_from_instance(should).join("\n"))
    end

    alias update create

    def delete(context, name)
        delete_hash = { name: name, ensure: 'absent' }
        context.transport.run_command_interface_mode(name, Puppet::Provider::IosNetworkTrunk::CiscoIos.commands_from_instance(delete_hash).join("\n"))
    end

    def canonicalize(_context, resources)
        resources
    end
end