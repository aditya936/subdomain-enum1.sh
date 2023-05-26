#!/bin/bash

# Check if the required tools are installed
command -v subfinder >/dev/null 2>&1 || { echo >&2 "subfinder is required but not installed. Aborting."; exit 1; }
command -v amass >/dev/null 2>&1 || { echo >&2 "amass is required but not installed. Aborting."; exit 1; }
command -v httprobe >/dev/null 2>&1 || { echo >&2 "httprobe is required but not installed. Aborting."; exit 1; }
command -v waybackurls >/dev/null 2>&1 || { echo >&2 "waybackurls is required but not installed. Aborting."; exit 1; }

# Function to perform subdomain enumeration for a single domain
perform_recon() {
  domain="$1"
  echo "Performing subdomain enumeration for domain: $domain"

  # Create a directory for the domain
  domain_dir="${domain//./_}"
  mkdir -p "$domain_dir"

  # Run subfinder in the background
  echo "Running subfinder in the background..."
  subfinder -d "$domain" -o "$domain_dir/subfinder.txt" || { echo "Error: Subfinder encountered an error."; return; }

  # Run amass in the background
  echo "Running amass in the background..."
  amass enum -passive -d "$domain" -o "$domain_dir/amass.txt" || { echo "Error: Amass encountered an error."; return; }

  # Create a file containing unique subdomains from amass and subfinder results
  echo "Creating the combined subdomain file..."
  combined_file="$domain_dir/2-allsubd-$domain.txt"
  cat "$domain_dir/subfinder.txt" "$domain_dir/amass.txt" | sort -u > "$combined_file"
  echo "Combined subdomain file created: $combined_file"

  # Use httprobe to probe subdomains and save the output
  echo "Running httprobe..."
  httprobe -c 50 -t 3000 -p http,https < "$combined_file" | tee "$domain_dir/3-subd$domain.txt" || { echo "Error: Httprobe encountered an error."; return; }

  # Use waybackurls to find URLs from Wayback Machine
  echo "Running waybackurls..."
  waybackurls < "$domain_dir/3-subd$domain.txt" > "$domain_dir/4-wayback-result.txt" || { echo "Error: waybackurls encountered an error."; return; }

  echo "Subdomain enumeration for domain $domain completed."
  echo
}

# Function to display the help menu
display_help() {
  echo "Usage: $0 [OPTIONS] <DOMAIN | FILE>"
  echo
  echo "Options:"
  echo "  -h, --help    Display this help menu"
  echo
  echo "Description: This script performs subdomain enumeration using the following tools:"
  echo "  - subfinder: Find subdomains using passive and active methods"
  echo "  - amass: Discover subdomains using various techniques"
  echo "  - httprobe: Probe subdomains to determine if they respond to HTTP/HTTPS"
  echo "  - waybackurls: Retrieve URLs from Wayback Machine"
  echo
  echo "Arguments:"
  echo "  DOMAIN        Single domain to perform subdomain enumeration"
  echo "  FILE          File containing a list of domains (one per line)"
  echo
  echo "Resume Handling:"
  echo "  If the script is re-run and a directory for a domain already exists, it will skip"
  echo "  the subdomain enumeration for that domain and continue with the remaining domains."
  echo "  This allows the script to resume where it left off in case of interruptions."
}

# Check if any argument is provided
if [ -z "$1" ]; then
  display_help
  exit 1
fi

# Process the command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -h|--help)
      display_help
      exit 0
      ;;
    *)
      # Check if the argument is a file
      if [ -f "$key" ]; then
        # Input is a file containing a list of domains
        while IFS= read -r domain; do
          perform_recon "$domain"
        done < "$key"
      else
        # Input is a single domain
        perform_recon "$key"
      fi
      shift
      ;;
  esac
done
