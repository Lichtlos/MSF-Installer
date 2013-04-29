#!/bin/bash

KVER=`uname -a`
# Variable to know if Homebrew should be installed
MSFPASS=`openssl rand -base64 16`
#Variable with time of launch used for log names
NOW=$(date +"-%b-%d-%y-%H%M%S")
IGCC=1
INSTALL=1

function print_good ()
{
	echo -e "\x1B[01;32m[*]\x1B[0m $1"
}
########################################

function print_error ()
{
	echo -e "\x1B[01;31m[*]\x1B[0m $1"
}
########################################

function print_status ()
{
	echo -e "\x1B[01;34m[*]\x1B[0m $1"
}
########################################

function check_root
{
	if [ "$(id -u)" != "0" ]; then
	   print_error "This step mus be ran as root"
	   exit 1
	fi
}
########################################

function install_armitage_osx
{
	if [ -e /usr/bin/curl ]; then
		print_status "Downloading latest version of Armitage"
		curl -# -o /tmp/armitage.tgz http://www.fastandeasyhacking.com/download/armitage-latest.tgz && print_good "Finished"
		if [ $? -eq 1 ] ; then
		       print_error "Failed to download the latest version of Armitage make sure you"
		       print_error "are connected to the intertet and can reach http://www.fastandeasyhacking.com"
		else
			print_status "Decompressing package to /opt/armitage"
			tar -xvzf /tmp/armitage.tgz -C /usr/local/
	    fi

	    # Check if links exists and if they do not create them
	    if [ ! -e /usr/local/bin/armitage ]; then
	    	print_status "Linking Armitage in /usr/local/bin/armitage"
	    	echo java -jar /usr/local/share/armitage/armitage.jar \$\* > /usr/local/bin/armitage
	    else
	    	print_good "Armitage is already linked to /usr/local/bin/armitage"
	    fi

	    if [ ! -e /usr/local/bin/teamserver ]; then
	    	print_status "CopyingTeamserver in /usr/local/bin/teamserver"
	    	ln -s /usr/local/armitage/teamserver /usr/local/bin/teamserver
	    	perl -pi -e 's/armitage.jar/\/usr\/local\/share\/armitage\/armitage.jar/g' /usr/local/share/armitage/teamserver
	    else
	    	print_good "Teamserver is already linked to /usr/local/bin/teamserver"
	    fi
	fi
}
########################################

function check_for_brew_osx
{
	print_status "Verifiying that Homebrew is installed:"
	if [ -e /usr/local/bin/brew ]; then
		print_good "Homebrew is installed on the system, updating formulas."
		/usr/local/bin/brew update 2>&1
		print_good "Finished updating formulas"
		brew tap homebrew/versions
		print_status "Verifying that the proper paths are set"

		if [ -d ~/.bash_profile ]; then
			if [ "$(grep ":/usr/local/sbin" ~/.bash_profile -q)" ]; then
				print_good "Paths are properly set"
			else
				print_status "Setting the path for homebrew"
				echo PATH=/usr/local/bin:/usr/local/sbin:$PATH >> ~/.bash_profile
				source  ~/.bash_profile
		 	fi
		 else
		 	echo PATH=/usr/local/bin:/usr/local/sbin:$PATH >> ~/.bash_profile
			source  ~/.bash_profile
		 fi
	else

		print_status "Installing Homebrew"
		/usr/bin/ruby -e "$(curl -fsSkL raw.github.com/mxcl/homebrew/go)"
		if [ "$(grep ":/usr/local/sbin" ~/.bash_profile -q)" ]; then
			print_good "Paths are properly set"
		else
			print_status "Setting the path for homebrew"
			echo PATH=/usr/local/bin:/usr/local/sbin:$PATH >> ~/.bash_profile
			source  ~/.bash_profile
	 	fi

	fi
}
########################################

function check_dependencies_osx
{
	# Get a list of all the packages installed on the system
	PKGS=`pkgutil --pkgs`
	print_status "Verifiying that Development Tools and Java are installed:"
	if $(echo "$PKGS" | grep -q Java) ; then
		print_good "Java is intalled."
	else
		print_error "Java is not installed on this system."
		exit 1
	fi

	if $(echo "$PKGS" | grep -q Xcode) ; then
		print_good "Xcode is intalled."
	else
		print_error "Xcode is not installed on this system. Install from the App AppStore."
		exit 1
	fi

	if $(echo "$PKGS" | grep -q com.apple.pkg.DeveloperToolsCLI) ; then
		print_good "Command Line Development Tools is intalled."
	else
		print_error "Command Line Development Tools is not installed on this system."
		exit 1
	fi
}
########################################

