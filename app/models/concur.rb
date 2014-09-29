class Concur < ActiveRecord::Base
  attr_accessible :site_id, :url

  belongs_to :sites
end
