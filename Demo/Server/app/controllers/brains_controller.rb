class BrainsController < ApplicationController
  # GET /brains
  # GET /brains.json
  def index
    @brains = Brain.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @brains }
    end
  end

  # GET /brains/1
  # GET /brains/1.json
  def show
    @brain = Brain.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @brain.to_json }
    end
  end

  # GET /brains/new
  # GET /brains/new.json
  def new
    @brain = Brain.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @brain }
    end
  end

  # GET /brains/1/edit
  def edit
    @brain = Brain.find(params[:id])
  end

  # POST /brains
  # POST /brains.json
  def create
    @brain = Brain.new(params[:brain])

    respond_to do |format|
      if @brain.save
        format.html { redirect_to @brain, :notice => 'Brain was successfully created.' }
        format.json { render :json => @brain.to_json, :status => :created, :location => @brain }
      else
        format.html { render :action => "new" }
        format.json { render :json => @brain.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /brains/1
  # PUT /brains/1.json
  def update
    @brain = Brain.find(params[:id])

    respond_to do |format|
      if @brain.update_attributes(params[:brain])
        format.html { redirect_to @brain, :notice => 'Brain was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @brain.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /brains/1
  # DELETE /brains/1.json
  def destroy
    @brain = Brain.find(params[:id])
    @brain.destroy

    respond_to do |format|
      format.html { redirect_to brains_url }
      format.json { head :ok }
    end
  end
end
