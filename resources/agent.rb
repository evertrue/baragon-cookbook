actions :create, :delete

attribute :group, kind_of: String

def initialize(*args)
  super
  @action = :create

  @run_context.include_recipe 'baragon::common'
end
