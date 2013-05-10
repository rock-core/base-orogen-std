require 'minitest/spec'
require 'orocos'
require 'orocos/test'

describe 'the transports' do
    include Orocos::Spec

    attr_reader :producer, :consumer
    before do
        Orocos.load_typekit 'std'
        @producer = new_ruby_task_context 'Producer'
        @consumer = new_ruby_task_context 'Consumer'
    end

    def assert_transmits(expected_value, out_p, in_p)
        out_p.write(expected_value)
        sleep 0.1
        assert_equal expected_value, in_p.read, "failed for #{out_p.type.name}"
    end

    def create_ports(typename)
        out_p = producer.create_output_port 'out', typename
        in_p  = consumer.create_input_port 'in', typename
        return out_p, in_p
    end

    STREAM_TRANSPORTS = ['ROS']

    def create_connection(typename, transport_id)
        out_p, in_p = create_ports(typename)
        if STREAM_TRANSPORTS.include?(Orocos::Port.transport_names[transport_id])
            producer.out.create_stream transport_id, "/test#{typename}"
            consumer.in.create_stream transport_id, "/test#{typename}"
        else
            producer.out.connect_to consumer.in, :transport => transport_id
        end
        return out_p, in_p
    end

    Orocos::Port.transport_names.each do |transport_id, transport_name|
        describe "the #{transport_name} transport" do
            [2, 4, 8].each do |int_size|
                it "should be able to marshal/unmarshal signed integers of size #{int_size}" do
                    out_p, in_p = create_connection("/int#{int_size * 8}_t", transport_id)
                    expected_value = 2 ** (int_size - 1) - 1
                    assert_transmits expected_value, out_p, in_p
                    assert_transmits -expected_value, out_p, in_p
                end
                it "should be able to marshal/unmarshal unsigned integers of size #{int_size}" do
                    out_p, in_p = create_connection("/int#{int_size * 8}_t", transport_id)
                    expected_value = 2 ** int_size - 1
                    assert_transmits expected_value, out_p, in_p
                end
            end
        end
    end
end
