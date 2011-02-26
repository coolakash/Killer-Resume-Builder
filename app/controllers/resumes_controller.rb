class ResumesController < ApplicationController
  
  def new
    @resume = Resume.new
  end
  
  def create
    
    #params[:resume].inspect
    
    @resume = Resume.new(:title => params[:resume][:title], :url => params[:resume][:url], 
    :user_id => current_user.id, :status => "active")
            
    if @resume.save
      
      @resume.resume_personal_information = ResumePersonalInformation.create
      
      @resume.resume_skill = ResumeSkill.create
      
      @resume.resume_field_work = ResumeFieldWork.create
      
      #@resume.resume_keyword = ResumeKeyword.create
      
      @resume.resume_section_order = ResumeSectionOrder.create(:resume_id => @resume.id, 
      :orders => "personal_information/education/skills/work_experience/references/field_works")
      
      @resume.resume_theme = ResumeTheme.create(:theme_id => Theme.default_theme.id)
      
      @resume.resume_setting = ResumeSetting.create
      
      for f in ["personal_information", "education", "skills", "work_experience", "field_works", "references"]
        name = f.sub("_", " ").split(" ").select {|w| w.capitalize! || w}.join(" ")
        @resume.resume_section_names.create!(
          :resume_id => @resume.id,
          :section => f,
          :name => name
        )
      end
      
      
      redirect_to dashboard_path
    else
      render :action => "new"
    end
  end
  
  def show
    @resume = Resume.find_by_url(params[:url])
    if !@resume.nil?
      @theme = Theme.find(@resume.resume_theme.theme_id)
      
      @section_names = {}
      
      @resume.resume_section_names.each do |s|
        @section_names[s.section] = s.name
      end
      
      @section_order = @resume.resume_section_order.orders.split("/")
      
      @keywords = []
      
      if @resume.resume_keywords.count > 0
    	   for keyword in @resume.resume_keywords
    	       @keywords << keyword.keywords
    	   end
    	end
    	
    	@field_works = @resume.resume_field_work.field_works
    	
    	@hidden_fields = []
    	
    	if @resume.resume_hidden_fields.count > 0
    	  for hfield in @resume.resume_hidden_fields
    	    @hidden_fields << hfield.hidden_field
  	    end
  	  end
  	  
  	  user_agent = UserAgent.parse(request.user_agent)
  	  
  	  VisitorInfo.create(:resume_id => @resume.id, :browser => user_agent[2].product, :version => user_agent.version,
  	  :platform => user_agent[0].comment.join(" "), :ip_address => request.remote_addr, :domain_name => request.host)
  	  
  	  @resume.update_attributes(:views => @resume.views + 1)
  	  
  	  ResumeViewer.create(:resume_id => @resume.id, :user_id => current_user.id)
      
      render :layout => "themes/" + @theme.slug
    else
      # TODO: add error handling
    end
  end
  
  def edit
    
    @body_id = "resume_edit"
    
    @resume = Resume.find(params[:id])
    
    @section_names = {}
    
    @resume.resume_section_names.each do |s|
      @section_names[s.section] = s.name
    end
    
    @section_order = @resume.resume_section_order.orders.split("/")
    
    @settings = @resume.resume_setting
    
    @field_works = @resume.resume_field_work.field_works
  	
  	@hidden_fields = []
  	
  	if @resume.resume_hidden_fields.count > 0
  	  for hfield in @resume.resume_hidden_fields
  	    @hidden_fields << hfield.hidden_field
	    end
	  end
    
  end
  
  def update
    @resume = Resume.find(params[:id])

    if @resume.update_attributes(params[:resume])
      flash[:notice] = "Your resume has been updated"
      redirect_to edit_resume_path(@resume)
    else
      render :action => :edit
    end
  end
  
  def delete
    resume = Resume.find(params[:id])
    resume.destroy
    redirect_to dashboard_path
  end
  
  def select_theme
    @themes = get_themes
    @resume = Resume.find(params[:id])
    render :layout => "theme_selector"
  end
  
  private 
  
  def get_themes
    themes = Theme.where(:status => :active).find(:all)
    themes_hash = {}
    
    for theme in themes
      themes_hash[theme.theme] = theme.id
    end
    
    themes_hash
  end
 
end
