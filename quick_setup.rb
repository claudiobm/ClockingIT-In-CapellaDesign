missing_dep = false
missing_deps = []

deps = { 'tzinfo' => 'tzinfo', 'redcloth' => 'RedCloth', 'rake' => 'rake', 'ferret' => 'ferret', 
  'fastercsv' => 'fastercsv', 'eventmachine' => 'eventmachine',  'RMagick' => 'rmagick', 
  'icalendar' => 'icalendar', 'mongrel' => 'mongrel', 'zentest' => 'ZenTest', 'hoe' => 'hoe',
  'google_chart' => 'gchartrb', 'json' => 'json', 'test/spec' => 'test-spec', 'echoe' => 'echoe'
}

puts "Verifying dependencies..."

deps.keys.each do |dep|
  begin
    require dep
  rescue LoadError
    missing_deps << deps[dep]
  end 
end 

if missing_deps.size > 0
  puts "Please install required Ruby Gems:"
  puts "  sudo gem install #{missing_deps.join(" ")} -r"
  puts
  if missing_deps.include? "rmagick"
    puts "rmagick requires ImageMagick. If you're unable to install ImageMagick 6.3.0+, which the latest"
    puts "version of rmagick requires, please install version 1.5.14 instead: "
    puts "  sudo gem install rmagick -v 1.5.14 -r"
  end
end

system("rake db:schema:load RAILS_ENV=production")
system("rake db:migrate RAILS_ENV=production")

begin
  require "config/environment"
rescue
  puts "** Unable to load Rails, please try:"
  puts "  ./script/console"
  puts "and look at the error reported."
  exit
end

@user = User.new
@company = Company.new

@user.name = "Administrador"
@user.username = "admin"
@user.password = "admin"
@user.email = "rodrigo@capelladesign.com.br"
@user.time_zone = "Brasilia"
@user.locale = "pt_BR"
@user.option_externalclients = 1
@user.option_tracktime = 1
@user.option_tooltips = 1
@user.date_format = "%d/%m/%Y"
@user.time_format = "%H:%M"
@user.admin = 1

puts "  Creating initial company..."

@company.name = "Capelladesign"
@company.contact_email = "rodrigo@capelladesign.com.br"
@company.contact_name = "Rodrigo"
@company.subdomain = "capelladesign"

if @company.save
  @customer = Customer.new
  @customer.name = @company.name
  
  @company.customers << @customer
  puts "  Creating initial user..."
  @company.users << @user
else 
  c = Company.find_by_subdomain(subdomain)
  if c
    puts "** Unable to create initial company, #{subdomain} already registered.. **"
    
    del = "\n"
    print "Delete existing company '#{c.name}' with subdomain '#{subdomain}' and try again? [y]: "
    del = gets
    del = "y" if del == "\n"
    del.strip!
    if del.downcase.include?('y')
      c.destroy
      if @company.save
        @customer = Customer.new
        @customer.name = @company.name
  
        @company.customers << @customer
        puts "  Creating initial user..."
        @company.users << @user
      
      else
        puts " Still unable to create initial company. Check database settings..."
        exit
      end
    end

  else 
    exit
  end
end

puts "Creating merged CSS and JavaScript files..."
system("rake asset:packager:build_all")
puts "Done"

puts "Running any pending migrations..."
system("rake db:migrate RAILS_ENV=production")
puts "Done"