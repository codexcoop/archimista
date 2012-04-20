class ApplicationController < ActionController::Base
  helper :all # Include all helpers, all the time
  helper_method :sort_direction # Make the method available to the view
  #protect_from_forgery # See ActionController::RequestForgeryProtection for details

  before_filter :authenticate_user!
  layout :layout_by_resource

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to(root_url, :alert => t('access_denied'))
  end

  # Sortable Columns
  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end

  def terms
    @terms = Term.for_select_options
  end

  def iccd_terms
    @iccd_terms = IccdTerm.all(:joins => :iccd_vocabulary,
      :select => "iccd_terms.*, iccd_vocabularies.name AS vocabulary_name",
      :order => "iccd_vocabularies.name, iccd_terms.position")
  end

  def langs
    @langs = Lang.find(:all, :conditions => {:active => true})
  end

  private

  def layout_by_resource
    if devise_controller? && controller_name == "sessions"
      "login"
    else
      "application"
    end
  end

  # Options: if @fond has_many :creators through :rel_creator_fonds...
  # - :for is the current_object, for example @fond (optional)
  # - :related the target association, ex. :creators (required)
  # - :through is the linking association, ex. :rel_creator_fonds (required)
  # - :available is the available target size, ex. @available_creators
  #   optional, if not provide will be automatically computed, as Creator.count('id')
  # - :suggested is a proc that defines the collection of possible related objects;
  #   this colleciton will be presented for rapid choice (optional);
  #   the block (and then the query), will be executed only if the available target size
  #   is greater than the threshold value;
  #   example: Proc.new{ Creator.all(:select => "id, name", :order => "name") }
  # - :threshold is the maximum size that will be allowed for the collection of
  #   suggested elements, (optional, default 5)
  # - :if is an additional condition (intended as boolean value) that will be checked together with the threshold
  #
  # Given the options, the method will then define the following instance variables
  # - @fond
  # - @rel_creator_fonds
  # - @available_creators
  # - @creators_threshold
  # - @suggested_creators (only if a proc is given as :suggested, and the conditions are met)
  def relation_collections(opts={})
    current_object  = opts[:for]       # => @fond
    related         = opts[:related]   # => :creators
    through         = opts[:through]   # => :rel_creator_fonds
    suggested       = opts[:suggested] # => a block containing a query
    threshold       = opts[:threshold] || 5
    available       = opts[:available]
    conditions      = opts.key?(:if) ? opts[:if] : true

    # @fond
    current_object ||= instance_variable_get("@#{controller_name.classify.underscore}".to_sym)
    # @rel_creator_fonds = @fond.sorted_rel_creator_fonds
    instance_variable_set("@#{through}".to_sym, current_object.send("sorted_#{through}"))
    # @creators_threshold = 5
    instance_variable_set("@#{related}_threshold", threshold)
    # @available_creators   = Creator.count('id') // fixed, warning: the process is different from ather variables
    available = instance_variable_set("@available_#{related}", (available || related.classify.constantize.accessible_by(current_ability, :read).count('id')))
    # @suggested_creators
    if suggested && available <= threshold && conditions
      instance_variable_set("@suggested_#{related}", suggested.call)
    end
  end

  def call_rake(task, options = {})
    options[:rails_env] ||= Rails.env
    args = options.map { |n, v| "#{n.to_s.upcase}='#{v}'" }
    bin_dir = RbConfig::CONFIG['bindir']

    #TODO test windows, import da database non funziona (crewait non supporta sqlite3), teniamo per altri import se serve
    if RbConfig::CONFIG['host_os'] == 'mingw32'
      system "start cmd /c & #{bin_dir}/ruby #{bin_dir}/rake #{task} #{args.join(' ')} --trace --rakefile #{Rails.root}/Rakefile >> #{Rails.root}/log/rake.log 2>&1"
    else
      system "#{bin_dir}/rake #{task} #{args.join(' ')} --trace --rakefile #{Rails.root}/Rakefile >> #{Rails.root}/log/rake.log 2>&1 &"
    end
  end

end

