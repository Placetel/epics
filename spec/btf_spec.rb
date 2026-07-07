RSpec.describe Epics::BTF do
  it 'normalizes attributes into the service hash consumed by HeaderRequest' do
    btf = described_class.new(
      service_name: 'SCT', scope: 'DE', service_option: 'URG',
      container: 'ZIP', msg_name: 'pain.001', msg_name_version: '03', msg_variant: '001'
    )

    expect(btf.to_h).to eq(
      service_name: 'SCT',
      service_option: 'URG',
      scope: 'DE',
      container: 'ZIP',
      msg_name: { name: 'pain.001', version: '03', variant: '001', format: nil }
    )
  end
end

RSpec.describe Epics::BtfMapping do
  it 'maps a known upload code to a BTF' do
    btf = described_class.upload('CCT')
    expect(btf).to be_a(Epics::BTF)
    expect(btf.service_name).to eq('SCT')
    expect(btf.msg_name).to eq('pain.001')
  end

  it 'maps a known download code to a BTF' do
    btf = described_class.download('C53')
    expect(btf.service_name).to eq('EOP')
    expect(btf.container).to eq('ZIP')
    expect(btf.msg_name).to eq('camt.053')
  end

  it 'maps the extended upload set (XE2/AZV/CIP/...)' do
    expect(described_class.upload('XE2').service_name).to eq('MCT')
    expect(described_class.upload('AZV').msg_name).to eq('dtazv')
    expect(described_class.upload('CIP').service_name).to eq('SCI')
    expect(described_class.upload('C2S').scope).to eq('BIL')
  end

  it 'maps the extended download set (Z53/BKA/CDZ/...)' do
    expect(described_class.download('Z53').service_name).to eq('EOP')
    expect(described_class.download('Z53').container).to eq('ZIP')
    expect(described_class.download('CDZ').service_option).to eq('SDD')
    expect(described_class.download('CRZ').service_option).to eq('SCT')
    expect(described_class.download('C5N').service_option).to eq('SCI')
  end

  it 'raises a helpful error for unmapped codes' do
    expect { described_class.upload('ZZZ') }.to raise_error(ArgumentError, /raw/)
  end

  it 'still raises for codes with no H005 form (CD1/FUL/XCT/XDS)' do
    %w[CD1 FUL XCT XDS].each do |code|
      expect { described_class.upload(code) }.to raise_error(ArgumentError)
    end
  end

  it 'applies overrides on top of the mapped defaults' do
    btf = described_class.download('C53', scope: 'CH', msg_name_version: '04')
    expect(btf.service_name).to eq('EOP')   # default kept
    expect(btf.msg_name).to eq('camt.053')  # default kept
    expect(btf.scope).to eq('CH')           # overridden
    expect(btf.msg_name_version).to eq('04')     # overridden
  end

  it 'ignores nil overrides, keeping the mapped default' do
    btf = described_class.download('C53', scope: nil, msg_name_version: nil)
    expect(btf.scope).to eq('DE')
    expect(btf.msg_name_version).to eq('08')
  end
end
