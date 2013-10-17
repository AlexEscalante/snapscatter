require 'thor'
require_relative '../snapscatter'

module Snapscatter
  class CLI < Thor

    desc 'targets', 'Show volumes tagged for backup'
    method_option :keys, type: :hash, banner: 'AWS security keys'
    def targets
      targets = Snapscatter.targets create_ec2
      targets.each { |target| puts target.id }
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
          output << snapshot.tags['PurgeAfter']
        end
        puts output.join(" ")
      end
    end

    desc 'purge', 'purge snapshots older than specified date'
    method_option :keys, type: :hash, banner: 'AWS security keys'
    method_option :date, type: :string, default: Date.today.strftime("%Y-%m-%d"), aliases: '-d', banner: 'date in yy-mm-dd format'
    method_option :noaction, type: :boolean, default: false, aliases: '-n', banner: 'do not purge, just show'
    def purge
      date = Date.strptime(options[:date], "%Y-%m-%d")
      purged = Snapscatter.purge create_ec2, date, true # options[:noaction] # remove in production
      purged.each { |snapshot| puts "#{snapshot.id}" }
    end

    desc 'create', 'Create snapshots, optionally copying them to destination region'
    method_option :keys, type: :hash, banner: 'AWS security keys'
    method_option :destination, type: :string, banner: 'region to copy snapshots to'
    def create
      source_ec2 = create_ec2
      targets = Snapscatter.targets source_ec2
      targets.each do |volume|
        snapshot = nil
        description = nil

        Snapscatter.in_lock volume.tags['Consistent'] do
          volume_name = volume.tags['Name']
          date_as_string = Date.today.strftime("%Y-%m-%d")
          purge_after = Date.today.next_month.strftime("%Y-%m-%d")
          description = "#{volume_name} #{date_as_string}"

          snapshot = volume.create_snapshot description
          snapshot.add_tag 'VolumeName', value: volume_name
          snapshot.add_tag 'PurgeAfter', value: purge_after
          snapshot.add_tag 'PurgeAllow', value: "true"

          sleep 1 until [:completed, :error].include?(snapshot.status)
        end

        if snapshot.status == :completed
          output = ["created", snapshot.id, description]
          if options.has_key? 'destination'
            destination_ec2 = create_ec2(region: options[:destination])
            Snapscatter.copy destination_ec2, source_ec2.client.config.region, snapshot, description
            output << "#{options[:destination]}"
          end
          puts output.join(" ")
        else
          puts "#{volume.id} (#{volume_name}): snapshot failed"
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