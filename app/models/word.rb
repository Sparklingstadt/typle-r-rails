class Word < ApplicationRecord
  belongs_to :word_list

  INPUT_TYPES = %w[command code word].freeze
  validates :input_type, inclusion: INPUT_TYPES, allow_nil: true

  def as_practice_json = { display:, input:, annotation:, input_type: }
end
