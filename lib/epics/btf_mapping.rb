# frozen_string_literal: true

# Maps the classic H004 order codes (CCT, CDD, C53, ...) to their EBICS 3.0
# (H005) BTF Service descriptors, so the existing convenience API keeps working
# when a client is configured with `version: :h005`.
#
# This is a *starter set* for German (DE) banks. The message versions below are
# the commonly used ISO 20022 versions but ARE bank-specific — verify them
# against your bank's BTF mapping / "Auftragsarten" annex and override via the
# raw Epics::Client#BTU / #BTD API (passing an Epics::BTF) when they differ.
#
# Unmapped codes raise, pointing the caller at the raw BTU/BTD API.
module Epics::BtfMapping
  # code => btf-attributes. Message versions are only pinned where we are fairly
  # confident of the DE default; where omitted the <MsgName> carries no version
  # attribute and the bank applies its own default. Override per call when your
  # bank differs (see Epics::Client convenience methods / #BTU / #BTD).
  UPLOADS = {
    'CCT' => { service_name: 'SCT', scope: 'DE', msg_name: 'pain.001', msg_name_version: '03' },
    'CCS' => { service_name: 'SCT', scope: 'DE', msg_name: 'pain.001', msg_name_version: '03' },
    'CDD' => { service_name: 'SDD', service_option: 'COR', scope: 'DE', msg_name: 'pain.008', msg_name_version: '02' },
    'CDB' => { service_name: 'SDD', service_option: 'B2B', scope: 'DE', msg_name: 'pain.008', msg_name_version: '02' },
    'AZV' => { service_name: 'XCT', scope: 'DE', msg_name: 'dtazv' },
    'C2S' => { service_name: 'SDD', scope: 'BIL', msg_name: 'pain.008' },
    'CDS' => { service_name: 'SDD', scope: 'BIL', msg_name: 'pain.008' },
    'CIP' => { service_name: 'SCI', msg_name: 'pain.001' },
    'XE2' => { service_name: 'MCT', msg_name: 'pain.001' },
    'XE3' => { service_name: 'SDD', msg_name: 'pain.008' },
  }.freeze

  DOWNLOADS = {
    'STA' => { service_name: 'EOP', scope: 'DE', msg_name: 'mt940' },
    'C53' => { service_name: 'EOP', scope: 'DE', container: 'ZIP', msg_name: 'camt.053', msg_name_version: '08' },
    'C52' => { service_name: 'STM', scope: 'DE', container: 'ZIP', msg_name: 'camt.052', msg_name_version: '08' },
    'C54' => { service_name: 'REP', scope: 'DE', container: 'ZIP', msg_name: 'camt.054', msg_name_version: '08' },
    'VMK' => { service_name: 'STM', scope: 'DE', msg_name: 'mt942' },
    'PSR' => { service_name: 'PSR', scope: 'DE', msg_name: 'pain.002', msg_name_version: '03' },
    'Z52' => { service_name: 'STM', container: 'ZIP', msg_name: 'camt.052' },
    'Z53' => { service_name: 'EOP', container: 'ZIP', msg_name: 'camt.053' },
    'Z54' => { service_name: 'EOP', service_option: 'XQRR', container: 'ZIP', msg_name: 'camt.054' },
    'Z01' => { service_name: 'PSR', service_option: 'CH003GEN', container: 'ZIP', msg_name: 'pain.002' },
    'BKA' => { service_name: 'EOP', scope: 'DE', container: 'ZIP', msg_name: 'camt.053' },
    'C5N' => { service_name: 'STM', scope: 'DE', service_option: 'SCI', container: 'ZIP', msg_name: 'camt.054' },
    'CDZ' => { service_name: 'REP', scope: 'DE', service_option: 'SDD', container: 'ZIP', msg_name: 'pain.002' },
    'CRZ' => { service_name: 'REP', scope: 'DE', service_option: 'SCT', container: 'ZIP', msg_name: 'pain.002' },
  }.freeze

  module_function

  # `overrides` lets callers replace individual BTF attributes (e.g. scope,
  # msg_name_version, service_option) on top of the starter-set defaults, so a bank
  # that expects a different message version or scope can be served without
  # dropping to the raw BTU/BTD API. nil overrides are ignored.
  def upload(code, **overrides)
    lookup(UPLOADS, code, overrides)
  end

  def download(code, **overrides)
    lookup(DOWNLOADS, code, overrides)
  end

  def lookup(table, code, overrides = {})
    attrs = table[code.to_s]
    unless attrs
      raise ArgumentError,
        "No H005 BTF mapping for order code #{code.inspect}. Use the raw " \
        "Epics::Client#BTU / #BTD API with an Epics::BTF instead."
    end
    Epics::BTF.new(**attrs.merge(overrides.compact))
  end
end
