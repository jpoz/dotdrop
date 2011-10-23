class DotDrop

  class Item

    attr_accessor :target, :destination, :name

    def initialize(target, destination=nil)
      @target = target
      @destination = destination
      raise "Need a target or a destination" if target.nil? && destination.nil?
    end

    def install
      if target_exists?
        if File.symlink?(target)
          location = File.readlink(target)
          if location == self.destination
            say("Did nothing, <%= color('#{self.name}', :green) %> is already linked to your DropBox")
          else
            say("Could not install <%= color('#{self.name}', :red) %> because it is already a symlink")
          end
        else
          if ask("<%= color('#{self.name}', :green) %> <%= color('already exists', :red) %>!! Do you want to replace <%= color('#{self.target}', :green) %>?").downcase.include?("y")
            self.install!
          end
        end
      else
        if ask("Would you like to install <%= color('#{self.name}', :green) %> from your Dropbox?  ").downcase.include?("y")
          self.install!
        end
      end
    end

    def import
      if destination_exists?
        if File.symlink?(target)
          location = File.readlink(target)
          if location == self.destination
            say("Did nothing, <%= color('#{self.name}', :green) %> is already linked to your DropBox")
          else
            say("Could not import <%= color('#{self.name}', :red) %> because it is already a symlink")
          end
        else
          if ask("<%= color('Dropbox already has a #{name}', :red) %> Do you want to replace it with <%= color('#{self.target}', :green) %>? This will <%= color('remove', :red) %> #{self.destination}!!!  ").downcase.include?("y")
            say "Woops not done yet. Plz remove #{self.destination} yourself"
          end
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

    def name
      if @target
        /\.(?<name>[^\/]*)$/ =~ self.target
        return name
      else
        /(?<name>[^\/]*)$/ =~ self.destination
        return name
      end
    end

    def destination
      return @destination if @destination
      DotDrop.dotfile_location + "/" + self.name
    end

    def target
      return @target if @target
      Dir.home + "/." + self.name
    end

    protected

    def install!
      if (self.target_exists?)
        say("\tBacking up #{self.target} to #{self.backup_location}")
        self.move!(self.backup_location)
      end
      say("\tCreating symlink #{self.target} to #{self.destination}")
      self.symlink!(self.destination)
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

    def backup_location
      self.target + "_backup"
    end

    def destination_exists?
      File.exists?(self.destination)
    end

    def target_exists?
      File.exists?(self.target)
    end
  end

end
