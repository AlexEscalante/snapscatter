require 'thor'
require_relative '../snapscatter'

module Snapscatter
  class CLI < Thor
    package_name "Snapscatter"
    map "-v" => :version

    desc 'version', 'Shows current version of the program'
    def version
      say "Snapscatter #{Snapscatter::VERSION}"
    end

    desc 'targets', 'Show volumes tagged for backup'
    method_option :keys, type: :hash, banner: 'AWS security keys'
    def targets
      targets = Snapscatter.targets create_ec2
      targets.each { |target| say target.id }
    end

    desc 'list', 'Show available snapshots'
    method_option :keys, type: :hash, banner: 'AWS security keys'
    method_option :full, type: :boolean, aliases: '-f', banner: 'Show useful info about snapshots'
    def list
      snapshots = Snapscatter.list create_ec2
      snapshots.each do |snapshot|
        output = [ snapshot.id ]
        if options[:full]
          output << snapshot.volume_id
          output << snapshot.start_time.strftime("%Y-%m-%d")
        end
        say output.join(" ")
      end
    end

    desc 'purge', 'purge snapshots older than the specified number of days'
    method_option :keys, type: :hash, banner: 'AWS security keys'
    method_option :days, type: :numeric, default: 30, aliases: '-d', banner: 'retention policy in days'
    method_option :noaction, type: :boolean, default: false, aliases: '-n', banner: 'do not purge, just show'
    method_option :alternate, type: :string, banner: 'alternate region to purge snapshots from'
    def purge
      purged = Snapscatter.purge create_ec2, options[:days], options[:noaction]
      purged.each { |snapshot| say "#{snapshot.id}" }

      if options.has_key? 'alternate'
        purged = Snapscatter.purge create_ec2(region: options[:alternate]), options[:days], options[:noaction]
        purged.each { |snapshot| say "#{snapshot.id}" }
      end
    end

    desc 'create', 'Create snapshots, optionally copying them to an alternate region'
    method_option :keys, type: :hash, banner: 'AWS security keys'
    method_option :alternate, type: :string, banner: 'region to copy snapshots to'
    def create
      source_ec2 = create_ec2
      targets = Snapscatter.targets source_ec2
      targets.each do |volume|
        snapshot = nil
        description = nil

        Snapscatter.in_lock volume.tags['Consistent'] do
          volume_name = volume.tags['Name']
          date_as_string = Date.today.strftime("%Y-%m-%d")
          description = "#{volume_name} #{date_as_string}"

          snapshot = volume.create_snapshot description
          snapshot.add_tag 'VolumeName', value: volume_name
          snapshot.add_tag 'PurgeAllow', value: "true"

          sleep 1 until [:completed, :error].include?(snapshot.status)
        end

        if snapshot.status == :completed
          output = ["created", snapshot.id, description]
          if options.has_key? 'alternate'
            alternate_ec2 = create_ec2(region: options[:alternate])
            Snapscatter.copy alternate_ec2, source_ec2.client.config.region, snapshot, description
            output << "#{options[:alternate]}"
          end
          say output.join(" ")
        else
          say "#{volume.id} (#{volume_name}): snapshot failed"
        end
      end
    end

    private
      def create_ec2 ec2_options={}
        ec2_options.merge! options[:keys] if options.has_key? :keys
        ec2 = AWS::EC2.new(ec2_options)
      end
  end
end