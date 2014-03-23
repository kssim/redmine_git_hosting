class RepositoryProtectedBranche < ActiveRecord::Base
  unloadable

  VALID_PERMS  = [ "RW+", "RW", "R", '-' ]
  DEFAULT_PERM = "RW+"

  belongs_to :repository
  belongs_to :role

  validates_presence_of   :repository_id
  validates_presence_of   :role_id
  validates_presence_of   :path
  validates_presence_of   :permissions

  validates_inclusion_of  :permissions, :in => VALID_PERMS

  after_commit ->(obj) { obj.update_permissions }, on: :create
  after_commit ->(obj) { obj.update_permissions }, on: :update
  after_commit ->(obj) { obj.update_permissions }, on: :destroy


  def self.clone_from(parent)
    parent = find_by_id(parent) unless parent.kind_of? RepositoryProtectedBranche
    copy = self.new
    copy.attributes = parent.attributes

    copy
  end


  protected


  def update_permissions
    RedmineGitolite::GitHosting.logger.info { "Update branch permissions for repository : '#{repository.gitolite_repository_name}'" }
    RedmineGitolite::GitHosting.resync_gitolite({ :command => :update_repository, :object => repository.id })
  end

end