function install_gcc_osx
{
	print_status "Checking if the GNU GCC Compiler is installed if not installing it."
	if [ -d /usr/local/Cellar/ ] && [ -L /usr/local/bin/gcc-4.8 ]; then
		print_good "Latest version of the GNU GCC is installed."
	else
		print_status "Installing version 4.8 of the GNU GCC Compiler"
		brew install homebrew/versions/gcc48
	fi

	print_status "Checking if GCC is set as the CC Compiler."
	if [[ ! "$(cat ~/.bash_profile)" =~ "CC=/usr/local/bin/gcc-4.8" ]]; then
		print_status "GCC is not set as the default CC Compiler."
		print_status "Setting GCC as the default CC Compiler."
		echo export CC=/usr/local/bin/gcc-4.7 >> ~/.bash_profile
		print_good "GCC set as the defult CC Compiler"
	else
		print_good "GCC is already set as the default CC Compiler."
	fi

	print_status "Checking GCC is set to compile for x86_64."
	if [[ ! "$(cat ~/.bash_profile)" =~ "x86_64" ]]; then
		print_status "x86_64 is not set as the default architecture."
		print_status "Setting x86_64 as the default architecture."
		echo export ARCHFLAGS=\"-arch x86_64\" >> ~/.bash_profile
		print_good "x86_64 set as the defult architecture"
	else
		print_good "x86_64 is already set as the default architecture."
	fi

}
########################################

function install_ruby_osx
{
	print_status "Checking if Ruby 1.9.3 is installed if not installing it."
	if [ -d /usr/local/Cellar/ruby193 ] && [ -L /usr/local/bin/ruby ]; then
		print_good "Correct version of Ruby is installed."
	else
		print_status "Installing Ruby 1.9.3"
		brew tap homebrew/versions
		brew install homebrew/versions/ruby193
		echo PATH=/usr/local/opt/ruby193/bin:$PATH >> ~/.bash_profile
		source  ~/.bash_profile
	fi
	print_status "Inatlling the bundler and SQLite3 Gems"
	gem install bundler sqlite3
}
########################################

function install_nmap_osx
{
	print_status "Checking if Nmap is installed using Homebrew if not installing it."
	if [ -d /usr/local/Cellar/nmap ] && [ -L /usr/local/bin/nmap ]; then
		print_good "NMap is installed."
	else
		print_status "Installing nmap"
		brew install nmap
	fi
}
########################################

