require "imap/backup/translator"

module Imap::Backup
  RSpec.describe Translator do
    subject { described_class.new }

    describe "#setup" do
      before do
        allow(I18n).to receive(:load_path=)
        allow(I18n.backend).to receive(:load_translations)
        allow(I18n).to receive(:default_locale=)
        allow(I18n).to receive(:locale=)
      end

      it "sets the load path" do
        subject.setup

        expect(I18n).to have_received(:load_path=)
      end

      it "loads translations" do
        subject.setup

        expect(I18n.backend).to have_received(:load_translations)
      end

      it "sets the default locale to English" do
        subject.setup

        expect(I18n).to have_received(:default_locale=).with(:en)
      end

      context "when LANG=C is set" do
        before do
          allow(ENV).to receive(:[]).and_call_original
          allow(ENV).to receive(:[]).with("LANG") { "C" }
        end

        it "sets the locale to English" do
          subject.setup

          expect(I18n).to have_received(:locale=).with(:en)
        end
      end

      context "when a supported locale is detected" do
        let(:it_tag) { instance_double(Locale::Tag::Simple, language: "it", to_s: "it_IT") }

        before do
          allow(Locale).to receive(:candidates) { [it_tag] }
          allow(subject).to receive(:available_locales) { [:en, :it] }
        end

        it "sets the locale to the detected locale" do
          subject.setup

          expect(I18n).to have_received(:locale=).with(:it)
        end
      end

      context "when an unsupported locale is detected" do
        let(:fr_tag) { instance_double(Locale::Tag::Simple, language: "fr", to_s: "fr_FR") }

        before do
          allow(Locale).to receive(:candidates) { [fr_tag] }
          allow(subject).to receive(:available_locales) { [:en, :it] }
        end

        it "falls back to English" do
          subject.setup

          expect(I18n).to have_received(:locale=).with(:en)
        end
      end

      context "when multiple locales are detected" do
        let(:fr_tag) { instance_double(Locale::Tag::Simple, language: "fr", to_s: "fr_FR") }
        let(:it_tag) { instance_double(Locale::Tag::Simple, language: "it", to_s: "it_IT") }

        before do
          allow(Locale).to receive(:candidates) { [fr_tag, it_tag] }
          allow(subject).to receive(:available_locales) { [:en, :it] }
        end

        it "sets the locale to the first supported locale" do
          subject.setup

          expect(I18n).to have_received(:locale=).with(:it)
        end
      end

      context "when no locales are detected" do
        before do
          allow(Locale).to receive(:candidates) { [] }
        end

        it "falls back to English" do
          subject.setup

          expect(I18n).to have_received(:locale=).with(:en)
        end
      end
    end
  end
end
