# frozen_string_literal: true

module ChromeLauncher
  module Platform
    module_function

    CHROME_EXECUTABLES = %w[
      google-chrome-stable
      google-chrome
      chromium-browser
      chromium
    ].freeze

    def os
      host_os = RbConfig::CONFIG["host_os"]
      @os ||= case host_os
              when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
                :windows
              when /darwin|mac os/
                :macos
              when /linux/
                :linux
              when /solaris|bsd/
                :uniq
              end
    end

    def windows?
      os == :windows
    end

    def unix_path(path)
      path.tr(File::ALT_SEPARATOR, File::SEPARATOR)
    end

    def chrome_binary(executables = CHROME_EXECUTABLES)
      paths = ENV["PATH"].split(File::PATH_SEPARATOR)

      if windows?
        executables.map! { |n| "#{n}.exe" }
        executables.dup.each { |n| binary_names << n.gsub("exe", "bat") }
      end

      executables.each do |executable|
        paths.each do |path|
          full_path = File.join(path, executable)
          full_path = unix_path(full_path) if windows?
          exe = Dir.glob(full_path).find { |_f| File.executable?(full_path) }
          return exe if exe
        end
      end

      # try to find in programfiles if host is window
      find_in_program_files if windows?
    end

    def find_in_program_files(executables = CHROME_EXECUTABLES)
      paths = [
        ENV["PROGRAMFILES"] || '\\Program Files',
        ENV["ProgramFiles(x86)"] || '\\Program Files (x86)',
        ENV["ProgramW6432"] || '\\Program Files'
      ]

      paths.each do |root|
        executables.each do |executable|
          exe = File.join(root, executable)
          return exe if File.executable?(exe)
        end
      end

      nil
    end
  end
end