function install_postgresql_osx
{
	print_status "Checking if PostgreSQL is installed using Homebrew if not installing it."
	if [ -d /usr/local/Cellar/postgresql ] && [ -L /usr/local/bin/postgres ]; then
		print_good "PostgreSQL is installed."
	else
		print_status "Installing PostgresQL"
		brew install postgresql
		if [ $? -eq 0 ]; then
			print_good "Installtion of PostgreSQL was successful"
			print_status "Initiating postgres"
			initdb /usr/local/var/postgres
			if [ $? -eq 0 ]; then
				print_good "Database initiation was successful"
			fi

			# Getting the Postgres version so as to configure startup of the databse
			PSQLVER=`psql --version | cut -d " " -f3`

			print_status "Configuring the database engine to start at logon"
			pg_ctl -D /usr/local/var/postgres -l /usr/local/var/postgres/server.log start
			mkdir -p ~/Library/LaunchAgents
			ln -sfv /usr/local/opt/postgresql/*.plist ~/Library/LaunchAgents
			# Give enough time for the database to start for the first time
			sleep 5
			#launchctl load ~/Library/LaunchAgents/homebrew.mxcl.postgresql.plist
			print_status "Creating the MSF Database user msf with the password provided"
			psql postgres -c "create role msf login password '$MSFPASS'"
			if [ $? -eq 0 ]; then
				print_good "Metasploit Role named msf has been created."
			else
				print_error "Failed to create the msf role"
			fi
			print_status "Creating msf database and setting the owner to msf user"
			createdb -O msf msf -h localhost
			if [ $? -eq 0 ]; then
				print_good "Metasploit Databse named msf has been created."
			else
				print_error "Failed to create the msf database."
			fi
		fi
	fi
}
########################################

function install_msf_osx
{
	print_status "Installing Metasploit Framework from the GitHub Repository"
	print_status "Cloning latest version of Metasploit Framework"
	git clone https://github.com/rapid7/metasploit-framework.git /usr/local/share/metasploit-framework
	print_status "Linking metasploit commands."
	cd /usr/local/share/metasploit-framework
	for MSF in $(ls msf*); do
		print_status "linking $MSF command"
		ln -s /usr/local/share/metasploit-framework/$MSF /usr/local/bin/$MSF
	done
	print_status "Creating Database configuration YAML file."
	echo 'production:
   adapter: postgresql
   database: msf
   username: msf
   password: $MSFPASS
   host: 127.0.0.1
   port: 5432
   pool: 75
   timeout: 5' > /usr/local/share/metasploit-framework/database.yml
   print_status "setting environment variable in system profile. Password will be requiered"
   sudo sh -c "echo export MSF_DATABASE_CONFIG=/usr/local/share/metasploit-framework/database.yml >> /etc/profile"
   echo "export MSF_DATABASE_CONFIG=/usr/local/share/metasploit-framework/database.yml" >> ~/.bash_profile
   source /etc/profile
   source ~/.bash_profile
   print_status "Installing required ruby gems by Framework using bundler"
   cd /usr/local/share/metasploit-framework
   bundle install
   print_status "Starting Metasploit so as to populate de database."
   /usr/local/share/metasploit-framework/msfconsole -q -x "exit"
}
########################################

function install_plugins
{
	print_status "Installing addiotional Metasploit plugins"
	print_status "Installing Pentest plugin"
	curl -# -o /usr/local/share/metasploit-framework/plugins/pentest.rb https://raw.github.com/darkoperator/Metasploit-Plugins/master/pentest.rb
	if [ $? -eq 0 ]; then
		print_good "The pentest plugin has been installed."
	else
		print_error "Failed to install the pentest plugin."
	fi
	print_status "Installing DNSRecon Import plugin"
	curl -# -o /usr/local/share/metasploit-framework/plugins/dnsr_import.rb https://raw.github.com/darkoperator/dnsrecon/master/msf_plugin/dnsr_import.rb
	if [ $? -eq 0 ]; then
		print_good "The dnsr_import plugin has been installed."
	else
		print_error "Failed to install the dnsr_import plugin."
	fi
}
#######################################

function install_deps_deb
{
	print_status "Installing dependencies for Metasploit Framework"
	sudo apt-get -y update
	sudo apt-get -y install build-essential libreadline-dev  libssl-dev libpq5 libpq-dev libreadline5 libsqlite3-dev libpcap-dev openjdk-7-jre subversion git-core autoconf postgresql pgadmin3 curl zlib1g-dev libxml2-dev libxslt1-dev vncviewer libyaml-dev ruby1.9.3 #>> $LOGFILE
	print_status "Installing base Ruby Gems"
	sudo gem install wirble sqlite3 bundler #>> $LOGFILE
}
#######################################

function install_nmap_linux
{
	print_status "Downloading and Compiling the latest version if Nmap"
	print_status "Downloading from SVN the latest version of Nmap"
	cd /usr/src
	sudo svn co https://svn.nmap.org/nmap #>> $LOGFILE
	cd nmap
	print_status "Configuring Nmap"
	./configure #>> $LOGFILE
	print_status "Compiling the latest version of Nmap"
	make #>> $LOGFILE
	print_status "Installing the latest version of Nmap"
	sudo make install #>> $LOGFILE
	make clean #>> $LOGFILE
}
#######################################

function configure_psql_deb
{
	print_status "Creating the MSF Database user msf with the password provided"
	sudo -u postgres psql postgres -c "create role msf login password '$MSFPASS'"
	if [ $? -eq 0 ]; then
		print_good "Metasploit Role named msf has been created."
	else
		print_error "Failed to create the msf role"
	fi
	print_status "Creating msf database and setting the owner to msf user"
	sudo -u postgres psql postgres -c "CREATE DATABASE msf OWNER msf;"
	if [ $? -eq 0 ]; then
		print_good "Metasploit Databse named msf has been created."
	else
		print_error "Failed to create the msf database."
	fi
}
#######################################

function install_msf_linux
{
	print_status "Installing Metasploit Framework from the GitHub Repository"
	print_status "Cloning latest version of Metasploit Framework"
	sudo git clone https://github.com/rapid7/metasploit-framework.git /usr/local/share/metasploit-framework #>> $LOGFILE
	print_status "Linking metasploit commands."
	cd /usr/local/share/metasploit-framework
	for MSF in $(ls msf*); do
		print_status "linking $MSF command"
		sudo ln -s /usr/local/share/metasploit-framework/$MSF /usr/local/bin/$MSF
	done
	print_status "Creating Database configuration YAML file."
	sudo sh -c "echo 'production:
   adapter: postgresql
   database: msf
   username: msf
   password: $MSFPASS
   host: 127.0.0.1
   port: 5432
   pool: 75
   timeout: 5' > /usr/local/share/metasploit-framework/database.yml"
   	print_status "setting environment variable in system profile. Password will be requiered"
   	sudo sh -c "echo export MSF_DATABASE_CONFIG=/usr/local/share/metasploit-framework/database.yml >> /etc/profile"
   	echo "export MSF_DATABASE_CONFIG=/usr/local/share/metasploit-framework/database.yml" >> ~/.bash_profile
   	source /etc/profile
   	source ~/.bash_profile
   	print_status "Installing required ruby gems by Framework using bundler"
   	cd /usr/local/share/metasploit-framework
   	sudo bundle install #>> $LOGFILE
   	print_status "Starting Metasploit so as to populate de database."
   	/usr/local/share/metasploit-framework/msfconsole -q -x "exit"
}
#######################################

function install_plugins_linux
{
	print_status "Installing addiotional Metasploit plugins"
	print_status "Installing Pentest plugin"
	sudo curl -# -o /usr/local/share/metasploit-framework/plugins/pentest.rb https://raw.github.com/darkoperator/Metasploit-Plugins/master/pentest.rb
	if [ $? -eq 0 ]; then
		print_good "The pentest plugin has been installed."
	else
		print_error "Failed to install the pentest plugin."
	fi
	print_status "Installing DNSRecon Import plugin"
	sudo curl -# -o /usr/local/share/metasploit-framework/plugins/dnsr_import.rb https://raw.github.com/darkoperator/dnsrecon/master/msf_plugin/dnsr_import.rb
	if [ $? -eq 0 ]; then
		print_good "The dnsr_import plugin has been installed."
	else
		print_error "Failed to install the dnsr_import plugin."
	fi
}
#######################################

function install_armitage_linux
{
	if [ -e /usr/bin/curl ]; then
		print_status "Downloading latest version of Armitage"
		curl -# -o /tmp/armitage.tgz http://www.fastandeasyhacking.com/download/armitage-latest.tgz && print_good "Finished"
		if [ $? -eq 1 ] ; then
		       print_error "Failed to download the latest version of Armitage make sure you"
		       print_error "are connected to the intertet and can reach http://www.fastandeasyhacking.com"
		else
			print_status "Decompressing package to /opt/armitage"
			sudo tar -xvzf /tmp/armitage.tgz -C /usr/local/share
	    fi

	    # Check if links exists and if they do not create them
	    if [ ! -e /usr/local/bin/armitage ]; then
	    	print_status "Creating link for Armitage in /usr/local/bin/armitage"
	    	sudo echo java -jar /usr/local/share/armitage/armitage.jar \$\* > /usr/local/bin/armitage
	    else
	    	print_good "Armitage is already linked to /usr/local/bin/armitage"
	    fi

	    if [ ! -e /usr/local/bin/teamserver ]; then
	    	print_status "Creating link for Teamserver in /usr/local/bin/teamserver"
	    	sudo ln -s /usr/local/share/armitage/teamserver /usr/local/bin/teamserver
	    	sudo perl -pi -e 's/armitage.jar/\/usr\/local\/share\/armitage\/armitage.jar/g' /usr/local/share/armitage/teamserver
	    else
	    	print_good "Teamserver is already linked to /usr/local/bin/teamserver"
	    fi
	fi
}
#######################################

function usage ()
{
	echo "Scritp for Installing Metasploit Framework"
	echo "By Carlos_Perez[at]darkoperator.com"
	echo "Ver 0.1.1"
	echo ""
	echo "-i                :Install Metasploit Framework."
	echo "-p <password>     :password for MEtasploit databse msf user. If not provided a roandom one is generated for you."
	echo "-g                :Install GNU GCC (Not necessary uless you wish to compile and install ruby 1.8.7 in OSX"
	echo "-h                :This help message"
}


#### MAIN ###
[[ ! $1 ]] && { usage; exit 0; }
#Variable with log file location for trobleshooting
LOGFILE="/tmp/msfinstall$NOW.log"
while getopts "igp:h" options; do
  case $options in
    p ) MSFPASS=$OPTARG;;
    i ) INSTALL=0;;
	g ) IGCC=0;;
    h ) usage;;
    \? ) usage
         exit 1;;
    * ) usage
          exit 1;;

  esac
done

if [ $INSTALL -eq 0 ]; then
	if [[ "$KVER" =~ Darwin ]]; then
		check_dependencies_osx
		check_for_brew_osx
		install_ruby_osx
		install_nmap_osx
		install_postgresql_osx
		install_msf_osx
		install_armitage_osx
		install_plugins

		if [ $IGCC -eq 0 ]; then
			install_gcc_osx
		fi

	elif [[ "$KVER" =~ buntu ]]; then
		install_deps_deb
		install_nmap_linux
		configure_psql_deb
		install_msf_linux
		install_plugins_linux
		install_armitage_linux
	else
		print_error "The script does not support this platform at this moment."
		exit 1
	fi
	print_status "#################################################################"
	print_status "### YOU NEED TO RELOAD YOUR PROFILE BEFORE USE OF METASPLOIT! ###"
	print_status "### RUN source ~/.bash_profile                                ###"
	print_status "#################################################################"

fi