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

    def create_connection(typename, transport_id, options = Hash.new)
        out_p, in_p = create_ports(typename)
        if STREAM_TRANSPORTS.include?(Orocos::Port.transport_names[transport_id])
            producer.out.create_stream transport_id, "/test#{typename}"
            consumer.in.create_stream transport_id, "/test#{typename}"
        else
            producer.out.connect_to consumer.in, options.merge(:transport => transport_id)
        end
        return out_p, in_p
    end

    Orocos::Port.transport_names.each do |transport_id, transport_name|
        describe "the #{transport_name} transport" do
            [1, 2, 4, 8].each do |int_size|
                it "should be able to marshal/unmarshal signed integers of size #{int_size}" do
                    out_p, in_p = create_connection("/int#{int_size * 8}_t", transport_id)
                    expected_value = 2 ** (int_size - 1) - 1
                    assert_transmits expected_value, out_p, in_p
                    assert_transmits -expected_value, out_p, in_p
                end
                it "should be able to marshal/unmarshal unsigned integers of size #{int_size}" do
                    out_p, in_p = create_connection("/uint#{int_size * 8}_t", transport_id)
                    expected_value = 2 ** int_size - 1
                    assert_transmits expected_value, out_p, in_p
                end
            end

            it "should be able to marshal/unmarshal true values for booleans" do
                out_p, in_p = create_connection("/bool", transport_id)
                expected_value = true
                assert_transmits expected_value, out_p, in_p
            end
            it "should be able to marshal/unmarshal false values for booleans" do
                out_p, in_p = create_connection("/bool", transport_id)
                expected_value = false
                assert_transmits expected_value, out_p, in_p
            end
            it "should be able to marshal/unmarshal doubles" do
                out_p, in_p = create_connection("/double", transport_id)
                expected_value = Typelib.to_ruby(Typelib.from_ruby(1.95432058430e9, Orocos.registry.get('/double')))
                assert_transmits expected_value, out_p, in_p
            end
            it "should be able to marshal/unmarshal floats" do
                out_p, in_p = create_connection("/float", transport_id)
                expected_value = Typelib.to_ruby(Typelib.from_ruby(1.95432058430e9, Orocos.registry.get('/float')))
                assert_transmits expected_value, out_p, in_p
            end
            it "should be able to marshal/unmarshal strings" do
                expected_value = "blabaetroajapowjra"
                out_p, in_p = create_connection("/std/string", transport_id) #, :data_size => expected_value.size + 1)
                assert_transmits expected_value, out_p, in_p
            end
        end
    end

    describe "property access" do
        def assert_property_access(expected_value, producer, typename)
            producer.create_property 'prop', typename
            producer.prop = expected_value
            assert_equal expected_value, producer.prop
        end

        [1, 2, 4, 8].each do |int_size|
            it "should be able to marshal/unmarshal signed integers of size #{int_size}" do
                producer.create_property 'prop', "/int#{int_size * 8}_t"
                expected_value = 2 ** (int_size - 1) - 1
                producer.prop = expected_value
                assert_equal expected_value, producer.prop
            end
            it "should be able to marshal/unmarshal unsigned integers of size #{int_size}" do
                producer.create_property 'prop', "/uint#{int_size * 8}_t"
                expected_value = 2 ** (int_size - 1) - 1
                producer.prop = expected_value
                assert_equal expected_value, producer.prop
            end
        end
        it "should be able to marshal/unmarshal doubles" do
            expected_value = Typelib.to_ruby(Typelib.from_ruby(1.95432058430e9, Orocos.registry.get('/double')))
            assert_property_access expected_value, producer, "/double"
        end
        it "should be able to marshal/unmarshal floats" do
            expected_value = Typelib.to_ruby(Typelib.from_ruby(1.95432058430e9, Orocos.registry.get('/float')))
            assert_property_access expected_value, producer, "/float"
        end
        it "should be able to marshal/unmarshal true values for booleans" do
            assert_property_access true, producer, "/bool"
        end
        it "should be able to marshal/unmarshal false values for booleans" do
            assert_property_access false, producer, "/bool"
        end
        it "should be able to marshal/unmarshal strings" do
            assert_property_access "blagteapiorujalskn", producer, "/std/string"
        end
    end
end

