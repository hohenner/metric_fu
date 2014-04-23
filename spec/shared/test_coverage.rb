shared_examples "rcov test coverage generator" do |metric_name|

  before do
    setup_fs
    MetricFu::Configuration.run do |config|
      config.configure_metric(metric_name) do |rcov|
        rcov.enabled = true
      end
    end
  end

  before :each do
    @default_options = MetricFu::Metric.get_metric(metric_name).run_options
  end

  describe "emit" do
    before :each do
      options = {:external =>  nil}
      @rcov = MetricFu::RcovGenerator.new(@default_options.merge(options))
    end

    # TODO: should this be true of this metric?
    it "should clear out previous output and make output folder" do
      expect(MetricFu::Utility).to receive(:rm_rf).with(MetricFu::RcovGenerator.metric_directory, :verbose => false)
      expect(MetricFu::Utility).to receive(:mkdir_p).with(MetricFu::RcovGenerator.metric_directory)
      @rcov.reset_output_location
    end

  end

  def rcov_output
    FIXTURE.load_file('rcov_output.txt')
  end

  describe "with rcov_output fed into" do
    before :each do
      options = {:external =>  nil}
      @rcov = MetricFu::RcovGenerator.new(@default_options.merge(options))
      expect(@rcov).to receive(:load_output).and_return(rcov_output)
      @files = @rcov.analyze
    end

    describe "analyze" do
      it "should compute percent of lines run" do
        expect(@files["lib/templates/awesome/awesome_template.rb"][:percent_run]).to eq(13)
        expect(@files["lib/templates/standard/standard_template.rb"][:percent_run]).to eq(14)
      end

      it "should know which lines were run" do
        expect(@files["lib/templates/awesome/awesome_template.rb"][:lines]).
              to include({:content=>"require 'fileutils'", :was_run=>true})
      end

      it "should know which lines NOT were run" do
        expect(@files["lib/templates/awesome/awesome_template.rb"][:lines]).
              to include({:content=>"      if template_exists?(section)", :was_run=>false})
      end
    end

    describe "to_h" do
      it "should calculate total percentage for all files" do
        expect(@rcov.to_h[:rcov][:global_percent_run]).to eq(13.7)
      end
    end
  end
  describe "with external configuration option set" do
    before :each do
      options = {:external =>  'coverage/rcov.txt'}
      @rcov = MetricFu::RcovGenerator.new(@default_options.merge(options))
    end

    it "should emit nothing if external configuration option is set" do
      expect(MetricFu::Utility).not_to receive(:rm_rf)
      @rcov.emit
    end

    it "should open the external rcov analysis file" do
      expect(@rcov).to receive(:load_output).and_return(rcov_output)
      @files = @rcov.analyze
    end

  end

  after do
    cleanup_fs
  end

end
