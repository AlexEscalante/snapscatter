require 'snapscatter/version'
require 'snapscatter/locker'
require 'aws'

module Snapscatter

  private

  def parse_spec str
    str ||= ""
    spec = {}
    str.split(',').map do |i|
      k, v = i.split(':').map { |i| i.strip }
      spec[k.to_sym] = v
    end
    return spec
  end

  public

  def targets ec2
    ec2.volumes.tagged('Backup').tagged_values('true')
  end

  def list ec2
    ec2.snapshots.tagged('PurgeAllow').tagged_values('true')
  end

  def copy ec2, region, snapshot, description
    options = {
      source_region: region,
      source_snapshot_id: snapshot.id,
      description: description
    }

    response = ec2.client.copy_snapshot options
    copied_snapshot = ec2.snapshots[response.data[:snapshot_id]]
    copied_snapshot.tags.set snapshot.tags
  end

  def purge ec2, purge_after_days, list_only
    purged = []
    snapshots = Snapscatter.list ec2
    snapshots.each do |snapshot|
      purge_date = snapshot.start_time.to_date + purge_after_days
      # puts "#{Date.today} > #{purge_date} == #{Date.today > purge_date}"
      if Date.today > purge_date
        snapshot.delete if not list_only
        purged << snapshot
      end
    end

    return purged
  end

  # consistency spec should look like the following (all parameters but host, optional)
  # strategy: mongo, host: 127.0.0.1, port: 27017, usr: admin, pwd: 12345
  def in_lock consistency_spec
    locker = Locker.new Snapscatter.parse_spec(consistency_spec)
    locker.lock
    begin
      yield
    ensure
      locker.unlock
    end
  end

  module_function :targets, :list, :copy, :purge, :in_lock, :parse_spec

end
