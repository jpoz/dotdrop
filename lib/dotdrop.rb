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
        Addable.new(target).run
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


  class Importable

    attr_accessor :target, :destination, :name

    def initialize(destination, target=nil)
      @destination = destination
      @target = target
      /(?<name>[^\/]*)$/ =~ destination
      @name = name
    end

    def run
      if target_exists?
        if ask("<%= color('#{self.name}', :green) %> <%= color('already exists', :red) %>!! Do you want to replace <%= color('#{self.target}', :green) %>?").downcase.include?("y")
          self.install!
        end
      else
        if ask("Would you like to install <%= color('#{self.name}', :green) %> from your Dropbox?  ").downcase.include?("y")
          self.install!
        end
      end
    end

    def install!
      say("\tBacking up #{self.target} to #{self.backup_location}")
      self.move!(self.backup_location)
      say("\tCreating symlink #{self.target} to #{self.destination}")
      self.symlink!(self.destination)
    end

    def symlink!(des)
      File.symlink(des, target)
    end

    def move!(des)
      FileUtils.mv(target, des)
    end

    def target
      return @target if @target
      Dir.home + "/." + self.name
    end

    def target_exists?
      File.exists?(self.target)
    end

    def backup_location
      self.target + "_backup"
    end

  end

  class Addable

    attr_accessor :target, :destination, :name

    BAD_TARGETS = [".","dropbox","DS_Store"]

    def initialize(target, destination=nil)
      @target = target
      @destination = destination
      /\.(?<name>[^\/]*)$/ =~ target
      @name = name
    end

    def run
      return unless self.viable_target?
      if destination_exists?
        say("Dropbox already has a #{name}")
        if File.symlink?(target)
          loc = File.readlink(target)
        end
      else
        unless File.symlink?(target)
          if ask("Would you like to move <%= color('#{self.target}', :green) %> to your Dropbox?  ").downcase.include?("y")
            self.import!
          end
        else
          say("#{target} is a symlink")
        end
      end
    end

    def import!
      say("\tCopying #{self.target} to #{self.destination}")
      self.copy!(self.destination)
      say("\tBacking up #{self.target} to #{self.backup_location}")
      self.move!(self.backup_location)
      say("\tCreating symlink #{self.target} to #{self.destination}")
      self.symlink!(self.destination)
    end

    def copy!(des)
      if File.directory?(self.target) 
        FileUtils.mkdir(self.destination) unless Dir.exists?(des)
        FileUtils.cp_r(self.target + "/.", des)
      else
        FileUtils.copy(self.target, des)
      end
    end

    def move!(des)
      FileUtils.mv(target, des)
    end

    def symlink!(des)
      File.symlink(des, target)
    end

    def viable_target?
      !BAD_TARGETS.include?(name)
    end

    def destination
      return @destination if @destination
      DotDrop.dotfile_location + "/" + name
    end

    def backup_location
      self.target + "_backup"
    end

    def destination_exists?
      File.exists?(self.destination)
    end

  end

end
