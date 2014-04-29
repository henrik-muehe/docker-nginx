require 'docker'
require 'awesome_print'

TLD = "muehe.org"

def template(aliases,ip,port=8080)
	aliases.map!{ |a| "#{a}.#{TLD}" }
	t = <<-EOF
    server {
        listen 80;
        server_name #{aliases.uniq.join(" ")};
        client_max_body_size 10M;

        include mime.types;
        default_type application/octet-stream;
        sendfile on;

        gzip on;
        gzip_proxied any;
        gzip_comp_level 6;
        gzip_vary on;
        gzip_min_length 1000;
        gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript;
        gzip_buffers 16 8k;

        location / {
                proxy_set_header Host $http_host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header Client-IP $remote_addr;
                proxy_set_header X-Forwarded-For $remote_addr;
                proxy_pass http://#{ip}:#{port};
        }
    }

	EOF
	t.gsub(/^    /,'')
end

Docker::Container.all.each do |c|
	aliases = [
		c.info["Image"].gsub(/.*\//,'').gsub(/:.*$/,''),
		c.info["Names"].first.gsub(/\//, '')
	]
	aliases += aliases.map { |a| "www.#{a}" }
	ip = c.json["NetworkSettings"]["IPAddress"]
	puts template(aliases,ip)
end
