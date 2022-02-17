class StealthController < ApplicationController

  unloadable

  skip_before_action :verify_authenticity_token, :only => :toggle
  before_action :authorize_global, :only => :toggle
  accept_api_auth :toggle

  def toggle
    @is_cloaked = toggle_for_params
    respond_to do |format|
      format.js {
        render :js => RedmineStealth.javascript_toggle_statement(@is_cloaked)
      }
      format.api
    end
  end

  private

  def toggle_for_params
    if params[:toggle] == 'true'
      RedmineStealth.cloak!
    elsif params[:toggle] == 'false'
      RedmineStealth.decloak!
    else
      RedmineStealth.toggle_stealth_mode!
    end
  end

end

