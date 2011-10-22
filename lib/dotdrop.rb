require 'logger'
require "highline/import"
require 'fileutils'
require "dotdrop/item"

class DotDrop

  def self.run!(mode='add', name=nil)
    case mode
    when 'import'
      self.import(name)
    when 'install'
      self.install(name)
    else
      say("Could not understand #{mode}. Try add or import")
    end
  end

  def self.load_env
    @dropbox_location = ENV["DROPBOX_LOCATION"] || Dir.home + "/Dropbox"
    while(!Dir.exist?(@dropbox_location))
      @dropbox_location = ask("Couldn't find your Dropbox folder? There is no #{@dropbox} folder. Where is your Dropbox located?")
    end

    @dotfile_location = @dropbox_location + "/dotfiles"

    unless Dir.exists?(@dotfile_location)
      say("creating #{@dotfile_location}")
      Dir::mkdir(@dotfile_location)
    end
  end

  def self.import(name)
    self.load_env

    if (name)
      Item.new(Dir.home + "/." + name).import
    else
      Dir::glob(Dir.home + "/.?*").each do |target|
        Item.new(target).import
      end
    end
  end

  def self.install(name)
    self.load_env

    if (name)
      Item.new(nil, self.dotfile_location + "/" + name).install
    else
      say("Not DONE yET!!!")
    end
  end

  def self.dropbox_location
    @dropbox_location
  end

  def self.dotfile_location
    @dotfile_location
  end

end
