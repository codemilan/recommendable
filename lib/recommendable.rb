require 'recommendable/configuration'
require 'recommendable/engine'
require 'recommendable/helpers'
require 'recommendable/acts_as_recommended_to'
require 'recommendable/acts_as_recommendable'
require 'recommendable/exceptions'
require 'recommendable/railtie' if defined?(Rails)
require 'recommendable/version'
require 'hooks'

module Recommendable
  mattr_writer :recommendable_classes
  mattr_accessor :user_class

  def self.recommendable_classes
    @@recommendable_classes ||= []
  end

  def self.enqueue(user_id, options={})
    defaults = { :priority => false }
    options = defaults.merge(options)

    if defined? Sidekiq
      if options[:priority]
        SidekiqPriorityWorker.perform_async user_id
      else
        SidekiqWorker.perform_async user_id
      end
    elsif defined? Resque
      Resque.enqueue ResqueWorker, user_id
    elsif defined? Delayed::Job
      Delayed::Job.enqueue DelayedJobWorker.new(user_id)
    elsif defined? Rails::Queueing
      unless Rails.queue.any? { |w| w.user_id == user_id }
        Rails.queue.push RailsWorker.new(user_id)
        Rails.application.queue_consumer.start
      end
    end
  end
end
