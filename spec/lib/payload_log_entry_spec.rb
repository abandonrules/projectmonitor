require 'spec_helper'

describe PayloadLogEntry do

  describe ".reverse_chronological" do
    subject { PayloadLogEntry.reverse_chronological }
    let!(:entry1) { PayloadLogEntry.create(created_at: 2.years.ago) }
    let!(:entry2) { PayloadLogEntry.create(created_at: 1.year.ago) }
    let!(:entry3) { PayloadLogEntry.create }
    it { should == [entry3, entry2, entry1] }
  end

  describe '.latest' do
    subject { PayloadLogEntry.latest }
    let!(:entry1) { PayloadLogEntry.create(created_at: 2.years.ago) }
    let!(:entry2) { PayloadLogEntry.create(created_at: 1.year.ago) }
    let!(:entry3) { PayloadLogEntry.create }
    it { should == entry3 }
  end
end

