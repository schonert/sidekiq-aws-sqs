# frozen_string_literal: true

module Sidekiq
  module AWS
    module SQS
      module Helpers
        def validate_sqs_options!
          raise ArgumentError, 'You must use the `sqs_options` method on your worker' if @sqs_options.blank?

          if need_to_raise_for_queue_url?
            raise ArgumentError,
                  'You must provide either a SQS queue URL or queue name. Like `sqs_options queue_url: "url"` or `sqs_options queue_name: "name"`'
          end

          raise ArgumentError, 'You must provide a SQS client' if need_to_raise_for_client?

          if need_to_raise_for_wait_time_seconds?
            raise ArgumentError,
                  'You must provide a valid wait time like `sqs_options wait_time_seconds: 20`'
          end
          if need_to_raise_for_max_number_of_messages?
            raise ArgumentError,
                  'You must provide a valid max number of messages like `sqs_options max_number_of_messages: 10`'
          end

          return unless need_to_raise_for_destroy_on_received?

          raise ArgumentError,
                'You must provide a valid destroy on received like `sqs_options destroy_on_received: true`'
        end

        def sqs_options_struct
          @sqs_options[:client] ||= Sidekiq::AWS::SQS.config.sqs_client
          @sqs_options[:wait_time_seconds] ||= Sidekiq::AWS::SQS.config.wait_time_seconds
          @sqs_options[:max_number_of_messages] ||= Sidekiq::AWS::SQS.config.max_number_of_messages
          @sqs_options[:destroy_on_received] ||= Sidekiq::AWS::SQS.config.destroy_on_received

          if @sqs_options[:queue_name].present? && @sqs_options[:queue_url].blank?
            queue_url = @sqs_options[:client].get_queue_url(queue_name: @sqs_options[:queue_name]).queue_url
            @sqs_options[:queue_url] = queue_url
          end

          OpenStruct.new(@sqs_options)
        end

        private

        def need_to_raise_for_max_number_of_messages?
          @sqs_options[:max_number_of_messages].present? && @sqs_options[:max_number_of_messages] > 10
        end

        def need_to_raise_for_wait_time_seconds?
          @sqs_options[:wait_time_seconds].present? && @sqs_options[:wait_time_seconds] > 20
        end

        def need_to_raise_for_client?
          Sidekiq::AWS::SQS.config.sqs_client.blank? && @sqs_options[:client].blank?
        end

        def need_to_raise_for_queue_url?
          @sqs_options[:queue_url].blank? && !@sqs_options[:queue_name].blank?
        end

        def need_to_raise_for_destroy_on_received?
          @sqs_options[:destroy_on_received].present? && !@sqs_options[:destroy_on_received].in?([true, false])
        end

        def need_to_destroy_on_received?
          @sqs_options[:destroy_on_received] == true
        end
      end
    end
  end
end
