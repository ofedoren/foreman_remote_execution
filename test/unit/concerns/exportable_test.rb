require 'test_plugin_helper'

module ForemanRemoteExecution
  class ExportableTest < ActiveSupport::TestCase
    class SampleModel
      include ::ForemanRemoteExecution::Exportable

      attr_accessor :name, :attrs, :subnet, :mac, :password, :subnet
      attr_exportable :name, :attrs, :mac, :subnet, :mac => ->(m) { m.mac.upcase if m.mac },
                                                    :custom_attr => ->(m) { 'hello world' }

      def attributes
        {
          'name' => name,
          'attrs' => attrs,
          'mac' => mac,
          'password' => password,
          'subnet' => subnet
        }
      end
    end

    class SampleSubnet
      include ::ForemanRemoteExecution::Exportable

      attr_accessor :name, :network
      attr_exportable :name, :network

      def attributes
        {
          'name' => name,
          'network' => network
        }
      end
    end

    def setup
      @subnet = SampleSubnet.new
      @subnet.name = 'pxe'
      @subnet.network = '192.168.122.0'

      @sample = SampleModel.new
      @sample.name = 'name'
      @sample.attrs = {'nested' => 'hash'}
      @sample.subnet = @subnet
      @sample.mac = 'aa:bb:cc:dd:ee:ff'
      @sample.password = 'password'
    end

    test '#to_export includes all specified attributes' do
      assert_equal %w(name attrs mac subnet custom_attr), @sample.to_export.keys
    end

    test '#to_export does not include all attributes' do
      assert_not_include @sample.to_export.keys, 'password'
    end

    test '#to_export calls the lambda' do
      export = @sample.to_export
      assert_equal('AA:BB:CC:DD:EE:FF', export['mac'])
      assert_equal(export['custom_attr'], 'hello world')
    end

    test '#to_export values are exported recursively' do
      export = @sample.to_export
      assert_equal('pxe', export['subnet']['name'])
      assert_equal('192.168.122.0', export['subnet']['network'])
    end

    test '#to_export nested hashes are primitive' do
      @sample.attrs = {:foo => 'bar', :baz => 'qux'}.with_indifferent_access
      export = @sample.to_export
      assert_instance_of Hash, export['attrs']
    end

    test '#to_export includes blank values' do
      @sample.attrs = {}
      export = @sample.to_export
      assert_instance_of Hash, export['attrs']
    end

    test '#to_export(false) does not include blank values' do
      @sample.attrs = {}
      export = @sample.to_export(false)
      assert_nil export['attrs']
    end
  end
end
