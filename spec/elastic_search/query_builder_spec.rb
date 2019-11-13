# frozen_string_literal: true

RSpec.describe ElasticSearch::QueryBuilder do
  let(:source) { %i[name users_gender amount_of_participants locations
                    photos_count selfie fake last_activity_at
                    popularity created_at interests] }
  let(:methods) {
                  {
                    must: %i[query bool must],
                    must_not: %i[query bool must_not],
                    should: %i[query bool should],
                    functions: %i[functions],
                    ids: %i[query terms _id],
                    size: [:size],
                    fields: %i[_source],
                    range: %i[bool must range],
                    sort: %i[sort],
                    aggs: [:aggs]
                  }
                }
  let(:function_score_path) { %i[query function_score] }
  let(:days_ago) { 3 }
  let(:must_clause) { { range: { last_activity_at: { gte: days_ago } } } }
  let(:must_not_clause) { { term: { hidden: true } } }
  let(:should_clause) { { term: { hidden: true } } }
  let(:ids_clause) { Array(1..5) }
  let(:size_clause) { 10 }
  let(:sort_clause) { [popularity: { order: :desc }] }
  let(:functions_clause) { { script_score: { script: "1 - ( 1.0 / ( doc['popularity'].value == 0 ? 1 : doc['popularity'].value ))" }, weight: 1 } }
  let(:function_score) { false }
  subject { described_class.new(function_score: function_score) }
  describe '#exclude_opposite && #exclude_duplicated' do
    context 'with function_score: false && opposite included with must_not' do
      let(:subject) { described_class.new(function_score: function_score) }
      before do
        subject.must([must_clause])
        subject.must_not([must_clause])
        @opts = subject.send(:opts)
      end
      it 'should persists only opposite' do
        expect(@opts.dig(*methods[:must]).first.present?).to eq false
        expect(@opts.dig(*methods[:must_not]).first.present?).to eq true
      end
    end

    context 'with function_score: false && opposite included with must' do
      before do
        subject.must_not([must_clause])
        subject.must([must_clause])
        subject.must([must_clause])
        subject.must([should_clause])
        @opts = subject.send(:opts)
      end
      it 'should persists only opposite' do
        expect(@opts.dig(*methods[:must_not]).first.present?).to eq false
        expect(@opts.dig(*methods[:must]).present?).to eq true
      end
      it 'should not repeat must clause' do
        expect(@opts.dig(*methods[:must]).size).to eq 2
      end
    end
  end

  describe '#multiple clauses' do
    context 'with function_score: false' do
      before do
        subject.must([must_clause])
        subject.must([should_clause])
        subject.must_not([must_not_clause])
        subject.should([should_clause])
        subject.size(size_clause)
        subject.sort([sort_clause])
        subject.fields(source)
        @opts = subject.send(:opts)
      end
      it 'should have added all clauses' do
        expect(@opts.dig(*methods[:must]).present?).to eq true
        expect(@opts.dig(*methods[:must]).first.dig(:range, :last_activity_at, :gte)).to eq days_ago
        expect(@opts.dig(*methods[:must_not]).present?).to eq true
        expect(@opts.dig(*methods[:must_not]).first.dig(:term, :hidden)).to eq true
      end
    end
  end
  describe '#initialized' do
    context 'with function_score: false' do
      before do
        @opts = subject.send(:opts)
      end
      it '@function_score should be false' do
        expect(subject.function_score).to eq false
        expect(@opts.empty?).to eq true
      end
    end

    context 'with function_score: true' do
      let(:function_score) { true }
      before do
        @opts = subject.send(:opts)
      end
      it '@function_score should be true' do
        expect(subject.function_score).to eq true
        expect(@opts.empty?).to eq true
      end
    end
  end

  describe '#must' do
    context 'with function_score: false' do
      before do
        subject.must([must_clause])
        @opts = subject.send(:opts)
      end
      it 'should have query path built' do
        expect(@opts.dig(*methods[:must]).present?).to eq true
        expect(@opts.dig(*function_score_path, *methods[:must]).present?).to eq false
        last_activity_at = @opts.dig(*methods[:must]).first.dig(:range, :last_activity_at)
        expect(last_activity_at.present?).to eq true
        expect(last_activity_at.dig(:gte)).to eq days_ago
      end
    end

    context 'with function_score: true' do
      let(:function_score) { true }
      before do
        subject.must([must_clause])
        @opts = subject.send(:opts)
      end
      it 'should have function_score path built' do
        expect(@opts.dig(*methods[:must]).present?).to eq false
        expect(@opts.dig(*function_score_path, *methods[:must]).present?).to eq true
        last_activity_at = @opts.dig(*function_score_path, *methods[:must]).first.dig(:range, :last_activity_at)
        expect(last_activity_at.present?).to eq true
        expect(last_activity_at.dig(:gte)).to eq days_ago
      end
    end
  end

  describe '#must_not' do
    context 'with function_score: false' do
      before do
        subject.must_not([must_not_clause])
        @opts = subject.send(:opts)
      end
      it 'should have query path built' do
        expect(@opts.dig(*methods[:must_not]).present?).to eq true
        expect(@opts.dig(*function_score_path, *methods[:must_not]).present?).to eq false
        expect(@opts.dig(*methods[:must_not]).first.dig(:term, :hidden)).to eq true
      end
    end

    context 'with function_score: true' do
      let(:function_score) { true }
      before do
        subject.must_not([must_not_clause])
        @opts = subject.send(:opts)
      end
      it 'should have function_score path built' do
        expect(@opts.dig(*methods[:must_not]).present?).to eq false
        must_not_body = @opts.dig(*function_score_path, *methods[:must_not])
        expect(must_not_body.present?).to eq true
        expect(must_not_body.first.dig(:term, :hidden)).to eq true
      end
    end
  end

  describe '#should' do
    context 'with function_score: false' do
      before do
        subject.should([should_clause])
        @opts = subject.send(:opts)
      end
      it 'should have query path built' do
        expect(@opts.dig(*methods[:should]).present?).to eq true
        expect(@opts.dig(*function_score_path, *methods[:should]).present?).to eq false
        expect(@opts.dig(*methods[:should]).first.dig(:term, :hidden)).to eq true
      end
    end

    context 'with function_score: true' do
      let(:function_score) { true }
      before do
        subject.should([should_clause])
        @opts = subject.send(:opts)
      end
      it 'should have function_score path built' do
        expect(@opts.dig(*methods[:should]).present?).to eq false
        expect(@opts.dig(*function_score_path, *methods[:should]).present?).to eq true
        expect(@opts.dig(*function_score_path, *methods[:should]).first.dig(:term, :hidden)).to eq true
      end
    end
  end

  describe '#ids' do
    context 'with function_score: false' do
      before do
        subject.ids(ids_clause)
        @opts = subject.send(:opts)
      end
      it 'should have query path built' do
        expect(@opts.dig(*methods[:ids]).present?).to eq true
        expect(@opts.dig(*function_score_path, *methods[:ids]).present?).to eq false
        expect(@opts.dig(*methods[:ids])).to eq ids_clause
      end
    end

    context 'with function_score: true' do
      let(:function_score) { true }
      before do
        subject.ids(ids_clause)
        @opts = subject.send(:opts)
      end
      it 'should have function_score path built' do
        expect(@opts.dig(*methods[:ids]).present?).to eq false
        expect(@opts.dig(*function_score_path, *methods[:ids]).present?).to eq true
        expect(@opts.dig(*function_score_path, *methods[:ids])).to eq ids_clause
      end
    end
  end

  describe '#functions' do
    context 'with function_score: false' do
      before do
        subject.must([must_clause])
        subject.functions([functions_clause])
        @opts = subject.send(:opts)
      end
      it 'should not have functions path built' do
        expect(@opts.dig(*methods[:functions]).present?).to eq false
      end
    end
  end

  describe '#size && #fields && #sort' do
    context 'with function_score: false' do
      before do
        subject.must([must_clause])
        subject.size(size_clause)
        subject.fields(source)
        subject.sort(sort_clause)
        @opts = subject.send(:opts)
      end
      it 'should have root path built' do
        expect(@opts.dig(*methods[:size]).present?).to eq true
        expect(@opts.dig(*methods[:size])).to eq size_clause
        expect(@opts.dig(*methods[:fields]).present?).to eq true
        expect(@opts.dig(*methods[:fields])).to eq source
        expect(@opts.dig(*methods[:sort]).present?).to eq true
        expect(@opts.dig(*methods[:sort])).to eq sort_clause
      end
    end

    context 'with function_score: true' do
      let(:function_score) { true }
      before do
        subject.size(size_clause)
        subject.fields(source)
        subject.sort(sort_clause)
        subject.must([must_clause])
        @opts = subject.send(:opts)
      end
      it 'should have root path built' do
        expect(@opts.dig(*methods[:size]).present?).to eq true
        expect(@opts.dig(*methods[:size])).to eq size_clause
        expect(@opts.dig(*methods[:fields]).present?).to eq true
        expect(@opts.dig(*methods[:fields])).to eq source
        expect(@opts.dig(*methods[:sort]).present?).to eq true
        expect(@opts.dig(*methods[:sort])).to eq sort_clause
      end
    end
  end
end
