# Create normal user
sudo adduser newusername

# Create system user
sudo adduser --system --group --no-create-home --shell /bin/false newusername
